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

# matugen が書き換えた colors.conf だけを外科的に再 source する。
# hyprctl reload (全 config 再読込) だと monitors.conf も効いてしまい、
# bed-mode 中の動的モニター構成が吹き飛ぶ。source keyword なら色だけ更新できる。
hyprctl keyword source "$HOME/.config/hypr/colors.conf" \
  || echo "[wallpaper.sh] colors.conf re-source failed" >&2
