#!/usr/bin/env bash
set -euo pipefail

# すでに開いていれば閉じる（Super+A / アイコンクリックの toggle 挙動）
if pgrep -x rofi >/dev/null; then
  pkill -x rofi || true
  exit 0
fi

theme="$HOME/.config/rofi/themes/app-launcher.rasi"
wp="$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/hypr/last_wallpaper" 2>/dev/null || true)"

# 現壁紙が読めるときだけ inputbar 背景に注入する（webp 等でデコード不可でも一覧は出す）
if [[ -n $wp && -f $wp ]]; then
  exec rofi -show drun -theme "$theme" \
    -theme-str "inputbar { background-image: url(\"$wp\", width); }"
fi
exec rofi -show drun -theme "$theme"
