#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/themes/capture.rasi"

sel="$(
  printf '%s\n' \
    "󰩭" \
    "󰖯" \
    "󰍹" |
    rofi -dmenu -l 3 -theme "$theme"
)" || exit 0

case "$sel" in
"󰩭") hyprshot-rs -m region ;;
"󰖯") hyprshot-rs -m window -m active ;;
"󰍹") hyprshot-rs -m output -m active ;;
esac
