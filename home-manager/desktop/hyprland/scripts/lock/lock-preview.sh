#!/usr/bin/env bash
# hyprlock を起動して grim で撮影し SIGUSR1 で即解除する（数秒間ロックされる）。
# 使い方: lock-preview.sh [出力.png] ["x,y WxH"]
set -euo pipefail

OUT="${1:-/tmp/hyprlock-preview.png}"
REGION="${2:-}"

hyprlock >/dev/null 2>&1 &
trap 'pkill -USR1 hyprlock 2>/dev/null || true' EXIT
sleep 4
if [[ -n $REGION ]]; then
  grim -g "$REGION" "$OUT"
else
  grim "$OUT"
fi
echo "saved: $OUT"
