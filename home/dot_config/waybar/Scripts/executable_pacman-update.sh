#!/usr/bin/env bash
# pacman 公式リポの更新可能パッケージ数を出力。
# checkupdates (pacman-contrib) は sudo 不要、別 DB に sync して既存 DB に影響しない。
# 0 件のとき空文字を返してモジュールを隠せるよう、format-icons / format で制御する側に
# テキストだけ渡す方針。waybar 側の format で `{} のときに class.empty` を検知できる。
count=$(checkupdates 2>/dev/null | wc -l)
printf '%s' "$count"
