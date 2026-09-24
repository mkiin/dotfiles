#!/usr/bin/env bash
set -euo pipefail
img="$(noctalia msg wallpaper-get)"
wallust run "$img" --quiet
