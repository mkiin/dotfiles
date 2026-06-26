#!/usr/bin/env bash
set -euo pipefail

LOG="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/wallpaper-apply.log"
LAST="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/last_wallpaper"
STATE="$HOME/.config/hypr/scripts/hyprctl-state"

log() { printf '[%s pid=%d apply] %s\n' "$(date +%FT%T.%3N)" "$$" "$*" >>"$LOG"; }

# 並列子プロセス管理。spawn で push、wait_all で全 wait + 終了コード log。
# タスクを増やすときは spawn 行を追加するだけ。
declare -a PIDS=() TAGS=()
spawn() {
  local tag="$1"
  shift
  ( "$@" ) >>"$LOG" 2>&1 &
  PIDS+=("$!")
  TAGS+=("$tag")
  log "$tag bg pid=$!"
}
wait_all() {
  local i pid tag rc
  for i in "${!PIDS[@]}"; do
    pid="${PIDS[$i]}"
    tag="${TAGS[$i]}"
    rc=0
    wait "$pid" || rc=$?
    log "$tag exit=$rc"
  done
  PIDS=()
  TAGS=()
}

# matugen が指定 index で失敗したら 0 で再試行する safety net。
matugen_with_fallback() {
  matugen image "$1" --source-color-index "$2" \
    || matugen image "$1" --source-color-index 0
}

run_color_pipeline() {
  local img="$1" source_idx

  # --source-color-index 省略時に非 tty 起動で対話 UI に落ちて失敗するため必須。
  if [[ "$("$STATE" get MATUGEN_RANDOM_INDEX)" == "true" ]]; then
    source_idx=$((RANDOM % 4))
  else
    source_idx=$("$STATE" get MATUGEN_SOURCE_INDEX)
  fi
  log "matugen SOURCE_IDX=$source_idx"

  spawn awww awww img "$img" \
    --transition-type grow \
    --transition-fps 120 \
    --transition-duration 3 \
    --transition-step 90 \
    --transition-bezier .23,1,.32,1
  spawn matugen matugen_with_fallback "$img" "$source_idx"
  # wallust: matugen が出さない @color0..15 (Pywal 系) を waybar style 用に追加生成
  spawn wallust wallust run "$img" --quiet

  wait_all
}

notify_downstream() {
  log "awww query after:"
  awww query >>"$LOG" 2>&1 || log "  awww query failed rc=$?"

  # matugen の post_hook で reload すると wallust 完了前に走り、@color3 等が古いまま固定される race になる
  "$HOME/.config/hypr/scripts/waybar/reload-css.sh" 2>>"$LOG" \
    || log "waybar/reload-css failed rc=$?"

  # ghostty: theme ファイルは window 起動時にしか読まれず split は親 window のキャッシュを継承する。
  # wallust 後に SIGUSR2 で全 ghostty に reload_config を要求。
  pkill -x -SIGUSR2 ghostty 2>>"$LOG" \
    && log "ghostty SIGUSR2 sent" \
    || log "ghostty SIGUSR2 failed rc=$? (no running ghostty?)"

  # Hyprland の $variable は parse 時に値置換されるため、border 等の既評価ルールに新色を伝播するには全 reload が必要 (colors.conf 単体 source では不十分)
  # boot 経路 (init→pick→apply) は reload 完了を待たず exec を抜けて起動体感を縮める。
  if [[ "${WALLPAPER_BOOT:-}" == 1 ]]; then
    hyprctl reload >>"$LOG" 2>&1 &
    disown
    log "hyprctl reload backgrounded (boot path)"
  else
    hyprctl reload 2>>"$LOG" || log "hyprctl reload failed rc=$?"
  fi
}

persist_last() {
  local img="$1"
  echo "$img" >"$LAST"
  log "wrote last_wallpaper=$img"
}

maybe_notify() {
  local img="$1"
  if [[ "$("$STATE" get WALLPAPER_NOTIFY)" == "true" ]]; then
    source "$HOME/.config/scripts/notify.sh"
    notify --app "wallset" --icon "preferences-desktop-wallpaper" \
      "Wallpaper changed" "$(basename "$img")"
  fi
}

img="${1:?usage: apply.sh <image>}"

log "=== invoked img=$img"
log "img exists=$([[ -f $img ]] && echo yes || echo no) size=$(stat -c %s "$img" 2>/dev/null || echo ?)"
log "last_cache=$(cat "$LAST" 2>/dev/null || echo '<none>')"
log "awww query before:"
awww query >>"$LOG" 2>&1 || log "  awww query failed rc=$?"

run_color_pipeline "$img"
notify_downstream
persist_last "$img"
maybe_notify "$img"
log "=== complete"
