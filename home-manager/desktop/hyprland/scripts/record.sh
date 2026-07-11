#!/usr/bin/env bash
set -euo pipefail

pid_file="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder.pid"

# SIGINT で正常終了させないと mp4 の moov atom が書かれず再生不能になる
if [[ -f $pid_file ]] && pid=$(<"$pid_file") && kill -0 "$pid" 2>/dev/null; then
  kill -SIGINT "$pid"
  for _ in {1..50}; do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1
  done
  rm -f "$pid_file"
  notify-send -a "record" "画面録画を停止" "保存しました"
  exit 0
fi

mode="full"
out_dir="${HOME}/Videos"
case "${1:-}" in
region) mode="region" ;;
"") ;;
*) out_dir="$1" ;;
esac

mkdir -p "$out_dir"
file="$out_dir/rec_$(date +%Y%m%d_%H%M%S).mp4"

if [[ $mode == region ]]; then
  # --list-capture-options は region を列挙しないので usage の -w 選択肢で判定する
  if ! gpu-screen-recorder --help 2>&1 | grep -qw region; then
    notify-send -a "record" "画面録画" "このバージョンの gpu-screen-recorder は範囲録画に対応していません"
    exit 0
  fi
  selection=$(slurp) || exit 0
  # slurp "X,Y WxH" → gsr "WxH+X+Y"（マルチモニタで X/Y が負になり得る）
  if [[ $selection =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]+([0-9]+)x([0-9]+)$ ]]; then
    x=${BASH_REMATCH[1]}
    y=${BASH_REMATCH[2]}
    width=${BASH_REMATCH[3]}
    height=${BASH_REMATCH[4]}
    region="${width}x${height}+${x}+${y}"
  else
    notify-send -a "record" "画面録画" "選択範囲を解釈できませんでした"
    exit 0
  fi
  gpu-screen-recorder -w region -region "$region" -f 60 -k h264 -a default_output -o "$file" >/dev/null 2>&1 &
  echo $! >"$pid_file"
  notify-send -a "record" "範囲録画を開始" "$(basename "$file")"
  exit 0
fi

monitor=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
gpu-screen-recorder -w "$monitor" -f 60 -k h264 -a default_output -o "$file" >/dev/null 2>&1 &
echo $! >"$pid_file"
notify-send -a "record" "画面録画を開始" "$monitor → $(basename "$file")"
