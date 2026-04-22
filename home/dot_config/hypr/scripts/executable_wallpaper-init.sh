#!/usr/bin/env bash
# awww-daemon を起動し、前回の壁紙を復元する。
# Hyprland の exec-once から呼ばれる想定。
#
# state 管理は awww 組み込みの cache (~/.cache/awww/<version>/<output>) に委譲。
# wallpaper.sh (keybind) が壁紙変更時に自動更新するので、init 側は読み出すだけ。

set -euo pipefail

FALLBACK="${HOME}/pictures/wallpaper/1297749.jpg"

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

# 前回の壁紙を復元 (モニター別 cache から自動選択)。
# cache 未生成 (初回起動 or clear-cache 後) は fallback 画像を適用。
if ! awww restore 2>/dev/null; then
    if [ -f "$FALLBACK" ]; then
        awww img --transition-type none "$FALLBACK"
    else
        echo "[wallpaper-init] no restore cache and fallback missing: $FALLBACK" >&2
        exit 1
    fi
fi
