#!/usr/bin/env bash
set -euo pipefail

# pyprland wallpapers の command。transition 系は設定センターから実行時に変えられるよう
# state.env(hyprctl-state) から都度読む。ここを config に持たせると宣言的で固定化するため。
STATE="$HOME/.config/hypr/scripts/hyprctl-state"

img="${1:?usage: set.sh <image>}"

# awww-daemon は systemd で起動直後だと IPC ソケット未 ready のことがある。
# After/Requires はプロセス起動順しか保証しないので、初回 img が失敗しないよう短く待つ。
for _ in $(seq 1 50); do
  awww query >/dev/null 2>&1 && break
  sleep 0.1
done

awww img "$img" \
  --transition-type "$("$STATE" get AWWW_TRANSITION_TYPE)" \
  --transition-fps "$("$STATE" get AWWW_TRANSITION_FPS)" \
  --transition-duration "$("$STATE" get AWWW_TRANSITION_DURATION)" \
  --transition-step "$("$STATE" get AWWW_TRANSITION_STEP)" \
  --transition-bezier "$("$STATE" get AWWW_TRANSITION_BEZIER)"
