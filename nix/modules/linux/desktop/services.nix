{ ... }:

{
  systemd.user = {
    services.bt-agent = {
      Unit = {
        Description = "Bluetooth pairing agent (bt-agent)";
        PartOf = [ "graphical-session.target" ];
        After = [ "bluetooth.target" "graphical-session.target" ];
      };
      Service = {
        ExecStart = "/usr/bin/bt-agent --capability=NoInputNoOutput";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    services.wallpaper-thumb = {
      Unit.Description = "Regenerate Walker wallpaper thumbnails";
      Service = {
        Type = "oneshot";
        ExecStart = "%h/.config/hypr/scripts/wallpaper/thumb.sh";
        TimeoutStartSec = 60;
      };
    };

    paths.wallpaper-thumb = {
      Unit.Description = "Watch wallpaper directory for thumbnail regeneration";
      Path = {
        PathChanged = "%h/Pictures/wallpaper";
        Unit = "wallpaper-thumb.service";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
