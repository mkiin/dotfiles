#!/usr/bin/env bash
# 設定メニュー > Wallpaper サブ (壁紙/matugen トグル)

THEME="$HOME/.config/rofi/themes/dmenu.rasi"
STATE="$HOME/.config/hypr/scripts/hyprctl-state"

fmt_bool() {
  [[ "$1" == "true" ]] && echo "[ON] " || echo "[OFF]"
}

fmt_interval() {
  case "$1" in
    300)   echo " 5m " ;;
    900)   echo "15m " ;;
    1800)  echo "30m " ;;
    3600)  echo " 1h " ;;
    10800) echo " 3h " ;;
    *)     printf '%ss' "$1" ;;
  esac
}

build_items() {
  local notify rotation interval src_idx random
  notify=$("$STATE" get WALLPAPER_NOTIFY)
  rotation=$("$STATE" get WALLPAPER_ROTATION)
  interval=$("$STATE" get WALLPAPER_INTERVAL_SEC)
  src_idx=$("$STATE" get MATUGEN_SOURCE_INDEX)
  random=$("$STATE" get MATUGEN_RANDOM_INDEX)

  printf '%s  壁紙切替時の通知\n'         "$(fmt_bool "$notify")"
  printf '%s  壁紙ローテーション\n'       "$(fmt_bool "$rotation")"
  printf '%s  ローテーション間隔\n'       "$(fmt_interval "$interval")"
  printf '#%s    matugen ソース color index\n' "$src_idx"
  printf '%s  matugen index ランダム\n'   "$(fmt_bool "$random")"
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
    | rofi -dmenu -theme "$THEME" -p "Wallpaper" -l "${#items[@]}" -selected-row "$last_row")
  status=$?

  [[ -z "$choice" ]] && exit 1
  [[ $status -eq 10 ]] && exit 0 # Left arrow → Back

  local row=0 i
  for i in "${!items[@]}"; do
    [[ "${items[$i]}" == "$choice" ]] && row=$i && break
  done

  case "$choice" in
    "← Back") exit 0 ;;
    *壁紙切替時の通知*)         "$STATE" toggle WALLPAPER_NOTIFY ;;
    *壁紙ローテーション*)       "$STATE" toggle WALLPAPER_ROTATION ;;
    *ローテーション間隔*)
      "$STATE" cycle WALLPAPER_INTERVAL_SEC 300 900 1800 3600 10800
      pkill -USR1 -f wallpaper/rotate.sh 2>/dev/null || true
      ;;
    *matugen\ ソース*)          "$STATE" cycle MATUGEN_SOURCE_INDEX 0 1 ;;
    *matugen\ index\ ランダム*) "$STATE" toggle MATUGEN_RANDOM_INDEX ;;
  esac
  show_menu "$row"
}

show_menu
