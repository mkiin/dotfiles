#!/usr/bin/env bash
set -euo pipefail
# style.css is a Home Manager symlink into the read-only Nix store.
pkill -SIGUSR2 -x waybar
