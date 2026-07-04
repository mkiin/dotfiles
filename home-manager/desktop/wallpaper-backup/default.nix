{ pkgs, dotfilesDir, ... }:
let
  dir = "${dotfilesDir}/images/wallpaper";
  # copy は追加のみ。ローカル削除を R2 へ伝播させず、一度上げた壁紙を失わない。
  backup = "${pkgs.rclone}/bin/rclone copy ${dir} r2:dotfiles-wallpaper/wallpaper --config /run/agenix/rclone-r2.conf";
in
{
  systemd.user.paths.wallpaper-backup = {
    Unit.Description = "Watch wallpaper dir and trigger R2 backup";
    Path.PathModified = dir;
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.wallpaper-backup = {
    Unit.Description = "Back up wallpapers to R2 (rclone copy, additive)";
    Service = {
      Type = "oneshot";
      ExecStart = backup;
    };
  };
}
