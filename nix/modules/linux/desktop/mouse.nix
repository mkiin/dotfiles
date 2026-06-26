{ config, dotfilesDir, ... }:

let
  sym = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/mouse/${path}";
in
{
  xdg.configFile = {
    "mouse/g703h.sh".source         = sym "g703h.sh";
    "mouse/m575-profiled.py".source = sym "m575-profiled.py";
    "mouse/profiles.toml".source    = sym "profiles.toml";
  };

  systemd.user.services.m575-profiled = {
    Unit = {
      Description = "ERGO M575 per-application profiles (DPI + side buttons)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "%h/.config/mouse/m575-profiled.py";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
