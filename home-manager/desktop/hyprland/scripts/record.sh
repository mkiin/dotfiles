#!/usr/bin/env bash
set -euo pipefail

out_dir="${1:-${HOME}/Videos}"
pid_file="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder.pid"

if [[ -f "$pid_file" ]] && pid=$(<"$pid_file") && kill -0 "$pid" 2>/dev/null; then
  # SIGINT で正常終了させないと mp4 の moov atom が書かれず再生不能になる
  kill -SIGINT "$pid"
  for _ in {1..50}; do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1
  done
  rm -f "$pid_file"
  notify-send -a "record" "画面録画を停止" "$out_dir に保存しました"
  exit 0
fi

mkdir -p "$out_dir"
monitor=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
file="$out_dir/rec_$(date +%Y%m%d_%H%M%S).mp4"

gpu-screen-recorder -w "$monitor" -f 60 -k h264 -a default_output -o "$file" >/dev/null 2>&1 &
echo $! >"$pid_file"
notify-send -a "record" "画面録画を開始" "$monitor → $(basename "$file")"
