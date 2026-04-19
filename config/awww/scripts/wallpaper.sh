#!/usr/bin/env bash
# 壁紙切替 CLI。
#   wallpaper.sh <image>         画像パスに切替
#   wallpaper.sh random <dir>    ディレクトリからランダム1枚
#
# トランジションは awww 公式 env var で制御可能 (man awww-img):
#   AWWW_TRANSITION (default simple)
#   AWWW_TRANSITION_FPS (default 30)
#   AWWW_TRANSITION_STEP (default 90 / simple=2)
#   AWWW_TRANSITION_DURATION (default 3)

set -euo pipefail

if [ "${1:-}" = "random" ]; then
    dir="${2:?usage: wallpaper.sh random <dir>}"
    img=$(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n 1)
    [ -n "$img" ] || { echo "no image in $dir" >&2; exit 1; }
    awww img "$img"
else
    img="${1:?usage: wallpaper.sh <image>|random <dir>}"
    awww img "$img"
fi
