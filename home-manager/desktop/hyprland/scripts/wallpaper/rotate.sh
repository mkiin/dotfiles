#!/usr/bin/env bash
set -uo pipefail

STATE="$HOME/.config/hypr/scripts/hyprctl-state"
PICKER="$HOME/.config/hypr/scripts/wallpaper/pick.sh"

INTERVAL=$("$STATE" get WALLPAPER_INTERVAL_SEC)
SLEEP_PID=

# rofi-wallpaper-settings から SIGUSR1 を受けたら INTERVAL を即時再読込し、
# 進行中の sleep を kill して新 INTERVAL で再ループする。
reload_interval() {
  INTERVAL=$("$STATE" get WALLPAPER_INTERVAL_SEC)
  [[ -n $SLEEP_PID ]] && kill "$SLEEP_PID" 2>/dev/null
}
trap reload_interval USR1

while :; do
  sleep "$INTERVAL" &
  SLEEP_PID=$!
  wait "$SLEEP_PID" 2>/dev/null
  rc=$?
  SLEEP_PID=

  # rc>128 は signal 起因の中断 (USR1 reload など)。ROTATE せずに wait をやり直す。
  ((rc > 128)) && continue

  ROTATION=$("$STATE" get WALLPAPER_ROTATION)
  if [[ $ROTATION == "true" ]]; then
    "$PICKER" || printf '%s\n' "[wallpaper/rotate] pick failed (continuing)" >&2
  fi
done
