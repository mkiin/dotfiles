#!/usr/bin/env bash
set -uo pipefail

INTERVAL="${WALLPAPER_INTERVAL:-900}"
PICKER="${HOME}/.config/hypr/scripts/wallpaper/pick.sh"

while :; do
  sleep "$INTERVAL"
  "$PICKER" || echo "[wallpaper/rotate] pick failed (continuing)" >&2
done
