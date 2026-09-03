{ pkgs, ... }:
{
  systemd.user.services.umu-runtime-update = {
    Unit.Description = "Update the umu Steam runtime";

    Service = {
      Type = "oneshot";
      Environment = [
        "GAMEID=umu-nikke"
        "UMU_NO_PROTON=1"
        "UMU_RUNTIME_UPDATE=1"
      ];
      ExecStart = "${pkgs.steam-run}/bin/steam-run ${pkgs.umu-launcher}/bin/umu-run true";
      TimeoutStartSec = "10min";
    };
  };

  systemd.user.timers.umu-runtime-update = {
    Unit.Description = "Update the umu Steam runtime daily";

    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };

    Install.WantedBy = [ "timers.target" ];
  };
}
