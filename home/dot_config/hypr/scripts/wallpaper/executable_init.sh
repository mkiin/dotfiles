#!/usr/bin/env bash
set -euo pipefail

LOG="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/wallpaper-apply.log"
mkdir -p "$(dirname "$LOG")"
log() { printf '[%s pid=%d init] %s\n' "$(date +%FT%T.%3N)" "$$" "$*" >>"$LOG"; }

# log size cap: 2000 行超えたら最新 1000 行に切り詰め (~20-40 boots 分の履歴を保持)。
# rotate.sh 経由の runtime 変更では init.sh は走らないので、cap は次回 boot 時に効く。
if [[ -s "$LOG" ]] && (( $(wc -l <"$LOG") > 2000 )); then
  tail -n 1000 "$LOG" >"$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

STATE="$HOME/.config/hypr/scripts/hyprctl-state"
WALLPAPER_RANDOM_ON_STARTUP=$("$STATE" get WALLPAPER_RANDOM_ON_STARTUP)

WALLPAPER_DIR="${HOME}/pictures/wallpaper"
FALLBACK="${WALLPAPER_DIR}/1297749.jpg"
PICKER="${HOME}/.config/hypr/scripts/wallpaper/pick.sh"

log "=== boot start"

# awww-daemon は起動時に ~/.cache/awww/<ver>/<output> を memory に取り込み、
# wayland output が ready になった瞬間 cache から auto-restore する。
# apply.sh の awww img と race して auto-restore が後勝ちすると、選んだ壁紙が
# 古い cache の壁紙で上書きされる。RANDOM_ON_STARTUP=true なら restore したい
# 値はないので、daemon spawn 前に cache を捨てて race を消す。
if [[ "$WALLPAPER_RANDOM_ON_STARTUP" == "true" ]] && ! awww query >/dev/null 2>&1; then
  rm -f "$HOME/.cache/awww/"*/* 2>/dev/null || true
  log "cleared awww cache to prevent auto-restore race"
fi

if awww query >/dev/null 2>&1; then
  log "awww-daemon already alive"
else
  log "awww-daemon not running, spawning"
  awww-daemon >/dev/null 2>>"$LOG" &
  daemon_pid=$!
  disown
  log "awww-daemon spawned pid=$daemon_pid"
  ready=0
  for i in $(seq 1 50); do
    if awww query >/dev/null 2>&1; then
      log "awww query ready after $((i * 100))ms"
      ready=1
      break
    fi
    sleep 0.1
  done
  [[ $ready -eq 0 ]] && log "WARNING awww query timeout after 5s"
fi

if [[ "$WALLPAPER_RANDOM_ON_STARTUP" == "true" ]]; then
  rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-shuffled.txt"
  log "RANDOM_ON_STARTUP=true, cleared shuffle cache, exec PICKER"
  WALLPAPER_BOOT=1 exec "$PICKER"
else
  log "RANDOM_ON_STARTUP=false, attempting awww restore"
  if ! awww restore 2>>"$LOG"; then
    if [[ -f "$FALLBACK" ]]; then
      log "restore failed, using FALLBACK=$FALLBACK"
      awww img --transition-type none "$FALLBACK"
    else
      log "no restore cache and fallback missing: $FALLBACK"
      echo "[wallpaper/init] no restore cache and fallback missing: $FALLBACK" >&2
      exit 1
    fi
  fi
fi
