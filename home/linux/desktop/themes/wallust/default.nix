{
  lib,
  pkgs,
  ...
}:

let
  # fallback ファイル名と、その配置先（target）の対応マップ
  fallbackTargets = {
    "waybar.css" = "$HOME/.config/waybar/colors.css";
    "wlogout.css" = "$HOME/.config/wlogout/colors.css";
    "hyprlock.conf" = "$HOME/.config/hyprlock/colors.conf";
    "ghostty.conf" = "$HOME/.config/ghostty/themes/wallust";
    "wezterm.toml" = "$HOME/.config/wezterm/colors/wallust.toml";
    "pywal.json" = "$HOME/.cache/wal/colors.json";
  };

  # マップから activation シェルスクリプトを自動生成
  mkFallbackScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (file: target: ''
      t="${target}"
      [ -e "$t" ] || $DRY_RUN_CMD install -Dm644 ${./fallback + "/${file}"} "$t"
    '') fallbackTargets
  );
in
{
  home.packages = [ pkgs.wallust ];

  xdg.configFile = {
    "wallust/wallust.toml".source = ./wallust.toml;
    "wallust/templates".source = ./templates;
  };

  # 初回ビルド時に未生成のファイルだけフォールバックを自動配置
  home.activation.setupWallustFallbacks = lib.hm.dag.entryAfter [ "writeBoundary" ] mkFallbackScript;
}
