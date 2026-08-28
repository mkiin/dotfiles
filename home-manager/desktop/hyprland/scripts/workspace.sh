#!/usr/bin/env bash
# WS はモニターに固定しない共有プール運用。WS が他モニターに在るとそちらへフォーカスごと
# 飛ぶため、先に現在のモニターへ引き寄せてから切替/送出する。
# configType = "lua" なので hyprctl dispatch の引数は Lua 式(hl.dsp.*)で書く。
set -u

action="${1:?usage: workspace.sh <focus|move> <n|+n|-n>}"
ws="${2:?usage: workspace.sh <focus|move> <n|+n|-n>}"

# pypr の max_workspaces と揃える。
MAX=10

# 相対指定は自前で解決する。native の e±1 も pypr change_workspace も「他モニターが
# 表示中/未生成の WS を飛ばす」ため、番号が素直に ±1 進まないのを避ける。
case "$ws" in
[+-]*)
  cur=$(hyprctl activeworkspace -j 2>/dev/null | jq -r 'select(.id > 0) | .id') || cur=""
  [[ $cur =~ ^[0-9]+$ ]] && ((cur <= MAX)) || cur=1
  ws=$(((cur - 1 + ws + MAX) % MAX + 1))
  ;;
esac

# 未生成の WS では失敗するが、その場合は続く dispatch が現在モニターに作るので無視してよい。
hyprctl dispatch "hl.dsp.workspace.move({ monitor = 'current', workspace = $ws })" >/dev/null 2>&1 || true

case "$action" in
focus) hyprctl dispatch "hl.dsp.focus({ workspace = $ws })" ;;
move) hyprctl dispatch "hl.dsp.window.move({ workspace = $ws })" ;;
*)
  echo "[workspace.sh] unknown action: $action" >&2
  exit 1
  ;;
esac
