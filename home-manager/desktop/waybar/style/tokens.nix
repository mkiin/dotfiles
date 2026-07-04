# waybar style のセマンティックトークン (単一情報源)。
# 寸法・色の変更は必ずここで行い、style/render.sh で style.css を再生成する。
# 個別 CSS ルールへの px 直書き・その場しのぎの調整は禁止 (CLAUDE.md 参照)。
{
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
}
