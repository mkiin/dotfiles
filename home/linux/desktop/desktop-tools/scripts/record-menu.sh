#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/themes/capture.rasi"

sel="$(
  printf '%s\n' \
    "󰍹" \
    "󰖯" \
    "󰻃" \
    "󰩭" \
    "󰛿" |
    rofi -dmenu -l 5 -theme "$theme"
)" || exit 0

case "$sel" in
"󰍹")
  hyprcap rec-start monitor:active
  ;;
"󰖯")
  hyprcap rec-start window
  ;;
"󰻃")
  hyprcap rec-start window:active
  ;;
"󰩭")
  hyprcap rec-start region
  ;;
"󰛿")
  hyprcap rec-stop
  ;;
esac
