#!/usr/bin/env bash
# 独立 keybind: 絵文字ピッカー (rofimoji ラッパ)
# 選択で wl-copy + 自動ペースト (rofimoji default)

THEME="$HOME/.config/rofi/themes/picker.rasi"

exec rofimoji --selector rofi --selector-args="-theme $THEME -p Emoji"
