{ dotLink, ... }:

let
  sym = dotLink "matugen";
in
{
  xdg.configFile = {
    "matugen/config.toml".source                      = sym "config.toml";
    "matugen/templates/hyprlock-colors.conf".source   = sym "templates/hyprlock-colors.conf";
    "matugen/templates/hyprland-colors.lua".source    = sym "templates/hyprland-colors.lua";
    "matugen/templates/waybar-colors.css".source      = sym "templates/waybar-colors.css";
    "matugen/templates/wlogout-colors.css".source     = sym "templates/wlogout-colors.css";
    "matugen/templates/quickshell-colors.json".source = sym "templates/quickshell-colors.json";
  };
}
