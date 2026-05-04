#!/usr/bin/env bash
# 設定メニュー本体 (索引)

THEME="$HOME/.config/rofi/themes/dmenu.rasi"
SCRIPTS="$HOME/.config/rofi/scripts"

show_menu() {
  local last_row="${1:-0}"
  local items=(
    "󰖩  WiFi & Ethernet"
    "󰕾  Audio Select"
    "󰂯  BT Settings"
    "󰸉  Wallpaper"
  )

  local choice status
  choice=$(printf '%s\n' "${items[@]}" \
    | rofi -dmenu -theme "$THEME" -p "Settings" -l "${#items[@]}" -selected-row "$last_row")
  status=$?

  [[ -z "$choice" ]] && exit 0   # Esc → 単純終了 (上位なし)
  [[ $status -eq 10 ]] && exit 0 # Left arrow → 同上

  local row=0 i
  for i in "${!items[@]}"; do
    [[ "${items[$i]}" == "$choice" ]] && row=$i && break
  done

  local script
  case "$choice" in
    *WiFi*)      script="rofi-network.sh" ;;
    *Audio*)     script="rofi-audio.sh" ;;
    *BT*)        script="rofi-bluetooth.sh" ;;
    *Wallpaper*) script="rofi-wallpaper-settings.sh" ;;
    *) show_menu "$row"; return ;;
  esac

  bash "$SCRIPTS/$script"
  local child=$?

  [[ $child -ne 0 ]] && exit 0  # 子が Esc で抜けた → 全閉じ
  show_menu "$row"
}

show_menu
