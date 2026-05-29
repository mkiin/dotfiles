#!/usr/bin/env bash
# 独立 keybind: 壁紙ピッカー (icon grid)

THEME="$HOME/.config/rofi/themes/wallpaper.rasi"
WALL_DIR="$HOME/Pictures/wallpaper"
APPLY="$HOME/.config/hypr/scripts/wallpaper/apply.sh"

# 壁紙ファイル一覧 (basename と path をペアで保持)
declare -a paths names
while IFS= read -r p; do
  paths+=("$p")
  names+=("$(basename "$p")")
done < <(fd --max-depth 1 -e jpg -e jpeg -e png -e webp . "$WALL_DIR" 2>/dev/null)

[[ ${#paths[@]} -eq 0 ]] && { notify-send "Wallpaper" "No images in $WALL_DIR"; exit 1; }

# rofi に index を返してもらう (-format i)
idx=$(
  for i in "${!paths[@]}"; do
    printf '%s\x00icon\x1f%s\n' "${names[$i]}" "${paths[$i]}"
  done | rofi -dmenu -theme "$THEME" -p "Wallpaper" -format i
)

[[ -z "$idx" ]] && exit 0  # キャンセル

img="${paths[$idx]}"
[[ -n "$img" && -f "$img" ]] && exec "$APPLY" "$img"
