#!/usr/bin/env bash
# 札幌 (石狩地方) の天気を気象庁 (JMA) API で取得し Waybar 用 JSON を出力する。
# 依存: curl, jq
#
# エンドポイント:
#   forecast:  /bosai/forecast/data/forecast/<region>.json    今日明日明後日 + 週間
#   amedas:    /bosai/amedas/data/point/<station>/<datehour>.json   現在観測値
#   amedas latest_time.txt                                     最新観測時刻
#
# 領域コード:
#   016000   = 北海道 石狩・空知・後志 (forecast の region)
#   016010   = 石狩地方 (天気コード/天気文の area キー)
#   14163    = 札幌 (気温の forecast area キー、amedas station ID と同じ)

set -e

REGION="016000"
SUB_AREA="016010"
SAPPORO_ID="14163"
LABEL="札幌"

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
ICON_MAP="${SCRIPT_DIR}/weather-icon.json"

FORECAST_URL="https://www.jma.go.jp/bosai/forecast/data/forecast/${REGION}.json"
AMEDAS_LATEST_URL="https://www.jma.go.jp/bosai/amedas/data/latest_time.txt"

DATA=$(curl -sf --max-time 10 "$FORECAST_URL") || {
  echo '{"text": "⚠️", "tooltip": "JMA forecast 取得失敗", "class": "error"}'
  exit 0
}

# 石狩地方の天気 (今日と明日)。weathers の中の全角スペース (JMA の単語区切り仕様)
# は読みづらいので除去する。
TODAY_CODE=$(jq -r --arg c "$SUB_AREA" '.[0].timeSeries[0].areas[] | select(.area.code == $c) | .weatherCodes[0] // ""' <<<"$DATA")
TODAY_DESC=$(jq -r --arg c "$SUB_AREA" '.[0].timeSeries[0].areas[] | select(.area.code == $c) | (.weathers[0] // "") | gsub("　"; "")' <<<"$DATA")
TOMORROW_DESC=$(jq -r --arg c "$SUB_AREA" '.[0].timeSeries[0].areas[] | select(.area.code == $c) | (.weathers[1] // "") | gsub("　"; "")' <<<"$DATA")

# 札幌の予報気温 (timeSeries[2])。temps は
#   [today_9am, today_0am, tomorrow_0am, tomorrow_9am] の順。
TEMPS=$(jq -r --arg c "$SAPPORO_ID" '
    .[0].timeSeries[2].areas[] | select(.area.code == $c) | .temps | @tsv
' <<<"$DATA")
TOMORROW_LOW=$(awk '{print $3}' <<<"$TEMPS")
TOMORROW_HIGH=$(awk '{print $4}' <<<"$TEMPS")

# 現在の観測値を amedas から取る (失敗しても致命的ではないので fallback)。
NOW_TEMP=""
NOW_HUMIDITY=""
NOW_WIND=""
LATEST=$(curl -sf --max-time 5 "$AMEDAS_LATEST_URL" 2>/dev/null || true)
if [[ -n "$LATEST" ]]; then
  # amedas point ファイルは 3 時間ブロック単位 (00/03/06/09/12/15/18/21)。
  # 観測時刻の hour を 3 で切り捨てて block hour に丸める (10# で 8 進数解釈回避)。
  HOUR=$(date -d "$LATEST" +%H 2>/dev/null || true)
  DATE_PART=$(date -d "$LATEST" +%Y%m%d 2>/dev/null || true)
  if [[ -n "$HOUR" && -n "$DATE_PART" ]]; then
    BLOCK_HOUR=$(printf "%02d" $((10#$HOUR / 3 * 3)))
    DATE_HOUR="${DATE_PART}_${BLOCK_HOUR}"
    AMEDAS_URL="https://www.jma.go.jp/bosai/amedas/data/point/${SAPPORO_ID}/${DATE_HOUR}.json"
    AMEDAS=$(curl -sf --max-time 5 "$AMEDAS_URL" 2>/dev/null || true)
    if [[ -n "$AMEDAS" ]]; then
      # 最新エントリ (key の昇順最後) から値を取り出す。値は [value, quality_flag]。
      NOW_TEMP=$(jq -r 'to_entries | last | .value.temp[0] // empty' <<<"$AMEDAS")
      NOW_HUMIDITY=$(jq -r 'to_entries | last | .value.humidity[0] // empty' <<<"$AMEDAS")
      NOW_WIND=$(jq -r 'to_entries | last | .value.wind[0] // empty' <<<"$AMEDAS")
    fi
  fi
fi

# 天気コード→アイコン: weather-icon.json (118 コード × Nerd Font weather glyph) を引く。
# 現在時刻 6:00-17:59 を昼、それ以外を夜と判定して icon_day / icon_night を切替。
# weather-icon.json は JMA telops.json と同期して 118 全コードを網羅しているので、
# JSON 読込/lookup が両方成功すれば必ず glyph が返る。失敗時のみ alert glyph を出す。
NOW_HOUR=$(date +%H)
if ((10#$NOW_HOUR >= 6 && 10#$NOW_HOUR < 18)); then
  ICON_FIELD="icon_day"
else
  ICON_FIELD="icon_night"
fi
ICON=$(jq -r --arg c "$TODAY_CODE" --arg f "$ICON_FIELD" \
  '.[$c][$f] // ""' "$ICON_MAP" 2>/dev/null || true)
[[ -z "$ICON" ]] && ICON="󱍡" # md-weather-cloudy-alert (JSON 欠損 / 新規コード時の fallback)

# bar 表示用の温度。amedas が取れていればそちら、無ければ予報値の今日 9 時。
DISPLAY_TEMP="$NOW_TEMP"
if [[ -z "$DISPLAY_TEMP" ]]; then
  DISPLAY_TEMP=$(awk '{print $1}' <<<"$TEMPS")
fi
# icon を下方向に微調整 (nf-weather-* は baseline より高めに描画される傾向)。
# pango rise / letter_spacing の単位は 1024ths of a point。
#   rise: 負値=下げる、正値=上げる
#   letter_spacing: 負値=詰める、正値=広げる (icon と温度の隙間調整)
# icon と温度の間は U+2003 (em space, 1em 幅) で固定。半角スペース 1 個では狭く、
# letter_spacing は pt 単位なので 14px font だと響きが弱い。
TEXT="${ICON} ${DISPLAY_TEMP:-?}°C"

# tooltip 構築
TOOLTIP="${LABEL}\n今日: ${TODAY_DESC:-?}"
if [[ -n "$NOW_TEMP" ]]; then
  TOOLTIP="${TOOLTIP}\n気温: ${NOW_TEMP}°C"
  [[ -n "$NOW_HUMIDITY" ]] && TOOLTIP="${TOOLTIP}\n湿度: ${NOW_HUMIDITY}%"
  [[ -n "$NOW_WIND" ]] && TOOLTIP="${TOOLTIP}\n風速: ${NOW_WIND} m/s"
fi
TOOLTIP="${TOOLTIP}\n明日: ${TOMORROW_DESC:-?} (${TOMORROW_LOW:-?}°C / ${TOMORROW_HIGH:-?}°C)"

jq -nc --arg text "$TEXT" --arg tooltip "$(printf '%b' "$TOOLTIP")" \
  '{text: $text, tooltip: $tooltip}'
