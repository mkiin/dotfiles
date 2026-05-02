#!/usr/bin/env bash
# mise tool 更新を実行 → cache 削除 → waybar に signal 送って即時 re-exec。
# config.jsonc の "custom/mise" の signal=10 と対応。
mise upgrade
rm -f "$XDG_RUNTIME_DIR/waybar/pkg-mise.json"
pkill -RTMIN+10 waybar
echo
read -p "press enter to close..."
