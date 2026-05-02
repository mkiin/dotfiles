#!/usr/bin/env bash
set -euo pipefail

LOG="$HOME/.cache/wallpaper-apply.log"
log() { printf '[%s pid=%d pick] %s\n' "$(date +%FT%T.%3N)" "$$" "$*" >>"$LOG"; }

WALLPAPER_DIR="${WALLPAPER_DIR:-${HOME}/pictures/wallpaper}"
LAST_FILE="${HOME}/.cache/last_wallpaper"
APPLY="${HOME}/.config/hypr/scripts/wallpaper/apply.sh"

mapfile -t FILES < <(fd --max-depth 1 --type f -e jpg -e jpeg -e png -e webp . "$WALLPAPER_DIR" 2>/dev/null | sort)

log "=== pick start dir=$WALLPAPER_DIR candidates=${#FILES[@]}"

if [[ ${#FILES[@]} -eq 0 ]]; then
  log "ERROR no images"
  echo "[wallpaper/pick] no images in $WALLPAPER_DIR" >&2
  exit 1
fi

LAST=""
[[ -f "$LAST_FILE" ]] && LAST=$(<"$LAST_FILE")
log "last=$LAST"

if [[ ${#FILES[@]} -eq 1 ]]; then
  PICK="${FILES[0]}"
  log "single candidate, forced PICK=$PICK"
else
  attempts=0
  while :; do
    attempts=$((attempts + 1))
    PICK="${FILES[RANDOM % ${#FILES[@]}]}"
    [[ "$PICK" != "$LAST" ]] && break
  done
  log "PICK=$PICK after $attempts attempts"
fi

log "exec APPLY"
exec "$APPLY" "$PICK"
