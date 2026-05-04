#!/usr/bin/env bash
set -uo pipefail

STATE="$HOME/.config/hypr/scripts/hyprctl-state"
PICKER="$HOME/.config/hypr/scripts/wallpaper/pick.sh"
SLICE=30

while :; do
  elapsed=0
  while :; do
    INTERVAL=$("$STATE" get WALLPAPER_INTERVAL_SEC)
    (( elapsed >= INTERVAL )) && break
    sleep "$SLICE"
    elapsed=$((elapsed + SLICE))
  done
  ROTATION=$("$STATE" get WALLPAPER_ROTATION)
  if [[ "$ROTATION" == "true" ]]; then
    "$PICKER" || echo "[wallpaper/rotate] pick failed (continuing)" >&2
  fi
done
