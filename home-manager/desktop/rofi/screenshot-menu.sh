#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/themes/capture.rasi"
scripts="$HOME/.config/hypr/scripts"

sel=$(printf '%s\n' "󰩭" "󰖯" "󰍹" | rofi -dmenu -l 3 -theme "$theme") || exit 0

case "$sel" in
"󰩭") "$scripts/screenshot.sh" region ;;
"󰖯") "$scripts/screenshot.sh" window ;;
"󰍹") "$scripts/screenshot.sh" output ;;
esac
