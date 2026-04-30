#!/usr/bin/env bash
# mise tool の outdated 件数を JSON で返す (mise outdated はヘッダ無しで 1 行 = 1 ツール)。
count=$(mise outdated 2>/dev/null | wc -l)
class=""
[ "$count" -gt 0 ] && class="has-updates"
printf '{"text":"%s","class":"%s"}\n' "$count" "$class"
