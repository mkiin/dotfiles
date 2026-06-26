{ config, dotfilesDir, ... }:

let
  sym = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/matugen/${path}";
in
{
  xdg.configFile = {
    "matugen/config.toml".source                      = sym "config.toml";
    "matugen/templates/hyprland-colors.conf".source   = sym "templates/hyprland-colors.conf";
    "matugen/templates/hyprland-colors.lua".source    = sym "templates/hyprland-colors.lua";
    "matugen/templates/waybar-colors.css".source      = sym "templates/waybar-colors.css";
    "matugen/templates/wlogout-colors.css".source     = sym "templates/wlogout-colors.css";
    "matugen/templates/quickshell-colors.json".source = sym "templates/quickshell-colors.json";
  };
}
