#!/usr/bin/env bash
# 設定メニュー > BT Settings (bluetoothctl ベース)

THEME="$HOME/.config/rofi/themes/dmenu.rasi"

build_items() {
  local powered=0
  if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    printf '󰂯  BT: ON\n'
    powered=1
  else
    printf '󰂲  BT: OFF\n'
  fi

  if (( powered )); then
    while IFS= read -r line; do
      [[ "$line" =~ ^Device[[:space:]]+([0-9A-F:]+)[[:space:]]+(.+)$ ]] || continue
      local mac="${BASH_REMATCH[1]}"
      local name="${BASH_REMATCH[2]}"
      local marker=" "
      if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
        marker="✓"
      fi
      printf '%s  %s\t%s\n' "$marker" "$name" "$mac"
    done < <(bluetoothctl devices Paired 2>/dev/null)
  fi

  printf '← Back\n'
}

show_menu() {
  local last_row="${1:-0}"

  local items=()
  while IFS= read -r line; do
    items+=("$line")
  done < <(build_items)

  local choice status
  choice=$(printf '%s\n' "${items[@]}" \
    | rofi -dmenu -theme "$THEME" -p "Bluetooth" -l "${#items[@]}" -selected-row "$last_row")
  status=$?

  [[ -z "$choice" ]] && exit 1
  [[ $status -eq 10 ]] && exit 0 # Left arrow → Back

  local row=0 i
  for i in "${!items[@]}"; do
    [[ "${items[$i]}" == "$choice" ]] && row=$i && break
  done

  case "$choice" in
    "← Back") exit 0 ;;
    *BT:*ON*)
      bluetoothctl power off 2>/dev/null
      notify-send "Bluetooth" "OFF"
      show_menu "$row" ;;
    *BT:*OFF*)
      bluetoothctl power on 2>/dev/null
      notify-send "Bluetooth" "ON"
      show_menu "$row" ;;
    *)
      # device: "✓  Name<TAB>MAC" or "   Name<TAB>MAC"
      local mac="${choice##*$'\t'}"
      if [[ "$mac" =~ ^[0-9A-F:]+$ ]]; then
        if [[ "$choice" == "✓"* ]]; then
          bluetoothctl disconnect "$mac" 2>/dev/null \
            && notify-send "Bluetooth" "Disconnected" \
            || notify-send "Bluetooth" "Failed"
        else
          bluetoothctl connect "$mac" 2>/dev/null \
            && notify-send "Bluetooth" "Connected" \
            || notify-send "Bluetooth" "Failed"
        fi
      fi
      show_menu "$row" ;;
  esac
}

show_menu
