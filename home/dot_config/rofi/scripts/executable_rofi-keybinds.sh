#!/usr/bin/env bash
# 独立 keybind: キーバインド早見表 (keybinds.conf から自動生成、閲覧のみ)

CONF="$HOME/.config/hypr/keybinds.conf"
THEME="$HOME/.config/rofi/themes/picker.rasi"

# bind/binde/bindel/bindl/bindm/bindn を統一処理
rg -N '^bind' "$CONF" | sed -E 's/^bind[a-z]* = //' | awk -F',' '{
  mods = $1; key = $2; disp = $3
  args = ""
  for (i = 4; i <= NF; i++) args = args (i > 4 ? "," : "") $i
  gsub(/^ +| +$/, "", mods); gsub(/^ +| +$/, "", key)
  gsub(/^ +| +$/, "", disp); gsub(/^ +| +$/, "", args)
  gsub(/\$mainMod/, "Super", mods)
  gsub(/ +/, "+", mods)
  combo = (mods == "" ? key : mods "+" key)
  printf "%-30s %s\n", combo, disp (args == "" ? "" : " " args)
}' | rofi -dmenu -theme "$THEME" -p "Keybinds" > /dev/null
