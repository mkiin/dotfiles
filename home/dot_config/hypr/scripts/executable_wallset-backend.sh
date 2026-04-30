#!/usr/bin/env bash
set -euo pipefail

img="${1:?usage: wallset-backend <image>}"

awww img "$img" \
  --transition-type grow \
  --transition-fps 120 \
  --transition-duration 3 \
  --transition-step 90 \
  --transition-bezier .23,1,.32,1 &
awww_pid=$!

# matugen は画像から上位 5 色を抽出。同じ壁紙でも見た目を変えるため 0-3 でランダム選択し、抽出色が足りない画像用に 0 fallback。
# --source-color-index を渡さないと TTY 対話 UI に落ちて exec/walker 経由で失敗する。
SOURCE_IDX=$((RANDOM % 4))
(matugen image "$img" --source-color-index "$SOURCE_IDX" 2>/dev/null ||
  matugen image "$img" --source-color-index 0) &
matugen_pid=$!

# wallust: matugen が出さない @color0..15 (Pywal 系) を waybar style 用に追加生成
wallust run "$img" --quiet &
wallust_pid=$!

wait "$awww_pid" || echo "[wallset-backend] awww img failed" >&2
wait "$matugen_pid" || echo "[wallset-backend] matugen failed" >&2
wait "$wallust_pid" || echo "[wallset-backend] wallust failed" >&2

# matugen の post_hook で reload すると wallust 完了前に走り、@color3 等が古いまま固定される race になる
"$HOME/.config/hypr/scripts/waybar-reload-css.sh" ||
  echo "[wallset-backend] waybar-reload-css failed" >&2

echo "$img" >"$HOME/.cache/last_wallpaper"

# Hyprland の $variable は parse 時に値置換されるため、border 等の既評価ルールに新色を伝播するには全 reload が必要 (colors.conf 単体 source では不十分)
hyprctl reload ||
  echo "[wallset-backend] hyprctl reload failed" >&2

source "$HOME/.config/scripts/notify.sh"
notify --app "wallset" --icon "preferences-desktop-wallpaper" \
  "Wallpaper changed" "$(basename "$img")"
