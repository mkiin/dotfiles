#!/usr/bin/env bash
# AUR 更新を実行 → cache 削除 → waybar に signal 送って即時 re-exec。
# config.jsonc の "custom/aur" の signal=9 と対応。
yay -Sua
rm -f "$XDG_RUNTIME_DIR/waybar/pkg-aur.json"
pkill -RTMIN+9 waybar
echo
read -p "press enter to close..."
