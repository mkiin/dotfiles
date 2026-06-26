{ config, dotfilesDir, ... }:

let
  sym = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/quickshell/${path}";
in
{
  xdg.configFile = {
    "quickshell/shell.json".source  = sym "shell.json";
    "quickshell/shell".source       = sym "shell";
    "quickshell/audio".source       = sym "audio";
    "quickshell/bluetooth".source   = sym "bluetooth";
  };

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell shell daemon (notifications + control center)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Environment = "QT_QPA_PLATFORMTHEME=gtk3";
      ExecStart = "/usr/bin/qs -c shell";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
