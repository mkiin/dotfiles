{ inputs, pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    package = inputs.waybar-pr.packages.${pkgs.stdenv.hostPlatform.system}.waybar;
  };

  xdg.configFile = {
    "waybar/config.jsonc".source = ./config.jsonc;
    "waybar/style.css".source = ./style.css;
    "waybar/scripts".source = ./scripts;
  };
}
