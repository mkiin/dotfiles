#!/usr/bin/env bash
set -euo pipefail

LOG="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/wallpaper-apply.log"
log() { printf '[%s pid=%d pick] %s\n' "$(date +%FT%T.%3N)" "$$" "$*" >>"$LOG"; }

WALLPAPER_DIR="${WALLPAPER_DIR:?WALLPAPER_DIR must be set}"
SCHEDULE="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/wallpaper-schedule.txt"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-shuffled.txt"
LAST="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/last_wallpaper"
APPLY="$HOME/.config/hypr/scripts/wallpaper/apply.sh"

regenerate_cache() {
  declare -a SRC=()
  if [[ -f $SCHEDULE ]]; then
    while IFS= read -r line; do
      [[ -z $line || $line =~ ^[[:space:]]*# ]] && continue
      [[ $line == "~/"* ]] && line="${HOME}/${line#~/}"
      if [[ -f $line ]]; then
        SRC+=("$line")
      else
        log "skip missing: $line"
      fi
    done <"$SCHEDULE"
    log "schedule loaded count=${#SRC[@]}"
  fi

  if [[ ${#SRC[@]} -eq 0 ]]; then
    mapfile -t SRC < <(fd --no-ignore --max-depth 1 --type f -e jpg -e jpeg -e png -e webp . "$WALLPAPER_DIR" 2>/dev/null | sort)
    log "fallback dir listing count=${#SRC[@]}"
  fi

  if [[ ${#SRC[@]} -eq 0 ]]; then
    log "ERROR no images for cache"
    return 1
  fi

  mkdir -p "$(dirname "$CACHE")"
  printf '%s\n' "${SRC[@]}" | shuf >"$CACHE"
  log "cache regenerated and shuffled count=${#SRC[@]}"

  # round 境界での被り防止: 新 queue の head が直前の壁紙と同じなら末尾へ回す。
  # N=1 では同一画像しか無いのでループ継続、N>=2 で必ず別画像に切り替わる。
  if [[ -f $LAST ]]; then
    local last_path head_path
    last_path=$(<"$LAST")
    IFS= read -r head_path <"$CACHE"
    if [[ -n $last_path && $head_path == "$last_path" && ${#SRC[@]} -gt 1 ]]; then
      tail -n +2 "$CACHE" >"$CACHE.tmp"
      printf '%s\n' "$head_path" >>"$CACHE.tmp"
      mv "$CACHE.tmp" "$CACHE"
      log "round boundary swap: head==last, rotated to tail"
    fi
  fi
}

pop_head() {
  IFS= read -r PICK <"$CACHE" || PICK=""
  tail -n +2 "$CACHE" >"$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
}

if [[ ! -s $CACHE ]]; then
  log "queue empty, regenerating"
  regenerate_cache || {
    printf '%s\n' "[wallpaper/pick] no images" >&2
    exit 1
  }
fi

pop_head

if [[ -z $PICK ]]; then
  log "queue head was empty, regenerating"
  regenerate_cache || {
    printf '%s\n' "[wallpaper/pick] no images" >&2
    exit 1
  }
  pop_head
fi

log "PICK=$PICK"

exec "$APPLY" "$PICK"
