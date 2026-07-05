# waybar の style.css を生成する自己完結モジュール。
# 寸法・質感の変更はこの先頭の t (セマンティックトークン) だけで行う。
# 個別 CSS ルールへの px 直書き・その場しのぎの調整は禁止
let
  t = {
    # 島の外側
    gapIsland = "6px"; # 島同士の間隔 (片側マージン)
    # 島の内側
    padIslandX = "12px"; # 島の左右パディング
    gapModule = "7px"; # 島内モジュール間 (片側マージン。モジュール間は 2 倍効く)
    # 形状
    radiusIsland = "20px";
    radiusTooltip = "12px";
    # workspaces ボタン (バー高 34 = 枠1x2 + 縦マージン6x2 + 丸20 で割り切る)
    wsDotSize = "20px";
    wsDotMarginY = "6px";
    wsDotGap = "3px";
    wsActiveMinWidth = "50px";
    # tooltip
    padTooltip = "6px 10px";
    padTooltipLabel = "2px 4px";
    # ガラス質感 (色は matugen 非依存の固定値)
    glassTint = "rgba(10, 12, 18, 0.58)";
    glassBorder = "rgba(255, 255, 255, 0.08)";
    tooltipBg = "rgba(10, 12, 18, 0.92)";
    # タイポグラフィ
    fontSize = "14px";
  };
in
''
  /* ===== 生成ファイル: 手編集禁止 =====
   * 寸法・質感は home-manager/desktop/waybar/style.nix の t で変更する。
   * レイヤ構造 (カスケード順に単方向。下の層は上の層の寸法を上書きしない):
   *   0 Reset / 1 Bar / 2 Island / 3 Module / 4 Component / 5 Role,State / 6 Surface
   * 色は matugen 生成の colors.css (MD3 トークン) のみに依存。
   * すりガラスは hyprland 側 layerrule が担当。 */

  @import "colors.css";

  @define-color glass_tint ${t.glassTint};
  @define-color glass_border ${t.glassBorder};
  /* tooltip は blur が乗らない別サーフェスなので濃いめにして可読性を確保 */
  @define-color tooltip_bg ${t.tooltipBg};

  /* ============================================================
     0 Reset: box-model の初期化と GTK テーマ既定装飾の無効化のみ
     ============================================================ */
  * {
    border: none;
    border-radius: 0;
    margin: 0;
    padding: 0;
    min-height: 1px;
  }

  button,
  button:hover,
  button:focus,
  button:focus-visible {
    box-shadow: none;
    outline: none;
    text-shadow: none;
    background-image: none;
  }

  tooltip,
  tooltip label {
    background-image: none;
    box-shadow: none;
    text-shadow: none;
  }

  /* ============================================================
     1 Bar: タイポグラフィと基調色 (font 系は GTK CSS で継承される)
     ============================================================ */
  window#waybar {
    background-color: transparent;
    color: @on_surface;
    font-family:
      "JetBrainsMono Nerd Font", "Iosevka Nerd Font", "Font Awesome 6 Free";
    font-size: ${t.fontSize};
  }

  /* ============================================================
     2 Island: ガラス質感と島同士の間隔
     `group/<name>#island` と `hyprland/window#island` の可視ノードが
     .island クラスを持つ (waybar の #サフィックス機構)。
     ============================================================ */
  .island {
    background-color: @glass_tint;
    border: 1px solid @glass_border;
    border-radius: ${t.radiusIsland};
    padding: 0 ${t.padIslandX};
    margin: 0 ${t.gapIsland};
    color: @on_surface;
  }

  /* フォーカスウィンドウが無いときは window 島を消灯 */
  window#waybar.empty #window {
    background-color: transparent;
    border: none;
    padding: 0;
    margin: 0;
  }

  /* ============================================================
     3 Module: 島の背景に乗るだけ。間隔は margin で取る
     (GTK3 は eventbox への padding をレイアウトに反映しない)。
     子孫コンビネータなので .island.module を両方持つ window の
     label 自身にはマッチしない。
     ============================================================ */
  .island .module {
    background-color: transparent;
    margin: 0 ${t.gapModule};
    padding: 0;
  }

  /* ============================================================
     4 Component: workspaces
     非アクティブは小ドット (文字色を透明にして丸だけ見せる)、
     アクティブは @primary の横長ピル。
     ============================================================ */
  #workspaces button {
    min-width: ${t.wsDotSize};
    min-height: ${t.wsDotSize};
    padding: 0;
    margin: ${t.wsDotMarginY} ${t.wsDotGap};
    color: transparent;
    background-color: alpha(@on_surface, 0.35);
    border-radius: ${t.radiusIsland};
    transition:
      background 0.25s cubic-bezier(0.4, 0, 0.2, 1),
      color 0.25s cubic-bezier(0.4, 0, 0.2, 1),
      min-width 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  }

  #workspaces button.active {
    color: @on_primary;
    background-color: @primary;
    min-width: ${t.wsActiveMinWidth};
  }

  #workspaces button:hover {
    background-color: @secondary_container;
    color: @on_secondary_container;
  }

  #workspaces button.urgent {
    background-color: @error;
    color: @on_error;
  }

  #workspaces button.special {
    color: @on_tertiary;
    background-color: @tertiary;
  }

  /* status 島の区画境界「情報 (cpu/memory) | 接続と音 | tray」。
     線色は島の縁と同じ hairline (@glass_border) */
  #network,
  #tray {
    border-left: 1px solid @glass_border;
    padding-left: ${t.gapModule};
  }

  /* ============================================================
     5 Role, State: 色のみ。寸法を持たない。
     .accent は #サフィックスで配るロールクラス (custom/nix, custom/power)。
     状態クラス (.muted 等) は waybar が動的に付与する。
     ============================================================ */
  .accent {
    color: @primary;
  }

  #network.disconnected {
    color: @state_critical;
  }

  #pulseaudio.muted {
    color: @primary;
  }

  #custom-idle_inhibitor.activated {
    color: @primary;
  }

  #custom-notify.dnd-none,
  #custom-notify.dnd-notification,
  #custom-notify.dnd-inhibited-none,
  #custom-notify.dnd-inhibited-notification {
    color: @primary;
  }

  /* ============================================================
     6 Surface: tooltip (バー外の別サーフェス)
     ============================================================ */
  tooltip {
    background-color: @tooltip_bg;
    border: 1px solid @glass_border;
    border-radius: ${t.radiusTooltip};
    padding: ${t.padTooltip};
  }

  tooltip label {
    color: @on_surface;
    padding: ${t.padTooltipLabel};
  }
''
