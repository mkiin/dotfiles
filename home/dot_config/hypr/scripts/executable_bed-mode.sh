#!/usr/bin/env bash
# モード状態を共有 (wallpaper.sh が reload を抑制するために参照する)
echo bed > "${XDG_RUNTIME_DIR:-/tmp}/hypr-monitor-mode"

# モニター構成 + ワークスペース所有権をまとめて切替。
# 1 つの --batch に入れることで:
#   - モニター重複チェックは末状態で評価される(中間の overlap を無視)
#   - HDMI-A-1 の modeset を DP-* disable より先に発行し信号断を回避
#   - workspace ルールも同じトランザクションで HDMI-A-1 へ付け替え
hyprctl --batch "\
keyword workspace 1,monitor:HDMI-A-1,default:true ; \
keyword workspace 2,monitor:HDMI-A-1,default:true ; \
keyword workspace 3,monitor:HDMI-A-1,default:true ; \
keyword workspace 4,monitor:HDMI-A-1,default:true ; \
keyword monitor HDMI-A-1,1920x1080@144,0x0,1 ; \
keyword monitor DP-3,disable ; \
keyword monitor DP-2,disable ; \
keyword monitor DP-1,disable"

# カーソルを HDMI-A-1 へ、DPMS スタンバイしていたら叩き起こす
hyprctl dispatch focusmonitor HDMI-A-1
hyprctl dispatch dpms on HDMI-A-1

# モニター位置変更で layer surface (awww の壁紙・waybar) が旧座標に取り残される
# ため、レイヤーを作り直す
awww restore >/dev/null 2>&1 || true
pkill -x waybar 2>/dev/null
uwsm app -- waybar >/dev/null 2>&1 &
disown

