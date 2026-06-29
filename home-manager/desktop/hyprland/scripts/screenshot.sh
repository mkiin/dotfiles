#!/usr/bin/env bash
set -euo pipefail

mode="${1:?usage: screenshot.sh <region|window|output>}"
base_dir="${HOME}/Pictures/Screenshots"
monitor=""
geom=""

case "$mode" in
region)
  class=$(hyprctl activewindow -j | jq -r '.class // "unknown"')
  class="${class//[\/\\ ]/_}"
  out_dir="${base_dir}/${class}"
  # slurp で範囲選択。Esc / 空選択ならキャンセル（撮影も通知もせず終了）
  geom=$(slurp) || exit 0
  [ -z "$geom" ] && exit 0
  ;;
window)
  class=$(hyprctl activewindow -j | jq -r '.class // "unknown"')
  class="${class//[\/\\ ]/_}"
  out_dir="${base_dir}/${class}"
  # 表示中ウィンドウの矩形を slurp に渡して選択。Esc / 空選択でキャンセル
  geom=$(hyprctl clients -j |
    jq -r '.[] | select(.mapped == true and .hidden == false) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' |
    slurp) || exit 0
  [ -z "$geom" ] && exit 0
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
file="${out_dir}/$(date +%Y%m%d_%H%M%S).png"

if [ -n "$geom" ]; then
  grim -g "$geom" "$file"
else
  grim -o "$monitor" "$file"
fi

wl-copy --type image/png <"$file"

notify-send -a "screenshot" "スクリーンショット" "$file に保存しました（クリップボードにコピー済み）"
