#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-${HOME}/pictures/wallpaper}"
LAST_FILE="${HOME}/.cache/last_wallpaper"
APPLY="${HOME}/.config/hypr/scripts/wallpaper/apply.sh"

mapfile -t FILES < <(fd --max-depth 1 --type f -e jpg -e jpeg -e png -e webp . "$WALLPAPER_DIR" 2>/dev/null | sort)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "[wallpaper/pick] no images in $WALLPAPER_DIR" >&2
  exit 1
fi

LAST=""
[[ -f "$LAST_FILE" ]] && LAST=$(<"$LAST_FILE")

if [[ ${#FILES[@]} -eq 1 ]]; then
  PICK="${FILES[0]}"
else
  while :; do
    PICK="${FILES[RANDOM % ${#FILES[@]}]}"
    [[ "$PICK" != "$LAST" ]] && break
  done
fi

exec "$APPLY" "$PICK"
