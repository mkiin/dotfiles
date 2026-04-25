#!/usr/bin/env bash
# 壁紙切替 API (単一責任、連鎖を全部ここで持つ)
#   wallset-backend <image>
#
# 連鎖: awww img + matugen image (並行) → hyprctl reload
# waybar は matugen の post_hook (waybar-reload-css.sh) で style.css を in-place rewrite、
# reload_style_on_change 経由で CSS だけ再読させる。surface 維持なのでタイル window が
# ガクつかない (SIGUSR2 は Client::reset() で surface 再生成するためガクつく)。
# matugen / hyprctl が失敗しても壁紙変更自体は成功扱いで継続。

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

# --source-color-index 0: matugen 4.0.0 以降 `image` は上位 5 色から対話選択する UI が
# デフォルト有効化されており、TTY 無しの呼び出し (walker activate, hyprland exec 等) で
# dialoguer が `not a terminal` を返して失敗する。index 0 (最頻色) 固定で対話回避。
matugen image "$img" --source-color-index 0 &
matugen_pid=$!

wait "$awww_pid" || echo "[wallset-backend] awww img failed" >&2
wait "$matugen_pid" || echo "[wallset-backend] matugen failed" >&2

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
