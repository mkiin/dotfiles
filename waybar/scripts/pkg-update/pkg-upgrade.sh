#!/usr/bin/env bash
# Usage: pkg-upgrade.sh <signal_num> <upgrade_cmd...>
#   upgrade コマンドを実行し、waybar に RTMIN+<signal_num> を送って
#   対応する custom module を即時 re-exec させる。
set -u

sig="$1"
shift

"$@"
pkill -RTMIN+"$sig" waybar
echo
read -r -p "press enter to close..." _
