#!/usr/bin/env bash
# AUR の更新可能パッケージ数 (yay -Qua = query update-able aur) を JSON で返す。
count=$(yay -Qua 2>/dev/null | wc -l)
class=""
[ "$count" -gt 0 ] && class="has-updates"
printf '{"text":"%s","class":"%s"}\n' "$count" "$class"
