#!/usr/bin/env bash
# 壁紙切替 API (単一責任、連鎖を全部ここで持つ)
#   wallpaper.sh <image>         画像パスに切替
#   wallpaper.sh random <dir>    ディレクトリからランダム1枚
#
# 連鎖: awww img (transition=grow) → matugen image → hyprctl reload
# waybar は matugen の post_hook (waybar-reload-css.sh) で style.css を in-place rewrite、
# reload_style_on_change 経由で CSS だけ再読させる。surface 維持なのでタイル window が
# ガクつかない (SIGUSR2 は Client::reset() で surface 再生成するためガクつく)。
# matugen / hyprctl が失敗しても壁紙変更自体は成功扱いで継続。

set -euo pipefail

if [ "${1:-}" = "random" ]; then
    dir="${2:?usage: wallpaper.sh random <dir>}"
    img=$(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n 1)
    [ -n "$img" ] || { echo "no image in $dir" >&2; exit 1; }
else
    img="${1:?usage: wallpaper.sh <image>|random <dir>}"
fi

awww img "$img" --transition-type grow
# --source-color-index 0: matugen 4.0.0 以降 `image` は上位 5 色から対話選択する UI が
# デフォルト有効化されており、TTY 無しの呼び出し (walker activate, hyprland exec 等) で
# dialoguer が `not a terminal` を返して失敗する。index 0 (最頻色) 固定で対話回避。
matugen image "$img" --source-color-index 0 || echo "[wallpaper.sh] matugen failed" >&2
hyprctl reload || echo "[wallpaper.sh] hyprctl reload failed" >&2
