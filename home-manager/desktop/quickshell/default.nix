{ pkgs, lnk, ... }:
{
  xdg.configFile = {
    "quickshell/shell.json".source = lnk ./shell.json;
    "quickshell/shell".source = lnk ./shell;
  };

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell shell daemon (notifications + control center)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs -c shell";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
