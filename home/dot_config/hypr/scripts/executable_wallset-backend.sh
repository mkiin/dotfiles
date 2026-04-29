#!/usr/bin/env bash
# 壁紙切替 API (単一責任、連鎖を全部ここで持つ)
#   wallset-backend <image>
#
# 連鎖: awww img + matugen image + wallust run (並行) → hyprctl reload
# waybar は matugen の post_hook (waybar-reload-css.sh) で style.css を in-place rewrite、
# reload_style_on_change 経由で CSS だけ再読させる。surface 維持なのでタイル window が
# ガクつかない (SIGUSR2 は Client::reset() で surface 再生成するためガクつく)。
# matugen は Material Design 3 トークン (@primary 等) を出力、wallust は Pywal 系 16 色
# パレット (@color0..15) を出力。両方 colors-waybar.css と colors.css に書き出されて
# style.css の @import チェーンを通じて waybar に反映される。
# matugen / wallust / hyprctl が失敗しても壁紙変更自体は成功扱いで継続。

set -euo pipefail

img="${1:?usage: wallset-backend <image>}"

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

# source-color-index: matugen は画像から上位 5 色 (0-4) を抽出。0 = 最頻色固定だと
# 同じ壁紙で常に同じ palette になり面白みがないので 0-3 でランダム化、抽出色が少なく
# 指定 index が無い画像 (=単色寄り) の時は 0 fallback。明示指定で TTY 不要の対話 UI も
# 回避 (walker activate / hyprland exec 経由でも dialoguer エラーにならない)。
SOURCE_IDX=$((RANDOM % 4))
( matugen image "$img" --source-color-index "$SOURCE_IDX" 2>/dev/null \
  || matugen image "$img" --source-color-index 0 ) &
matugen_pid=$!

# wallust: 16 色 Pywal 系パレット → ~/.config/waybar/colors-waybar.css
# noro 系 style プリセットが要求する @color0..15 トークンを供給する。
wallust run "$img" --quiet &
wallust_pid=$!

wait "$awww_pid"    || echo "[wallset-backend] awww img failed" >&2
wait "$matugen_pid" || echo "[wallset-backend] matugen failed" >&2
wait "$wallust_pid" || echo "[wallset-backend] wallust failed" >&2

# matugen + wallust の両方が完了してから waybar reload を走らせる。
# matugen 側の post_hook で reload してしまうと wallust 完了前に発火し、
# `@color3` / tray など wallust 由来の色が古いまま固定される race が起きる。
"$HOME/.config/hypr/scripts/waybar-reload-css.sh" \
  || echo "[wallset-backend] waybar-reload-css failed" >&2

# モード切替時に同じ壁紙を再適用するための last 状態を更新。
# bed-mode.sh / desk-mode.sh が `awww restore` ではなく本ファイルの画像を `awww img`
# で焼き直すことで、disable 中だった側のモニターにも同じ壁紙が乗る。
echo "$img" > "$HOME/.cache/last_wallpaper"

# 全 config を reload する。
# Hyprland は $variable を parse 時に値置換するため、colors.conf だけを source しても
# `col.active_border = $primary $tertiary` 等の既評価ルールには新色が伝播しない。
# 全 reload で初めて全ファイルが再評価され、border 色等が新しい matugen palette を反映する。
#
# bed-mode が吹き飛ばないのは monitors.conf を分割した仕掛けで担保:
#   monitors.conf → monitors-active.conf → 現モードの定義 (bed/desk-mode.sh が書換)
hyprctl reload \
  || echo "[wallset-backend] hyprctl reload failed" >&2

# 通知 (shared notify helper)
source "$HOME/.config/scripts/notify.sh"
notify --app "wallset" --icon "preferences-desktop-wallpaper" \
       "Wallpaper changed" "$(basename "$img")"
