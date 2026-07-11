#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/themes/capture.rasi"
record="$HOME/.config/hypr/scripts/record.sh"
pid_file="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder.pid"

if [[ -f $pid_file ]] && pid=$(<"$pid_file") && kill -0 "$pid" 2>/dev/null; then
  sel=$(printf '%s\n' "󰛿" | rofi -dmenu -l 1 -theme "$theme") || exit 0
  [[ -n $sel ]] && "$record"
  exit 0
fi

sel=$(printf '%s\n' "󰻃" "󰩭" | rofi -dmenu -l 2 -theme "$theme") || exit 0
case "$sel" in
"󰻃") "$record" ;;
"󰩭") "$record" region ;;
esac
