#!/usr/bin/env bash
# hyprlock の時刻/日付ラベル用 Pango マークアップを出力する。
set -euo pipefail
export LC_ALL=C

d() {
  if [ -n "${LOCK_CLOCK_AT:-}" ]; then
    date -d "$LOCK_CLOCK_AT" "$@"
  else
    date "$@"
  fi
}

esc() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

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
  printf '%s%s</span>' "$(span_open "$2" "")" "$(esc "$(d +%I)")"
  printf '%s%s</span>' "$(span_open "$3" "")" "$(esc ":$(d +%M)")"
  printf '%s %s</span>\n' "$(span_open "$4" "size='28672' rise='45000'")" \
    "$(esc "$(d +%p)")"
  ;;
date)
  printf '%s%s</span>' "$(span_open "$2" "")" \
    "$(esc "$(d +%a | tr '[:lower:]' '[:upper:]')")"
  printf '%s%s</span>\n' "$(span_open "$3" "")" \
    "$(esc " · $(d '+%b %d' | tr '[:lower:]' '[:upper:]')")"
  ;;
*)
  echo "usage: lock-clock.sh {time|date} <colors...>" >&2
  exit 1
  ;;
esac
