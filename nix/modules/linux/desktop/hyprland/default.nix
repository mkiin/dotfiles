{ config, dotfilesDir, ... }:

let
  sym = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/hypr/${path}";
in
{
  wayland.windowManager.hyprland = {
    enable        = true;
    package       = null;
    portalPackage = null;
    xwayland.enable = true;
    systemd.enable  = false;
    configType      = "lua";
  };

  xdg.configFile = {
    "hypr/hyprland.lua".source     = sym "lua/hyprland.lua";
    "hypr/vars.lua".source         = sym "lua/vars.lua";
    "hypr/color-scheme.lua".source = sym "lua/color-scheme.lua";
    "hypr/appearance.lua".source   = sym "lua/appearance.lua";
    "hypr/input.lua".source        = sym "lua/input.lua";
    "hypr/autostart.lua".source    = sym "lua/autostart.lua";
    "hypr/keybinds.lua".source     = sym "lua/keybinds.lua";
    "hypr/rules.lua".source        = sym "lua/rules.lua";
    "hypr/scripts".source          = sym "scripts";
    "hypr/hyprlock.conf".source    = sym "hyprlock.conf";
  };
}
