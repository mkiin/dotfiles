#!/usr/bin/env bash
# pacman 公式リポの更新可能パッケージ数を JSON で返す。
# checkupdates (pacman-contrib) は sudo 不要、別 DB に sync して既存 DB に影響しない。
# count > 0 のとき class=has-updates を吐く → CSS 側で色を切替。
# キャッシュは $XDG_RUNTIME_DIR に置く: 起動時に空 = fresh fetch、セッション内は共有 = マルチモニター値が揃う。
cache_dir="$XDG_RUNTIME_DIR/waybar"
cache_file="$cache_dir/pkg-pacman.json"
ttl=1500

mkdir -p "$cache_dir"

if [ -f "$cache_file" ] && [ "$(( $(date +%s) - $(stat -c %Y "$cache_file") ))" -lt "$ttl" ]; then
    cat "$cache_file"
    exit 0
fi

count=$(checkupdates 2>/dev/null | wc -l)
class=""
[ "$count" -gt 0 ] && class="has-updates"
printf '{"text":"%s","class":"%s"}\n' "$count" "$class" | tee "$cache_file"
