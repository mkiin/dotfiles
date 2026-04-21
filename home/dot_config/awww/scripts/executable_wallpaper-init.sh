#!/usr/bin/env bash
# awww-daemon を起動し、壁紙を初期適用する。
# Hyprland の exec-once から呼ばれる想定。

set -euo pipefail

WALLPAPER="${HOME}/pictures/wallpaper/1297749.jpg"

# 既にデーモンが socket を掴んでいるかは `awww query` の可否で判定する
# （pgrep はプロセス名バリエーションやゾンビで誤判定することがある）
if ! awww query >/dev/null 2>&1; then
    # awww-daemon の stdout/stderr は /dev/null に捨てる (terminal に流れないように)
    awww-daemon >/dev/null 2>&1 &
    disown
    # socket 作成まで最大 5秒待機
    for _ in $(seq 1 50); do
        awww query >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

# トランジションなしで即時適用（起動時の黒→画像フェードは不自然なため）
awww img --transition-type none "$WALLPAPER"
