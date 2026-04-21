#!/bin/bash
# Wlogout ランチャー: 解像度に応じて中央帯状ピルに配置する。
# - `-b 6` で横1列6ボタンを強制
# - `--margin-top/-bottom` を画面高の30%に設定して中央下に集約
# - ワークスペース切替イベントを監視し、切替時は自動で閉じる
# - 起動中に再度呼ばれたらトグルで閉じる

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

# Hyprland のイベントソケットを監視して、ワークスペース切替時に wlogout を閉じる
HYPR_SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
if [ -S "$HYPR_SOCK" ] && command -v socat >/dev/null 2>&1; then
  (
    socat -U - "UNIX-CONNECT:${HYPR_SOCK}" 2>/dev/null | while read -r event; do
      case "$event" in
        workspace*|focusedmon*)
          pkill -x wlogout
          exit 0
          ;;
      esac
    done
  ) &
  LISTENER_PID=$!
fi

# wlogout を起動（ブロッキング）
wlogout -b 6 --margin-top "$MARGIN" --margin-bottom "$MARGIN"

# リスナを後始末
if [ -n "${LISTENER_PID:-}" ]; then
  kill "$LISTENER_PID" 2>/dev/null || true
fi
