{ lnk, ... }:
{
  xdg.configFile = {
    "matugen/config.toml".source                      = lnk ./config.toml;
    "matugen/templates/hyprlock-colors.conf".source   = lnk ./templates/hyprlock-colors.conf;
    "matugen/templates/hyprland-colors.lua".source    = lnk ./templates/hyprland-colors.lua;
    "matugen/templates/waybar-colors.css".source      = lnk ./templates/waybar-colors.css;
    "matugen/templates/wlogout-colors.css".source     = lnk ./templates/wlogout-colors.css;
    "matugen/templates/quickshell-colors.json".source = lnk ./templates/quickshell-colors.json;
  };
}
