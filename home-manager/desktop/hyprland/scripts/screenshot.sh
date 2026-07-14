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
edit)
  # region と同じ範囲選択 → satty で注釈/トリミングして保存・コピー。
  # satty がクリップボードと保存を担うので共通の grim/wl-copy 経路は通さず即終了。
  class=$(hyprctl activewindow -j | jq -r '.class // "unknown"')
  class="${class//[\/\\ ]/_}"
  out_dir="${base_dir}/${class}"
  geom=$(slurp) || exit 0
  [ -z "$geom" ] && exit 0
  mkdir -p "$out_dir"
  file="${out_dir}/$(date +%Y%m%d_%H%M%S).png"
  grim -g "$geom" - | satty --filename - --output-filename "$file" --early-exit --copy-command wl-copy
  exit 0
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
  target="${2:-}"
  if [ -n "$target" ]; then
    # 指定モニターの存在確認。無ければ撮らずに通知して終了（誤った画面を撮らない）
    exists=$(hyprctl monitors -j | jq -r --arg n "$target" 'any(.[]; .name == $n)')
    if [ "$exists" != "true" ]; then
      notify-send -a "screenshot" "スクリーンショット" "モニター ${target} が見つかりません"
      exit 0
    fi
    monitor="$target"
  else
    monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name // "unknown"')
  fi
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
