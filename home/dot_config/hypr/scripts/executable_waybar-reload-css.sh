#!/usr/bin/env bash
# waybar の reload_style_on_change を発火させるため style.css 自体を O_TRUNC + write で書き直す。
# touch では IN_ATTRIB 止まりで反応せず、SIGUSR2 では surface 再生成でタイル window が再レイアウトされる。
set -euo pipefail

f="${HOME}/.config/waybar/style.css"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cp "$f" "$tmp"
cat "$tmp" >"$f"
