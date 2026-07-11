#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/themes/capture.rasi"
record="$HOME/.config/hypr/scripts/record.sh"
pid_file="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder.pid"

if [[ -f $pid_file ]] && pid=$(<"$pid_file") && kill -0 "$pid" 2>/dev/null; then
  # 録画中: 󰛿 停止のみ
  sel=$(printf '%s\n' "󰛿" | rofi -dmenu -theme "$theme") || exit 0
  [[ -n $sel ]] && "$record"
  exit 0
fi

# 非録画中: 󰻃 全体 / 󰩭 範囲
sel=$(printf '%s\n' "󰻃" "󰩭" | rofi -dmenu -theme "$theme") || exit 0
case "$sel" in
"󰻃") "$record" ;;
"󰩭") "$record" region ;;
esac
