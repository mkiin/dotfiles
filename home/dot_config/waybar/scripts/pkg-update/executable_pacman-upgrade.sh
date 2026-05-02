#!/usr/bin/env bash
# pacman 更新を実行 → cache 削除 → waybar に signal 送って即時 re-exec。
# config.jsonc の "custom/pacman" の signal=8 と対応。
sudo pacman -Syu
rm -f "$XDG_RUNTIME_DIR/waybar/pkg-pacman.json"
pkill -RTMIN+8 waybar
echo
read -p "press enter to close..."
