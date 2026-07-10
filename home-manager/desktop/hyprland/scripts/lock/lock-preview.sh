#!/usr/bin/env bash
# hyprlock を起動して grim で撮影し SIGUSR1 で即解除する（数秒間ロックされる）。
# 既定ではフォーカス中のモニターのみ撮影する。
# 使い方: lock-preview.sh [出力.png] ["x,y WxH" | モニター名 | all]
set -euo pipefail

OUT="${1:-/tmp/hyprlock-preview.png}"
TARGET="${2:-}"

hyprlock >/dev/null 2>&1 &
trap 'pkill -USR1 hyprlock 2>/dev/null || true' EXIT
sleep 4
if [[ $TARGET == all ]]; then
  grim "$OUT"
elif [[ $TARGET == *" "* ]]; then
  grim -g "$TARGET" "$OUT"
else
  grim -o "${TARGET:-$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')}" "$OUT"
fi
echo "saved: $OUT"
