{ lnk, lib, ... }:
{
  xdg.configFile = {
    "matugen/config.toml".source = lnk ./config.toml;
    "matugen/templates/hyprland-colors.lua".source = lnk ./templates/hyprland-colors.lua;
    "matugen/templates/wlogout-colors.css".source = lnk ./templates/wlogout-colors.css;
    "matugen/templates/quickshell-colors.json".source = lnk ./templates/quickshell-colors.json;
    "matugen/templates/rofi-colors.rasi".source = lnk ./templates/rofi-colors.rasi;
  };

  home.activation.fallbackRofiColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/rofi/themes/colors.rasi"
    [ -e "$t" ] || $DRY_RUN_CMD install -Dm644 ${./fallback/colors.rasi} "$t"
  '';
}
