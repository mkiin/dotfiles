#!/usr/bin/env bash
# 設定メニュー > WiFi & Ethernet (nmcli ベース)

THEME="$HOME/.config/rofi/themes/dmenu.rasi"

build_items() {
  # Wired
  local wired
  wired=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | grep ':ethernet:' | head -1)
  if [[ -n "$wired" ]]; then
    local dev state
    dev=$(echo "$wired" | cut -d: -f1)
    state=$(echo "$wired" | cut -d: -f3)
    if [[ "$state" == "connected" ]]; then
      local ip
      ip=$(nmcli -t -f IP4.ADDRESS device show "$dev" 2>/dev/null | head -1 | cut -d: -f2 | cut -d/ -f1)
      printf '󰈀  Wired: %s (%s)\n' "$dev" "$ip"
    else
      printf '󰈀  Wired: 未接続\n'
    fi
  fi

  # Wi-Fi toggle
  local radio
  radio=$(nmcli radio wifi 2>/dev/null)
  if [[ "$radio" == "enabled" ]]; then
    printf '󰖩  Wi-Fi: ON\n'
  else
    printf '󰖪  Wi-Fi: OFF\n'
  fi

  # SSID list (only if wifi on)
  if [[ "$radio" == "enabled" ]]; then
    nmcli -t -f IN-USE,SSID,SIGNAL device wifi list 2>/dev/null \
      | awk -F: 'NF>=3 && $2 != "" {
          mark = ($1 == "*") ? "*" : " "
          printf "  %s %s  (%s)\n", mark, $2, $3
        }' \
      | head -10
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
    | rofi -dmenu -theme "$THEME" -p "Network" -l "${#items[@]}" -selected-row "$last_row")
  status=$?

  [[ -z "$choice" ]] && exit 1   # Esc → 全閉じを親に伝播
  [[ $status -eq 10 ]] && exit 0 # Left arrow → Back (1段戻る)

  local row=0 i
  for i in "${!items[@]}"; do
    [[ "${items[$i]}" == "$choice" ]] && row=$i && break
  done

  case "$choice" in
    "← Back")
      exit 0 ;;
    *Wi-Fi:*ON*)
      nmcli radio wifi off 2>/dev/null
      notify-send "Wi-Fi" "OFF"
      show_menu "$row" ;;
    *Wi-Fi:*OFF*)
      nmcli radio wifi on 2>/dev/null
      notify-send "Wi-Fi" "ON"
      show_menu "$row" ;;
    *Wired:*)
      # MVP: 状態表示のみ、選択しても何もしない
      show_menu "$row" ;;
    *)
      # SSID 行: "  * SSID  (signal)" or "    SSID  (signal)"
      local ssid=""
      if [[ "$choice" =~ ^[[:space:]]+[\*[:space:]][[:space:]]+(.+)[[:space:]]+\([0-9]+\)$ ]]; then
        ssid="${BASH_REMATCH[1]}"
      fi

      if [[ -z "$ssid" ]]; then
        show_menu "$row"
      elif nmcli -t -f NAME connection show 2>/dev/null | grep -qx -- "$ssid"; then
        nmcli connection up id "$ssid" 2>/dev/null \
          && notify-send "Wi-Fi" "Connected: $ssid" \
          || notify-send "Wi-Fi" "Failed: $ssid"
        show_menu "$row"
      else
        local password
        password=$(rofi -dmenu -password -theme "$THEME" -p "Password for $ssid")
        if [[ -n "$password" ]]; then
          nmcli device wifi connect "$ssid" password "$password" 2>/dev/null \
            && notify-send "Wi-Fi" "Connected: $ssid" \
            || notify-send "Wi-Fi" "Failed: $ssid"
        fi
        show_menu "$row"
      fi
      ;;
  esac
}

show_menu
