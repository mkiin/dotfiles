#!/usr/bin/env bash
# AUR の更新可能パッケージ数 (yay -Qua = query update-able aur) を JSON で返す。
# モニター毎の独立 fetch でズレるのを防ぐため TTL 付きキャッシュを共有する。
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
cache_file="$cache_dir/pkg-aur.json"
ttl=1500

mkdir -p "$cache_dir"

if [ -f "$cache_file" ] && [ "$(( $(date +%s) - $(stat -c %Y "$cache_file") ))" -lt "$ttl" ]; then
    cat "$cache_file"
    exit 0
fi

count=$(yay -Qua 2>/dev/null | wc -l)
class=""
[ "$count" -gt 0 ] && class="has-updates"
printf '{"text":"%s","class":"%s"}\n' "$count" "$class" | tee "$cache_file"
