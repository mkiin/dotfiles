{
  pkgs,
  config,
  dotfilesDir,
  ...
}:
let
  dir = "${dotfilesDir}/images/wallpaper";
  # サムネイルは派生物なので cache に置く。images/ に置くと git に載り、
  # rclone が wallpaper/ prefix へ上げてサムネイル自身が壁紙として一覧される。
  thumbDir = "${config.xdg.cacheHome}/wallpaper-thumb";
  conf = "/run/agenix/rclone-r2.conf";

  backup = pkgs.writeShellApplication {
    name = "wallpaper-backup";
    runtimeInputs = with pkgs; [
      imagemagick
      rclone
      coreutils
    ];
    text = ''
      shopt -s nullglob nocaseglob

      # 原寸のバックアップが本来の目的なので、サムネイル生成より先に通す。
      # 1枚の変換失敗がバックアップを巻き込まない。
      rclone sync "${dir}" r2:dotfile-wallpaper/wallpaper --config ${conf}

      # サムネイル名は原寸の内容 MD5。walltone は R2 の etag(= 同じ MD5) から
      # キーを導出するため、突き合わせなしに一致する。中身が差し替われば
      # キーごと変わるので、原寸とサムネイルがズレない。
      mkdir -p "${thumbDir}"
      declare -A want
      for f in "${dir}"/*.{jpg,jpeg,png,webp}; do
        m=$(md5sum "$f" | cut -d' ' -f1)
        t="${thumbDir}/$m.webp"
        want["$t"]=1
        # <md5>.webp が在るなら、その内容から作られたものなので古くなり得ない。
        [[ -f $t ]] || magick "$f" -resize 512x -define webp:lossless=true "$t"
      done

      # 孤児は walltone から参照されないが、ローカルと R2 が太るので掃除する。
      for t in "${thumbDir}"/*.webp; do
        [[ -v want["$t"] ]] || rm -f "$t"
      done

      rclone sync "${thumbDir}" r2:dotfile-wallpaper/thumb --config ${conf}
    '';
  };
in
{
  systemd.user.paths.wallpaper-backup = {
    Unit.Description = "Watch wallpaper dir and trigger R2 backup";
    Path.PathModified = dir;
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.wallpaper-backup = {
    Unit.Description = "Back up wallpapers to R2 and publish thumbnails (rclone sync, mirror)";
    # 同一ディレクトリを watch する wallpaper-namer と同時に起床したとき、
    # 命名（リネーム）を済ませてから sync する。リネームで再発火しても mirror なので冪等。
    Unit.After = [ "wallpaper-namer.service" ];
    Service = {
      Type = "oneshot";
      ExecStart = "${backup}/bin/wallpaper-backup";
    };
  };
}
