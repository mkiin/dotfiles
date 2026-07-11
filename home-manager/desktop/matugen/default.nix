{ lnk, lib, ... }:
{
  xdg.configFile = {
    "matugen/config.toml".source = lnk ./config.toml;
    "matugen/templates/hyprland-colors.lua".source = lnk ./templates/hyprland-colors.lua;
    "matugen/templates/waybar-colors.css".source = lnk ./templates/waybar-colors.css;
    "matugen/templates/wlogout-colors.css".source = lnk ./templates/wlogout-colors.css;
    "matugen/templates/quickshell-colors.json".source = lnk ./templates/quickshell-colors.json;
    "matugen/templates/rofi-colors.rasi".source = lnk ./templates/rofi-colors.rasi;
  };

  # 初回ブートは matugen 未実行で colors.css が無く waybar が @import に失敗する。
  # 壁紙適用で本物が生成されるまでの間だけ seed 由来のフォールバックを置く(存在時は触らない)。
  home.activation.fallbackWaybarColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/waybar/colors.css"
    [ -e "$t" ] || $DRY_RUN_CMD install -Dm644 ${./fallback/colors.css} "$t"
  '';

  # rofi も同様に、matugen 生成前の初回起動で @import "colors.rasi" が失敗しないよう seed する。
  home.activation.fallbackRofiColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/rofi/themes/colors.rasi"
    [ -e "$t" ] || $DRY_RUN_CMD install -Dm644 ${./fallback/colors.rasi} "$t"
  '';
}
