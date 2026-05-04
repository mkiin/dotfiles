#!/usr/bin/env bash
# 設定メニュー > Audio Select (wpctl ベース)

THEME="$HOME/.config/rofi/themes/dmenu.rasi"

build_items() {
  wpctl status | awk '
    /Sinks:/ { in_sinks=1; next }
    /Sources:/ || /Filters:/ { in_sinks=0 }
    in_sinks && /\[vol:/ {
      gsub(/^[ │]+/, "")
      active = " "
      if (/^\*/) { active = "✓"; sub(/^\*[ \t]*/, "") }
      else { sub(/^[ \t]*/, "") }
      if (match($0, /^[0-9]+\./)) {
        id = substr($0, RSTART, RLENGTH-1)
        rest = substr($0, RSTART + RLENGTH)
        sub(/[ \t]*\[vol:.*$/, "", rest)
        gsub(/[ \t]+$/, "", rest)
        gsub(/^[ \t]+/, "", rest)
        printf "%s  %s\t#%s\n", active, rest, id
      }
    }
  '
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
    | rofi -dmenu -theme "$THEME" -p "Audio" -l "${#items[@]}" -selected-row "$last_row")
  status=$?

  [[ -z "$choice" ]] && exit 1
  [[ $status -eq 10 ]] && exit 0 # Left arrow → Back

  local row=0 i
  for i in "${!items[@]}"; do
    [[ "${items[$i]}" == "$choice" ]] && row=$i && break
  done

  case "$choice" in
    "← Back") exit 0 ;;
    *)
      # ID は "#NNN" 末尾に格納
      local id="${choice##*#}"
      if [[ "$id" =~ ^[0-9]+$ ]]; then
        wpctl set-default "$id" 2>/dev/null \
          && notify-send "Audio" "Default sink switched" \
          || notify-send "Audio" "Failed to switch"
      fi
      show_menu "$row"
      ;;
  esac
}

show_menu
