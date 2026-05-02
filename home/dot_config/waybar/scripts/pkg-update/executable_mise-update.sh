#!/usr/bin/env bash
# mise tool の outdated 件数を JSON で返す (mise outdated はヘッダ無しで 1 行 = 1 ツール)。
# キャッシュは $XDG_RUNTIME_DIR に置く: 起動時に空 = fresh fetch、セッション内は共有 = マルチモニター値が揃う。
cache_dir="$XDG_RUNTIME_DIR/waybar"
cache_file="$cache_dir/pkg-mise.json"
ttl=1500

mkdir -p "$cache_dir"

if [ -f "$cache_file" ] && [ "$(( $(date +%s) - $(stat -c %Y "$cache_file") ))" -lt "$ttl" ]; then
    cat "$cache_file"
    exit 0
fi

count=$(mise outdated 2>/dev/null | wc -l)
class=""
[ "$count" -gt 0 ] && class="has-updates"
printf '{"text":"%s","class":"%s"}\n' "$count" "$class" | tee "$cache_file"
