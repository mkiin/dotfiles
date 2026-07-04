# tokens.nix を受けて style.css の中身を返す。render.sh から使う。
t: ''
  /* ===== 生成ファイル: 手編集禁止 =====
   * 寸法・質感は style/tokens.nix で変更し、style/render.sh で再生成する。
   * ダークグラス・アイランド単一スタイル。色は matugen 生成の colors.css
   * (MD3 トークン) のみに依存。すりガラスは hyprland 側 layerrule が担当。 */

  @import "colors.css";

  @define-color glass_tint ${t.glassTint};
  @define-color glass_border ${t.glassBorder};
  /* tooltip は blur が乗らない別サーフェスなので濃いめにして可読性を確保 */
  @define-color tooltip_bg ${t.tooltipBg};

  /* ============================================================
     Reset
     ============================================================ */
  * {
    border: none;
    border-radius: 0;
    font-family:
      "JetBrainsMono Nerd Font", "Iosevka Nerd Font", "Font Awesome 6 Free";
    font-size: ${t.fontSize};
    margin: 0;
    padding: 0;
    min-height: 1px;
  }

  window#waybar {
    background-color: transparent;
    color: @on_surface;
  }

  /* GTK Adwaita 既定の button/tooltip 装飾を無効化 */
  button {
    box-shadow: none;
    outline: none;
    text-shadow: none;
    background-image: none;
  }

  button:hover,
  button:focus,
  button:focus-visible {
    box-shadow: none;
    outline: none;
    background-image: none;
  }

  tooltip {
    background-image: none;
    box-shadow: none;
    text-shadow: none;
  }

  tooltip label {
    background-image: none;
  }

  /* ============================================================
     Island
     バーに載る group は全部 `group/<name>#island` で .island class を持つ。
     #window だけは group で包むと空タイトル時に空枠が残るため裸のまま
     同じ質感を当てる (唯一の例外)。
     ============================================================ */
  .island,
  #window {
    background-color: @glass_tint;
    border: 1px solid @glass_border;
    border-radius: ${t.radiusIsland};
    padding: 0 ${t.padIslandX};
    margin: 0 ${t.gapIsland};
    color: @on_surface;
  }

  /* 島内モジュールは島の背景に乗るだけ。個別 ID は列挙しない */
  .island > * {
    background-color: transparent;
    border: none;
    border-radius: 0;
    margin: 0;
    padding: 0 ${t.gapModule};
  }

  /* フォーカスウィンドウが無いときは window 島ごと消す */
  window#waybar.empty #window {
    background-color: transparent;
    border: none;
    padding: 0;
    margin: 0;
  }

  /* ============================================================
     Workspaces
     非アクティブは小ドット (文字色を透明にして丸だけ見せる)、
     アクティブは @primary の横長ピル。
     ============================================================ */
  #workspaces button {
    min-width: ${t.wsButtonMinWidth};
    margin: ${t.wsButtonMargin};
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

  /* ============================================================
     状態色
     ============================================================ */
  #custom-nix {
    color: @primary;
  }

  #custom-power {
    color: @primary;
  }

  #network.disconnected {
    color: @state_critical;
  }

  #pulseaudio.muted {
    color: @primary;
  }

  #privacy {
    color: @primary;
  }

  #temperature.critical {
    color: @state_critical;
  }

  #custom-idle_inhibitor.activated {
    color: @primary;
  }

  #custom-control-center.dnd-none,
  #custom-control-center.dnd-notification,
  #custom-control-center.dnd-inhibited-none,
  #custom-control-center.dnd-inhibited-notification {
    color: @primary;
  }

  /* ============================================================
     Tooltip
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
