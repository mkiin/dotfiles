{ lnk, lib, ... }:
{
  xdg.configFile = {
    "wallust/wallust.toml".source = lnk ./wallust.toml;
    "wallust/templates/waybar.css".source = lnk ./templates/waybar.css;
    "wallust/templates/ghostty.conf".source = lnk ./templates/ghostty.conf;
    "wallust/templates/wezterm.toml".source = lnk ./templates/wezterm.toml;
    "wallust/templates/pywal-colors.json".source = lnk ./templates/pywal-colors.json;
  };

  # colors-waybar.css も初回未生成。waybar と wlogout が共有するため置いておく。
  home.activation.fallbackWaybarColorsWallust = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/waybar/colors-waybar.css"
    [ -e "$t" ] || $DRY_RUN_CMD install -Dm644 ${./fallback/colors-waybar.css} "$t"
  '';
}
