#!/usr/bin/env bash
set -euo pipefail
img="$(noctalia msg wallpaper-get)"
wallust run "$img" --quiet

# style.css is a Home Manager symlink into the read-only Nix store.
pkill -SIGUSR2 -x waybar
