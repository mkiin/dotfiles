#!/usr/bin/env bash
set -euo pipefail

if pkill -x rofi 2>/dev/null; then
  exit 0
fi

theme="$HOME/.config/rofi/themes/app-launcher.rasi"
wp="$(awww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -n1 || true)"

if [[ -n $wp && -f $wp ]]; then
  exec rofi -show drun -theme "$theme" \
    -theme-str "imagebox { background-image: url(\"$wp\", height); }"
fi
exec rofi -show drun -theme "$theme"
