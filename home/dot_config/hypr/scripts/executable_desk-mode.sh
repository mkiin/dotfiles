#!/usr/bin/env bash
# desk-mode 切替: DP-3/2/1 を有効化、HDMI-A-1 を無効化。
#
# monitor / workspace の定義は monitors-desk.conf に一元化済み。
# このスクリプトは「どのモードか」を active.conf に書いて reload するだけ。
#   1. monitors-active.conf を desk 向けに書換 → 永続化
#   2. hyprctl reload → 全 config 再評価 (monitor 切替 + workspace rule refresh)
#   3. layer surface 再構築 (Hyprland のバグ workaround、後述)

# 切替前: 現在の active ws を覚えておき、切替後にそこへ戻す (モード非依存)。
PREV_WS=$(hyprctl activeworkspace -j 2>/dev/null \
    | jq -r 'select(.id > 0) | .id' 2>/dev/null) || PREV_WS=1
[[ "$PREV_WS" =~ ^[0-9]+$ ]] || PREV_WS=1

echo "source = ~/.config/hypr/monitors-desk.conf" > "$HOME/.config/hypr/monitors-active.conf"
hyprctl reload

# awww-daemon が reload 後の monitor 構成を認識するまで待つ (最大 1 秒)。
# hyprctl reload は async なので、戻った直後に awww img を打つと
# 新規 enable された output が awww-daemon の view に未到達で取りこぼされ、
# 一部モニタだけ壁紙が更新されない race が起きる
# (例: bed→desk 直後、DP-2 だけ更新されて DP-1/3 が古いキャッシュのまま等)。
expected=$(hyprctl monitors -j 2>/dev/null | jq 'length')
for _ in {1..10}; do
    (( $(awww query 2>/dev/null | wc -l) == expected )) && break
    sleep 0.1
done

# Hyprland はモニター位置変更を layer surface に伝播しない既知バグがあるため、
# awww (壁紙) と waybar の layer は手動で作り直す。
# `awww restore` だと disable 中だったモニターは過去のキャッシュが残ってモード間で
# 壁紙が割れるため、~/.cache/last_wallpaper を明示適用してモード間同期する。
# transition-type none で瞬時 (モード切替なのでアニメ不要)。
LAST="$HOME/.cache/last_wallpaper"
if [[ -f "$LAST" ]] && [[ -r "$(<"$LAST")" ]]; then
    awww img --transition-type none "$(<"$LAST")" >/dev/null 2>&1 || true
else
    awww restore >/dev/null 2>&1 || true
fi
pkill -x waybar 2>/dev/null
uwsm app -- waybar >/dev/null 2>&1 &
disown

# 切替後: 切替前にいた ws へ復帰。
hyprctl dispatch workspace "$PREV_WS" >/dev/null 2>&1 || true
