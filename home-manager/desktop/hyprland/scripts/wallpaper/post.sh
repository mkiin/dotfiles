#!/usr/bin/env bash
set -euo pipefail

# pyprland wallpapers の post_command。壁紙セット(set.sh)後の色生成と波及のみを担う。
# awww img は set.sh に移譲済み。
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/wallpaper-apply.log"
LAST="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/last_wallpaper"
STATE="$HOME/.config/hypr/scripts/hyprctl-state"
mkdir -p "$(dirname "$LOG")"

log() { printf '[%s pid=%d post] %s\n' "$(date +%FT%T.%3N)" "$$" "$*" >>"$LOG"; }

# init.sh 廃止に伴い log cap をここへ移設。毎回の wc は安価。~20-40 回分の履歴を保持。
if [[ -s $LOG ]] && (($(wc -l <"$LOG") > 2000)); then
  tail -n 1000 "$LOG" >"$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

# 並列子プロセス管理。spawn で push、wait_all で全 wait + 終了コード log。
declare -a PIDS=() TAGS=()
spawn() {
  local tag="$1"
  shift
  ("$@") >>"$LOG" 2>&1 &
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
  matugen image "$1" --source-color-index "$2" ||
    matugen image "$1" --source-color-index 0
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

  spawn matugen matugen_with_fallback "$img" "$source_idx"
  # wallust: matugen が出さない @color0..15 (Pywal 系) を waybar style 用に追加生成
  spawn wallust wallust run "$img" --quiet

  wait_all
}

notify_downstream() {
  # matugen の post_hook で reload すると wallust 完了前に走り、@color3 等が古いまま固定される race になる
  "$HOME/.config/hypr/scripts/waybar/reload-css.sh" 2>>"$LOG" ||
    log "waybar/reload-css failed rc=$?"

  # ghostty: theme ファイルは window 起動時にしか読まれず split は親 window のキャッシュを継承する。
  # wallust 後に SIGUSR2 で全 ghostty に reload_config を要求。
  pkill -x -SIGUSR2 ghostty 2>>"$LOG" &&
    log "ghostty SIGUSR2 sent" ||
    log "ghostty SIGUSR2 failed rc=$? (no running ghostty?)"

  # Hyprland の $variable は parse 時に値置換されるため、border 等の既評価ルールに新色を伝播するには全 reload が必要
  hyprctl reload 2>>"$LOG" || log "hyprctl reload failed rc=$?"
}

img="${1:?usage: post.sh <image>}"

log "=== invoked img=$img"
run_color_pipeline "$img"
notify_downstream
# mode.sh がモード切替時に参照するため last_wallpaper を書き続ける。
echo "$img" >"$LAST"
log "=== complete last_wallpaper=$img"
