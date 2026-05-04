#!/usr/bin/env bash
# 独立 keybind: クリップボード履歴 (cliphist ベース)
# 選択 → wl-copy で復元、再ペーストはユーザーが Ctrl+V で行う
# Shift+Enter (kb-custom-1, exit code 10) で選択エントリ削除

THEME="$HOME/.config/rofi/themes/picker.rasi"

choice=$(cliphist list \
  | rofi -dmenu -theme "$THEME" -p "Clipboard" \
         -kb-custom-1 "Alt+d" -mesg "Enter: copy / Alt+d: delete entry")
status=$?

[[ -z "$choice" ]] && exit 0

if [[ $status -eq 10 ]]; then
  printf '%s' "$choice" | cliphist delete
  notify-send "Clipboard" "Entry deleted"
else
  printf '%s' "$choice" | cliphist decode | wl-copy
fi
