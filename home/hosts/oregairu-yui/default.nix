{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../linux/desktop.nix
    ./kanshi.nix
    ./noctalia.nix
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."github.com" = {
      IdentityFile = "${config.home.homeDirectory}/.ssh/oregairu-yui";
      IdentitiesOnly = true;
    };
  };
  programs.git.signing.key = "${config.home.homeDirectory}/.ssh/oregairu-yui.pub";

  modules.desktop.noctalia.idle = {
    lockTimeout = 900;
    screenOffTimeout = 1800;
    suspendTimeout = 3600;
  };

  modules.desktop.niri.enable = true;
  modules.desktop.pyprland.enable = false;

  home.packages = with pkgs; [
    brightnessctl
    playerctl
  ];
}
