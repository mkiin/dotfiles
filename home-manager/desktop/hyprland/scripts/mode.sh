#!/usr/bin/env bash
mode="${1:?usage: mode.sh <mode>}"
[[ -f "$HOME/.config/hypr/monitors/$mode.lua" ]] || {
  echo "[mode.sh] unknown mode: $mode (no monitors/$mode.lua)" >&2
  exit 1
}

PREV_WS=$(hyprctl activeworkspace -j 2>/dev/null |
  jq -r 'select(.id > 0) | .id' 2>/dev/null) || PREV_WS=1
[[ $PREV_WS =~ ^[0-9]+$ ]] || PREV_WS=1

cat >"$HOME/.config/hypr/monitors.lua" <<EOF
require("monitors.$mode")
EOF

# hyprctl reload は async。configreloaded event が出てから awww を触らないと
# 新 monitor 構成への img 投下が取りこぼされる。
# event socket を購読しておいて reload を発火 → configreloaded を待つ。
HYPR_SOCK="${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
exec {EV_FD}< <(socat -u "UNIX-CONNECT:$HYPR_SOCK" - 2>/dev/null)
sleep 0.05 # socat の接続確立待ち (process substitution は非同期起動)

hyprctl reload

while read -r -t 2 -u "$EV_FD" line; do
  [[ $line == configreloaded* ]] && break
done
exec {EV_FD}<&-

# 壁紙は apply.sh(唯一の書き込み経路)へ委譲。output 待ち・表示検証・色の整合は
# apply.sh 内の実状態照合が担う。last_wallpaper 不在時は pyprland の適用に任せる。
LAST="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/last_wallpaper"
if [[ -f $LAST ]] && [[ -r "$(<"$LAST")" ]]; then
  "$HOME/.config/hypr/scripts/wallpaper/apply.sh" "$(<"$LAST")" >/dev/null 2>&1 || true
fi
pkill -f waybar 2>/dev/null
sleep 0.1
uwsm app -- waybar >/dev/null 2>&1 &
disown

hyprctl dispatch workspace "$PREV_WS" >/dev/null 2>&1 || true
