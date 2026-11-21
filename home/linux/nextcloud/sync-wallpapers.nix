{
  config,
  lib,
  myvars,
  pkgs,
  ...
}:
let
  wallpaperDir = "${config.home.homeDirectory}/${myvars.dotfilesdir}/wallpaper";
  stateDir = "%S/wallpaper-sync";
  bisync = lib.concatStringsSep " " [
    "${lib.getExe pkgs.rclone} bisync ${lib.escapeShellArg wallpaperDir} nextcloud:Pictures/Wallpaper"
    "--workdir ${stateDir} --recover --resilient --max-lock 2m"
    "--exclude /yukino-yukinoshita-cute-close-up.png --exclude .gitkeep"
  ];
in
{
  options.modules.desktop.wallpaper-sync.enable =
    lib.mkEnableOption "two-way Nextcloud wallpaper sync";

  config = lib.mkIf config.modules.desktop.wallpaper-sync.enable {
    systemd.user.services.wallpaper-sync-init = {
      Unit = {
        Description = "Initialize wallpaper sync history";
        ConditionPathExists = "!${stateDir}/initialized";
        Requires = [ "rclone-config.service" ];
        After = [ "rclone-config.service" ];
        ConditionPathIsDirectory = wallpaperDir;
      };
      Service = {
        Type = "oneshot";
        StateDirectory = "wallpaper-sync";
        ExecStart = "${bisync} --resync-mode path2 --backup-dir1 ${stateDir}/initial-backup";
        ExecStartPost = "${pkgs.coreutils}/bin/touch ${stateDir}/initialized";
      };
    };
    systemd.user.services.wallpaper-sync = {
      Unit = {
        Description = "Sync wallpapers with Nextcloud";
        Requires = [ "wallpaper-sync-init.service" ];
        After = [ "wallpaper-sync-init.service" ];
        ConditionPathIsDirectory = wallpaperDir;
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${bisync} --track-renames --max-delete-renames-aware";
      };
    };
    systemd.user.paths.wallpaper-sync = {
      Unit.Description = "Watch for local wallpaper changes";
      Path.PathChanged = wallpaperDir;
      Install.WantedBy = [ "default.target" ];
    };
    systemd.user.timers.wallpaper-sync = {
      Unit.Description = "Check Nextcloud for wallpaper changes";
      Timer = {
        OnStartupSec = "10s";
        OnUnitInactiveSec = "1min";
        AccuracySec = "5s";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
