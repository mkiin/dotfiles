#!/usr/bin/env bash
set -euo pipefail

# 開いていれば閉じる（waybar アイコン再クリック / Super+A の toggle）
if pkill -x rofi 2>/dev/null; then
  exit 0
fi

theme="$HOME/.config/rofi/themes/app-launcher.rasi"
wp="$(awww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -n1 || true)"

# 現壁紙が読めるときだけ imagebox 背景に注入する（webp 等でデコード不可でも一覧は出す）
if [[ -n $wp && -f $wp ]]; then
  exec rofi -show drun -theme "$theme" \
    -theme-str "imagebox { background-image: url(\"$wp\", height); }"
fi
exec rofi -show drun -theme "$theme"
