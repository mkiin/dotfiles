{ config, pkgs, ... }:
let
  backupTimer = {
    Unit.Description = "Schedule the Nextcloud backup";
    Timer = {
      OnCalendar = "*:0/15";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
in
{
  home.packages = [ pkgs.rclone ];

  systemd.user.services.nextcloud-backup-facefusion = {
    Unit.Description = "Copy FaceFusion media to Nextcloud";
    Service = {
      Type = "oneshot";
      WorkingDirectory = "${config.home.homeDirectory}/ghq/github.com/mkiin/facefusion/media";
      ExecStart = "${pkgs.rclone}/bin/rclone copy . nextcloud:Backup/Yukino/Facefusion";
    };
  };
  systemd.user.timers.nextcloud-backup-facefusion = backupTimer;

  systemd.user.services.nextcloud-backup-screenshot = {
    Unit.Description = "Copy screenshots to Nextcloud";
    Service = {
      Type = "oneshot";
      WorkingDirectory = config.xdg.userDirs.extraConfig.SCREENSHOTS;
      ExecStart = "${pkgs.rclone}/bin/rclone copy . nextcloud:Backup/Yukino/Screenshot";
    };
  };
  systemd.user.timers.nextcloud-backup-screenshot = backupTimer;
}
