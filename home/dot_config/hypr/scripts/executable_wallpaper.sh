#!/usr/bin/env bash
# 壁紙切替 API (単一責任、連鎖を全部ここで持つ)
#   wallpaper.sh <image>
#
# 連鎖: awww img + matugen image (並行) → hyprctl reload
# waybar は matugen の post_hook (waybar-reload-css.sh) で style.css を in-place rewrite、
# reload_style_on_change 経由で CSS だけ再読させる。surface 維持なのでタイル window が
# ガクつかない (SIGUSR2 は Client::reset() で surface 再生成するためガクつく)。
# matugen / hyprctl が失敗しても壁紙変更自体は成功扱いで継続。

set -euo pipefail

img="${1:?usage: wallpaper.sh <image>}"

# awww と matugen は同じ画像ファイルを読むだけで互いに独立 → 並行化で短縮。
# transition 調整 (144Hz モニター前提、NVIDIA + 多モニター環境で stutter 抑制):
#   --transition-fps 120        デフォ30は粗い。120fpsで滑らか
#   --transition-duration 0.4   デフォ3秒→0.4秒、負荷継続時間も短縮
#   --transition-step 180       デフォ90→180、色変化を倍速化して中間フレーム削減
#   --transition-bezier         hyprland の easeOutQuint と同値 (急始動→滑終了)
awww img "$img" \
  --transition-type grow \
  --transition-fps 120 \
  --transition-duration 3 \
  --transition-step 90 \
  --transition-bezier .23,1,.32,1 &
awww_pid=$!

# --source-color-index 0: matugen 4.0.0 以降 `image` は上位 5 色から対話選択する UI が
# デフォルト有効化されており、TTY 無しの呼び出し (walker activate, hyprland exec 等) で
# dialoguer が `not a terminal` を返して失敗する。index 0 (最頻色) 固定で対話回避。
matugen image "$img" --source-color-index 0 &
matugen_pid=$!

wait "$awww_pid" || echo "[wallpaper.sh] awww img failed" >&2
wait "$matugen_pid" || echo "[wallpaper.sh] matugen failed" >&2

# bed-mode 中は hyprctl reload を抑制 (monitors.conf がデフォルト = 3枚なので、
# reload するとモニター構成が崩壊し awww トランジションも中断される)。
# Hyprland の colors.conf は次回 reload まで古いままになるが、waybar は matugen の
# post_hook で CSS を自動更新するので主要な視覚要素は追従する。
mode="$(cat "${XDG_RUNTIME_DIR:-/tmp}/hypr-monitor-mode" 2>/dev/null || echo desk)"
if [ "$mode" = "bed" ]; then
    echo "[wallpaper.sh] bed-mode: skipping hyprctl reload to preserve monitor state" >&2
else
    hyprctl reload || echo "[wallpaper.sh] hyprctl reload failed" >&2
fi
