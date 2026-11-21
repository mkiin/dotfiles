{
  config,
  lib,
  pkgs,
  ...
}:
let
  rcloneConfig = [ "rclone-config.service" ];
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
  options.modules.desktop.nextcloud-backup.enable = lib.mkEnableOption "Nextcloud backups";

  config = lib.mkIf config.modules.desktop.nextcloud-backup.enable {
    systemd.user.services.nextcloud-backup-facefusion = {
      Unit = {
        Description = "Copy FaceFusion media to Nextcloud";
        Requires = rcloneConfig;
        After = rcloneConfig;
      };
      Service = {
        Type = "oneshot";
        WorkingDirectory = "${config.home.homeDirectory}/ghq/github.com/mkiin/facefusion/media";
        ExecStart = "${pkgs.rclone}/bin/rclone copy . nextcloud:Backup/Yukino/Facefusion";
      };
    };
    systemd.user.timers.nextcloud-backup-facefusion = backupTimer;

    systemd.user.services.nextcloud-backup-screenshot = {
      Unit = {
        Description = "Copy screenshots to Nextcloud";
        Requires = rcloneConfig;
        After = rcloneConfig;
      };
      Service = {
        Type = "oneshot";
        WorkingDirectory = config.xdg.userDirs.extraConfig.SCREENSHOTS;
        ExecStart = "${pkgs.rclone}/bin/rclone copy . nextcloud:Backup/Yukino/Screenshot";
      };
    };
    systemd.user.timers.nextcloud-backup-screenshot = backupTimer;
  };
}
