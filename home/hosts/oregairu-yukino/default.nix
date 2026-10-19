{ config, ... }:
{
  imports = [
    ./kanshi.nix
    ../../base
    ../../base/desktop
    ../../linux/desktop.nix
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."github.com" = {
      IdentityFile = "${config.home.homeDirectory}/.ssh/oregairu-yukino";
      IdentitiesOnly = true;
    };
  };
  programs.git.signing.key = "${config.home.homeDirectory}/.ssh/oregairu-yukino.pub";

  modules.desktop.noctalia.idle = {
    lockTimeout = 900;
    screenOffTimeout = 1800;
    suspendTimeout = 3600;
  };

  modules.desktop.niri.enable = true;
  modules.desktop.niri.extraBinds = builtins.readFile ./niri-binds.kdl;
  modules.desktop.nvidia.enable = true;
  modules.desktop.pyprland.enable = false;

}
