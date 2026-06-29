#!/usr/bin/env bash
set -euo pipefail

mode="${1:?usage: screenshot.sh <region|window|output>}"
base_dir="${HOME}/Pictures/Screenshots"

case "$mode" in
region | window)
  class=$(hyprctl activewindow -j | jq -r '.class // "unknown"')
  class="${class//[\/\\ ]/_}"
  out_dir="${base_dir}/${class}"
  ;;
output)
  monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name // "unknown"')
  out_dir="${base_dir}/output/${monitor}"
  ;;
*)
  echo "[screenshot.sh] unknown mode: $mode" >&2
  exit 1
  ;;
esac

mkdir -p "$out_dir"
hyprshot -m "$mode" --output-folder "$out_dir" --silent || true
notify-send -a "screenshot" "スクリーンショット" "$out_dir に保存しました"
