#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.cache/wallpaper-apply.log"
log() { printf '[%s pid=%d apply] %s\n' "$(date +%FT%T.%3N)" "$$" "$*" >>"$LOG"; }

img="${1:?usage: apply.sh <image>}"

log "=== invoked img=$img"
log "img exists=$([[ -f $img ]] && echo yes || echo no) size=$(stat -c %s "$img" 2>/dev/null || echo ?)"
log "last_cache=$(cat "$HOME/.cache/last_wallpaper" 2>/dev/null || echo '<none>')"
log "awww query before:"
awww query >>"$LOG" 2>&1 || log "  awww query failed rc=$?"

awww img "$img" \
  --transition-type grow \
  --transition-fps 120 \
  --transition-duration 3 \
  --transition-step 90 \
  --transition-bezier .23,1,.32,1 \
  >>"$LOG" 2>&1 &
awww_pid=$!
log "awww img bg pid=$awww_pid"

# matugen は画像から上位 5 色を抽出。同じ壁紙でも見た目を変えるため 0-3 でランダム選択し、抽出色が足りない画像用に 0 fallback。
# --source-color-index を渡さないと TTY 対話 UI に落ちて exec/walker 経由で失敗する。
SOURCE_IDX=$((RANDOM % 4))
log "matugen SOURCE_IDX=$SOURCE_IDX"
(matugen image "$img" --source-color-index "$SOURCE_IDX" 2>>"$LOG" ||
  matugen image "$img" --source-color-index 0 2>>"$LOG") &
matugen_pid=$!
log "matugen bg pid=$matugen_pid"

# wallust: matugen が出さない @color0..15 (Pywal 系) を waybar style 用に追加生成
wallust run "$img" --quiet >>"$LOG" 2>&1 &
wallust_pid=$!
log "wallust bg pid=$wallust_pid"

awww_rc=0
matugen_rc=0
wallust_rc=0
wait "$awww_pid" || awww_rc=$?
log "awww img    exit=$awww_rc"
wait "$matugen_pid" || matugen_rc=$?
log "matugen     exit=$matugen_rc"
wait "$wallust_pid" || wallust_rc=$?
log "wallust     exit=$wallust_rc"

log "awww query after:"
awww query >>"$LOG" 2>&1 || log "  awww query failed rc=$?"

# matugen の post_hook で reload すると wallust 完了前に走り、@color3 等が古いまま固定される race になる
"$HOME/.config/hypr/scripts/waybar/reload-css.sh" 2>>"$LOG" ||
  log "waybar/reload-css failed rc=$?"

echo "$img" >"$HOME/.cache/last_wallpaper"
log "wrote last_wallpaper=$img"

# Hyprland の $variable は parse 時に値置換されるため、border 等の既評価ルールに新色を伝播するには全 reload が必要 (colors.conf 単体 source では不十分)
hyprctl reload 2>>"$LOG" ||
  log "hyprctl reload failed rc=$?"

source "$HOME/.config/scripts/notify.sh"
notify --app "wallset" --icon "preferences-desktop-wallpaper" \
  "Wallpaper changed" "$(basename "$img")"
log "=== complete"
