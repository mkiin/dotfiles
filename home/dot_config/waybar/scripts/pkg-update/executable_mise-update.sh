#!/usr/bin/env bash
# mise tool の outdated 件数 (mise outdated はヘッダ無しで 1 行 = 1 ツール)
count=$(mise outdated 2>/dev/null | wc -l)
printf '%s' "$count"
