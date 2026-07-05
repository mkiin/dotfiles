#!/usr/bin/env bash
# hyprlock の時刻/日付ラベル用 Pango マークアップを出力する。
# 色は hyprlock.conf 側で $lock_* トークン（rgba(rrggbbaa)）が展開され引数で渡る。
# 使い方:
#   lock-clock.sh time <hour> <colon> <minute> <ampm>
#   lock-clock.sh date <month> <day> <weekday>
# <...> は rgba(rrggbbaa) 形式。
set -euo pipefail
export LC_ALL=C

esc() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# $1=rgba(rrggbbaa), $2=追加属性 → <span ...> 開きタグ
span_open() {
  local v="${1#rgba(}"
  v="${v%)}"
  local hex="#${v:0:6}"
  local a=$((16#${v:6:2}))
  local attrs="foreground='$hex'"
  if [ "$a" -lt 255 ]; then
    attrs="$attrs fgalpha='$(((a * 100 + 127) / 255))%'"
  fi
  printf "<span %s %s>" "$attrs" "$2"
}

mode="$1"
case "$mode" in
time)
  h="$(esc "$(date +%-I)")"
  m="$(esc "$(date +%M)")"
  p="$(esc "$(date +%p)")"
  printf '%s%s</span>' "$(span_open "$2" "font_weight='800'")" "$h"
  printf '%s%s</span>' "$(span_open "$3" "font_weight='800'")" ':'
  printf '%s%s</span>' "$(span_open "$4" "font_weight='800'")" "$m"
  printf '%s %s</span>\n' "$(span_open "$5" "font_weight='medium' size='18432' rise='40960'")" "$p"
  ;;
date)
  mo="$(esc "$(date +%B | tr '[:lower:]' '[:upper:]')")"
  d="$(esc "$(date +%d)")"
  wd="$(esc "$(date +%A)")"
  printf '%s%s</span>\n' "$(span_open "$2" "letter_spacing='4096' font_weight='bold'")" "$mo"
  printf '%s%s</span>\n' "$(span_open "$3" "letter_spacing='2048' font_weight='medium' size='26624'")" "$d"
  printf '%s%s</span>\n' "$(span_open "$4" "letter_spacing='2048'")" "$wd"
  ;;
*)
  echo "usage: lock-clock.sh {time|date} <colors...>" >&2
  exit 1
  ;;
esac
