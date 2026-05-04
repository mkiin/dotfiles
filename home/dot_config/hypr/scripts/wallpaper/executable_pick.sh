#!/usr/bin/env bash
set -euo pipefail

LOG="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/wallpaper-apply.log"
log() { printf '[%s pid=%d pick] %s\n' "$(date +%FT%T.%3N)" "$$" "$*" >>"$LOG"; }

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/pictures/wallpaper}"
SCHEDULE="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/wallpaper-schedule.txt"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-shuffled.txt"
APPLY="$HOME/.config/hypr/scripts/wallpaper/apply.sh"
STATE="$HOME/.config/hypr/scripts/hyprctl-state"

regenerate_cache() {
  declare -a SRC=()
  if [[ -f "$SCHEDULE" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
      [[ "$line" == "~/"* ]] && line="${HOME}/${line#~/}"
      if [[ -f "$line" ]]; then
        SRC+=("$line")
      else
        log "skip missing: $line"
      fi
    done < "$SCHEDULE"
    log "schedule loaded count=${#SRC[@]}"
  fi

  if [[ ${#SRC[@]} -eq 0 ]]; then
    mapfile -t SRC < <(fd --max-depth 1 --type f -e jpg -e jpeg -e png -e webp . "$WALLPAPER_DIR" 2>/dev/null | sort)
    log "fallback dir listing count=${#SRC[@]}"
  fi

  if [[ ${#SRC[@]} -eq 0 ]]; then
    log "ERROR no images for cache"
    return 1
  fi

  mkdir -p "$(dirname "$CACHE")"
  printf '%s\n' "${SRC[@]}" | shuf > "$CACHE"
  "$STATE" set WALLPAPER_PLAYLIST_INDEX 0
  log "cache regenerated and shuffled count=${#SRC[@]}"
}

if [[ ! -s "$CACHE" ]]; then
  regenerate_cache || { echo "[wallpaper/pick] no images" >&2; exit 1; }
fi

mapfile -t LIST < "$CACHE"

IDX=$("$STATE" get WALLPAPER_PLAYLIST_INDEX)
IDX=${IDX:-0}

if (( IDX >= ${#LIST[@]} || IDX < 0 )); then
  log "round complete or out-of-bounds, reshuffling"
  regenerate_cache || { echo "[wallpaper/pick] no images" >&2; exit 1; }
  mapfile -t LIST < "$CACHE"
  IDX=0
fi

PICK="${LIST[$IDX]}"
log "PICK=$PICK index=$IDX/${#LIST[@]}"

"$STATE" set WALLPAPER_PLAYLIST_INDEX $((IDX + 1))

exec "$APPLY" "$PICK"
