#!/usr/bin/env bash
set -euo pipefail

WALLSET_RANDOM_ON_STARTUP=true

WALLPAPER_DIR="${HOME}/pictures/wallpaper"
FALLBACK="${WALLPAPER_DIR}/1297749.jpg"
PICKER="${HOME}/.config/hypr/scripts/wallset-pick-random.sh"

if ! awww query >/dev/null 2>&1; then
  awww-daemon >/dev/null 2>&1 &
  disown
  for _ in $(seq 1 50); do
    awww query >/dev/null 2>&1 && break
    sleep 0.1
  done
fi

if [[ "$WALLSET_RANDOM_ON_STARTUP" == "true" ]]; then
  exec "$PICKER"
else
  if ! awww restore 2>/dev/null; then
    if [[ -f "$FALLBACK" ]]; then
      awww img --transition-type none "$FALLBACK"
    else
      echo "[wallset-backend-startup] no restore cache and fallback missing: $FALLBACK" >&2
      exit 1
    fi
  fi
fi
