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
"󰩭") hyprcap shot region --copy --write ;;
"󰖯") hyprcap shot window:active --copy --write ;;
"󰍹") hyprcap shot monitor:active --copy --write ;;
esac
