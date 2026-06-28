#!/usr/bin/env bash
# Usage: pkg-check.sh <count_cmd...>
#   コマンドの行数を waybar 用 JSON で返す。
#   waybar の interval と signal で再実行が制御されるため自前 cache は持たない。
set -u

count=$("$@" 2>/dev/null | wc -l)
class=""
(( count > 0 )) && class="has-updates"
printf '{"text":"%s","class":"%s"}\n' "$count" "$class"
