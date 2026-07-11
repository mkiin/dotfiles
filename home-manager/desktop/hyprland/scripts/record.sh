#!/usr/bin/env bash
set -euo pipefail

pid_file="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder.pid"

# 録画中ならモードに関わらず停止（SIGINT で moov atom を確定させる）
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

# 第 1 引数: region=範囲録画 / 空=全体録画 / それ以外=保存先ディレクトリ指定の全体録画
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
  # gsr が region キャプチャに対応していなければ開始せず通知（wf-recorder へフォールバックしない）
  if ! gpu-screen-recorder --list-capture-options 2>/dev/null | grep -qw region; then
    notify-send -a "record" "画面録画" "このバージョンの gpu-screen-recorder は範囲録画に対応していません"
    exit 0
  fi
  selection=$(slurp) || exit 0
  # slurp 出力 "X,Y WxH" → gsr の "WxH+X+Y"。マルチモニタで X/Y は負になり得る
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
  # 領域指定の引数名・形式は実機の gpu-screen-recorder --help を正とする（未対応版なら上で弾く）
  gpu-screen-recorder -w region -region "$region" -f 60 -k h264 -a default_output -o "$file" >/dev/null 2>&1 &
  echo $! >"$pid_file"
  notify-send -a "record" "範囲録画を開始" "$(basename "$file")"
  exit 0
fi

monitor=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
gpu-screen-recorder -w "$monitor" -f 60 -k h264 -a default_output -o "$file" >/dev/null 2>&1 &
echo $! >"$pid_file"
notify-send -a "record" "画面録画を開始" "$monitor → $(basename "$file")"
