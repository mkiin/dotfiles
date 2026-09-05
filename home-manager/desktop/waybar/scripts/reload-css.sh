#!/usr/bin/env bash
set -euo pipefail

f="${HOME}/.config/waybar/style.css"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cp "$f" "$tmp"
cat "$tmp" >"$f"
