#!/usr/bin/env bash
set -euo pipefail

img="${NOCTALIA_WALLPAPER_PATH:-$(noctalia msg wallpaper-get)}"

wallust run "$img" --quiet
