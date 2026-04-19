#!/usr/bin/env bash
# waybar CSS-only reload (surface 維持、タイル window がガクつかない)
#
# matugen post_hook から呼ばれる想定。style.css を in-place truncate+rewrite すると
# GIO FileMonitor が CHANGES_DONE_HINT を発火し、waybar が Client::reset() せずに
# CssProvider だけ reload する。SIGUSR2 (surface destroy → 再生成 → exclusive_zone
# 一瞬消失で全タイル window 再レイアウト) より圧倒的に滑らか。
#
# 注意: @import 先 (colors.css) の変更は reload_style_on_change に拾われないので、
#       style.css 自体を書き直すことでリロードの発火点を作る。inode は保持される
#       (O_TRUNC での write なので)。touch (mtime のみ更新) では IN_ATTRIB 止まりで
#       CHANGES_DONE_HINT にならないため不可。

set -euo pipefail

f="${HOME}/.config/waybar/style.css"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cp "$f" "$tmp"
cat "$tmp" > "$f"
