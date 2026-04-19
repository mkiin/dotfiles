#!/bin/bash
# Wlogout ランチャー: 解像度に応じて中央帯状ピルに配置する。
# - `-b 6` で横1列6ボタンを強制
# - `--margin-top/-bottom` を画面高の30%に設定して中央下に集約

set -e

# 既に起動中なら閉じる（トグル挙動）
if pgrep -x wlogout >/dev/null; then
  pkill -x wlogout
  exit 0
fi

# アクティブモニターの高さ・スケールを取得
MONITOR_JSON=$(hyprctl -j monitors | jq '.[] | select(.focused == true)')
HEIGHT=$(echo "$MONITOR_JSON" | jq -r '.height')
SCALE=$(echo "$MONITOR_JSON" | jq -r '.scale')

# 論理解像度（スケール考慮）に換算した高さ
EFFECTIVE_H=$(awk -v h="$HEIGHT" -v s="$SCALE" 'BEGIN {printf "%d", h / s}')

# 上下マージンを画面高の30%に（中央に帯が集約される）
MARGIN=$((EFFECTIVE_H * 30 / 100))

wlogout -b 6 --margin-top "$MARGIN" --margin-bottom "$MARGIN"
