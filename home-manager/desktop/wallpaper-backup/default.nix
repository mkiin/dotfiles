{ pkgs, dotfilesDir, ... }:
let
  dir = "${dotfilesDir}/images/wallpaper";
  # sync でローカルをミラー。ローカルで削除/リネームした壁紙は R2 からも消す。
  backup = "${pkgs.rclone}/bin/rclone sync ${dir} r2:dotfile-wallpaper/wallpaper --config /run/agenix/rclone-r2.conf";
in
{
  systemd.user.paths.wallpaper-backup = {
    Unit.Description = "Watch wallpaper dir and trigger R2 backup";
    Path.PathModified = dir;
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.wallpaper-backup = {
    Unit.Description = "Back up wallpapers to R2 (rclone sync, mirror)";
    Service = {
      Type = "oneshot";
      ExecStart = backup;
    };
  };
}
