#!/bin/bash
# 札幌の天気を Open-Meteo API で取得し、Waybar 用 JSON を出力する。
# 依存: curl, jq

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ICONS_FILE="${SCRIPT_DIR}/weather_icons.json"

# 札幌の緯度経度
LAT=43.0642
LON=141.3469

API_URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m&timezone=Asia%2FTokyo"

DATA=$(curl -sf --max-time 10 "${API_URL}" 2>/dev/null) || {
  echo '{"text": "⚠️", "tooltip": "天気取得失敗", "class": "error"}'
  exit 0
}

CODE=$(echo "${DATA}" | jq -r '.current.weather_code')
TEMP=$(echo "${DATA}" | jq -r '.current.temperature_2m')
FEELS=$(echo "${DATA}" | jq -r '.current.apparent_temperature')
HUMIDITY=$(echo "${DATA}" | jq -r '.current.relative_humidity_2m')
WIND=$(echo "${DATA}" | jq -r '.current.wind_speed_10m')
IS_DAY=$(echo "${DATA}" | jq -r '.current.is_day')

# weather_icons.json から該当エントリを取得
ENTRY=$(jq --argjson code "${CODE}" '.[] | select(.code == $code)' "${ICONS_FILE}")

if [ -z "${ENTRY}" ]; then
  ICON="❓"
  DESC="Unknown (code: ${CODE})"
else
  if [ "${IS_DAY}" = "1" ]; then
    ICON=$(echo "${ENTRY}" | jq -r '."icon-emoji"')
    DESC=$(echo "${ENTRY}" | jq -r '.day')
  else
    ICON=$(echo "${ENTRY}" | jq -r '."icon-emoji-night"')
    DESC=$(echo "${ENTRY}" | jq -r '.night')
  fi
fi

TEMP_INT=$(printf "%.0f" "${TEMP}")
FEELS_INT=$(printf "%.0f" "${FEELS}")

TEXT="${ICON} ${TEMP_INT}°C"
TOOLTIP=$(printf '札幌\n%s\n気温: %s°C (体感 %s°C)\n湿度: %s%%\n風速: %s km/h' \
    "${DESC}" "${TEMP_INT}" "${FEELS_INT}" "${HUMIDITY}" "${WIND}")

jq -nc --arg text "${TEXT}" --arg tooltip "${TOOLTIP}" '{text: $text, tooltip: $tooltip}'
