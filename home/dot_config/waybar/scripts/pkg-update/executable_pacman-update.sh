#!/usr/bin/env bash
# pacman 公式リポの更新可能パッケージ数を JSON で返す。
# checkupdates (pacman-contrib) は sudo 不要、別 DB に sync して既存 DB に影響しない。
# count > 0 のとき class=has-updates を吐く → CSS 側で色を切替。
count=$(checkupdates 2>/dev/null | wc -l)
class=""
[ "$count" -gt 0 ] && class="has-updates"
printf '{"text":"%s","class":"%s"}\n' "$count" "$class"
