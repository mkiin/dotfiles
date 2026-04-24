#!/usr/bin/env bash
# デスク 3 枚を有効化し、ベッド用 HDMI-A-1 を無効化する。
# monitors.conf の定義と一致させ、ワークスペース所有権も元に戻す。
# ws 1-3 は persistent:true で常在、ws 4 は HDMI-A-1 disable 時は persistent しない。
hyprctl --batch "\
keyword monitor DP-3,1920x1080@60,0x0,1 ; \
keyword monitor DP-2,2560x1440@180,1920x0,1 ; \
keyword monitor DP-1,1920x1080@100,4480x0,1 ; \
keyword monitor HDMI-A-1,disable"

# monitors.conf の workspace rule (ws 1→DP-3, ws 2→DP-2, ws 3→DP-1, persistent) が真なので、
# monitor 復帰により ws 1-3 は自動的に home monitor へ戻る。ws 4 は HDMI-A-1 disable で消える。

# モニター位置変更で layer surface (awww の壁紙・waybar) が旧座標に取り残される
# ため、レイヤーを作り直す
awww restore >/dev/null 2>&1 || true
pkill -x waybar 2>/dev/null
uwsm app -- waybar >/dev/null 2>&1 &
disown
