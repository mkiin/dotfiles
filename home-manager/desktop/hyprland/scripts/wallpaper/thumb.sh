#!/usr/bin/env bash
set -euo pipefail

SRC="${HOME}/Pictures/wallpaper"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-thumbs"
mkdir -p "$CACHE"

while IFS= read -r -d '' img; do
  name=$(basename "$img")
  thumb="$CACHE/${name%.*}.jpg"

  if [[ -f $thumb && $thumb -nt $img ]]; then
    continue
  fi

  if magick "$img" \
    -strip \
    -colorspace sRGB \
    -resize 416x234^ \
    -gravity center -extent 416x234 \
    -unsharp 0x0.75+0.75+0.008 \
    -quality 85 \
    -interlace Plane \
    "$thumb.tmp"; then
    mv "$thumb.tmp" "$thumb"
    echo "generated: $name"
  else
    rm -f "$thumb.tmp"
    echo "FAILED: $name" >&2
  fi
done < <(fd --max-depth 1 --type f \
  -e jpg -e jpeg -e png -e webp \
  . "$SRC" --print0)

while IFS= read -r -d '' thumb; do
  name=$(basename "$thumb" .jpg)
  if ! compgen -G "$SRC/${name}.*" >/dev/null; then
    rm "$thumb"
    echo "removed orphan: $(basename "$thumb")"
  fi
done < <(fd --max-depth 1 --type f -e jpg . "$CACHE" --print0)
