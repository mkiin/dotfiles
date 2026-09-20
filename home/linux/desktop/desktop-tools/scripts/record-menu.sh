#!/usr/bin/env bash
set -euo pipefail

choice="$(
  printf '%s\n' \
    "Monitor" \
    "Window" \
    "Active Window" \
    "Region" |
    rofi -dmenu -p "Record"
)" || exit 0

case "$choice" in
"Monitor")
  hyprcap rec monitor:active
  ;;
"Window")
  hyprcap rec window
  ;;
"Active Window")
  hyprcap rec window:active
  ;;
"Region")
  hyprcap rec region
  ;;
esac
