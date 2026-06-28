{ inputs, pkgs, lnk, ... }:
{
  imports = [ ./monitor.nix ];

  wayland.windowManager.hyprland = {
    enable        = true;
    package       = inputs.hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = null;
    xwayland.enable = true;
    systemd.enable  = false;
    configType      = "lua";
  };

  xdg.configFile = {
    "hypr/hyprland.lua".source     = lnk ./lua/hyprland.lua;
    "hypr/vars.lua".source         = lnk ./lua/vars.lua;
    "hypr/color-scheme.lua".source = lnk ./lua/color-scheme.lua;
    "hypr/appearance.lua".source   = lnk ./lua/appearance.lua;
    "hypr/input.lua".source        = lnk ./lua/input.lua;
    "hypr/autostart.lua".source    = lnk ./lua/autostart.lua;
    "hypr/keybinds.lua".source     = lnk ./lua/keybinds.lua;
    "hypr/rules.lua".source        = lnk ./lua/rules.lua;
    "hypr/scripts".source          = lnk ./scripts;
    "hypr/hyprlock.conf".source    = lnk ./hyprlock.conf;
  };
}
