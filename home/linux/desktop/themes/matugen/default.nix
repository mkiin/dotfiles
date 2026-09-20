{
  lib,
  pkgs,
  ...
}:

let
  fallbackTargets = {
    "rofi.rasi" = "$HOME/.config/rofi/themes/colors.rasi";
    "hyprland.lua" = "$HOME/.config/hypr/colors.lua";
    # "wlogout.css" = "$HOME/.config/wlogout/colors.css";
    "quickshell.json" = "$HOME/.cache/quickshell/matugen-colors.json";
  };

  # fallback/ 配下に実際に存在するファイルだけを対象に activation script を生成
  mkFallbackScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (file: target: ''
      t="${target}"
      src=${./fallback + "/${file}"}
      if [ -f "$src" ]; then
        [ -e "$t" ] || $DRY_RUN_CMD install -Dm644 "$src" "$t"
      fi
    '') fallbackTargets
  );
in
{
  home.packages = [ pkgs.matugen ];

  xdg.configFile = {
    "matugen/config.toml".source = ./config.toml;
    # テンプレートはディレクトリごと一括リンク
    "matugen/templates".source = ./templates;
  };

  # 初回起動時のフォールバック配置
  home.activation.setupMatugenFallbacks = lib.hm.dag.entryAfter [ "writeBoundary" ] mkFallbackScript;
}
