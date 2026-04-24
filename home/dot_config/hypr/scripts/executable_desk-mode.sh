#!/usr/bin/env bash
# モード状態を共有 (wallpaper.sh が reload を抑制するかの判定に使う)
echo desk > "${XDG_RUNTIME_DIR:-/tmp}/hypr-monitor-mode"

# デスク 3 枚を有効化し、ベッド用 HDMI-A-1 を無効化する。
# monitors.conf の定義と一致させ、ワークスペース所有権も元に戻す。
hyprctl --batch "\
keyword workspace 1,monitor:DP-3,default:true ; \
keyword workspace 2,monitor:DP-2,default:true ; \
keyword workspace 3,monitor:DP-1,default:true ; \
keyword workspace 4,monitor:HDMI-A-1,default:true ; \
keyword monitor DP-3,1920x1080@60,0x0,1 ; \
keyword monitor DP-2,2560x1440@180,1920x0,1 ; \
keyword monitor DP-1,1920x1080@100,4480x0,1 ; \
keyword monitor HDMI-A-1,disable"

# モニター位置変更で layer surface (awww の壁紙・waybar) が旧座標に取り残される
# ため、レイヤーを作り直す
awww restore >/dev/null 2>&1 || true
pkill -x waybar 2>/dev/null
uwsm app -- waybar >/dev/null 2>&1 &
disown

