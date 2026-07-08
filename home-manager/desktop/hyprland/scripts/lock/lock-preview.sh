#!/usr/bin/env bash
# hyprlock の見た目確認用スクリーンショットを撮る開発ツール。
# ロック画面は通常の方法では撮れないため、hyprlock を起動して grim で撮影し
# SIGUSR1（hyprlock の正規解除シグナル）で即解除する。数秒間画面がロックされる。
# 使い方: lock-preview.sh [出力.png] ["x,y WxH"(grim -g 領域)]
set -euo pipefail

OUT="${1:-/tmp/hyprlock-preview.png}"
REGION="${2:-}"

hyprlock >/dev/null 2>&1 &
# grim が失敗しても必ず解除してロックアウトを防ぐ
trap 'pkill -USR1 hyprlock 2>/dev/null || true' EXIT
sleep 4
if [[ -n $REGION ]]; then
  grim -g "$REGION" "$OUT"
else
  grim "$OUT"
fi
echo "saved: $OUT"
