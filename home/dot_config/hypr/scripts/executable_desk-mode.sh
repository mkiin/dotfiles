#!/usr/bin/env bash
PREV_WS=$(hyprctl activeworkspace -j 2>/dev/null |
  jq -r 'select(.id > 0) | .id' 2>/dev/null) || PREV_WS=1
[[ "$PREV_WS" =~ ^[0-9]+$ ]] || PREV_WS=1

echo "source = ~/.config/hypr/monitors-desk.conf" >"$HOME/.config/hypr/monitors-active.conf"
hyprctl reload

# hyprctl reload は async。awww-daemon が新 monitor 構成を認識する前に img を打つと取りこぼす
expected=$(hyprctl monitors -j 2>/dev/null | jq 'length')
for _ in {1..10}; do
  (($(awww query 2>/dev/null | wc -l) == expected)) && break
  sleep 0.1
done

# Hyprland はモニター構成変更を layer surface に伝播しないバグがあるため awww と waybar を作り直す。
# `awww restore` は disable 中だったモニターのキャッシュが残ってモード間で壁紙が割れるので last_wallpaper を明示適用する。
LAST="$HOME/.cache/last_wallpaper"
if [[ -f "$LAST" ]] && [[ -r "$(<"$LAST")" ]]; then
  awww img --transition-type none "$(<"$LAST")" >/dev/null 2>&1 || true
else
  awww restore >/dev/null 2>&1 || true
fi
pkill -x waybar 2>/dev/null
uwsm app -- waybar >/dev/null 2>&1 &
disown

hyprctl dispatch workspace "$PREV_WS" >/dev/null 2>&1 || true
