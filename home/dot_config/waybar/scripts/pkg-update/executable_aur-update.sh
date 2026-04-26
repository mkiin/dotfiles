#!/usr/bin/env bash
# AUR の更新可能パッケージ数 (yay -Qua: query update-able aur)
count=$(yay -Qua 2>/dev/null | wc -l)
printf '%s' "$count"
