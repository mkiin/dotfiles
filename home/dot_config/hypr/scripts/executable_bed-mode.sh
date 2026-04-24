#!/usr/bin/env bash
# モニター構成 + ワークスペース所有権をまとめて切替。
# 1 つの --batch に入れることで:
#   - モニター重複チェックは末状態で評価される(中間の overlap を無視)
#   - HDMI-A-1 の modeset を DP-* disable より先に発行し信号断を回避
#   - workspace ルールも同じトランザクションで HDMI-A-1 へ付け替え
# persistent:true で ws 1-4 を常在化 → Super+I/O (e-1/e+1) が全 ws を巡回できる。
hyprctl --batch "\
keyword monitor HDMI-A-1,1920x1080@144,0x0,1 ; \
keyword monitor DP-3,disable ; \
keyword monitor DP-2,disable ; \
keyword monitor DP-1,disable"

# workspace 1-4 を HDMI-A-1 上で実体化する。
# monitors.conf の rule は ws 1-3 を DP-* にピン留めしているため `hyprctl keyword workspace`
# では runtime のモニター割当を上書きできない。代わりに dispatch workspace で visit すると
# Hyprland は home monitor が disable 中でも現在有効な HDMI-A-1 に ws を作成する。
orig_ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1')
for n in 1 2 3 4; do
    hyprctl dispatch workspace "$n" >/dev/null
done
hyprctl dispatch workspace "$orig_ws"

# カーソルを HDMI-A-1 へ、DPMS スタンバイしていたら叩き起こす
hyprctl dispatch focusmonitor HDMI-A-1
hyprctl dispatch dpms on HDMI-A-1

# モニター位置変更で layer surface (awww の壁紙・waybar) が旧座標に取り残される
# ため、レイヤーを作り直す
awww restore >/dev/null 2>&1 || true
pkill -x waybar 2>/dev/null
uwsm app -- waybar >/dev/null 2>&1 &
disown
