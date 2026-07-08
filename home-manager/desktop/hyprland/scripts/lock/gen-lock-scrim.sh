#!/usr/bin/env bash
# hyprlock 右上の時計クラスタ用コーナー減光 PNG (lock-scrim.png) を生成する。
# 使い方: dotfiles リポジトリ内で実行する。
#   ./home-manager/desktop/hyprland/scripts/lock/gen-lock-scrim.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
OUT="$ROOT/images/lock/lock-scrim.png"
W=1400
H=800
# 右上角の黒の濃さ (0.0-1.0)。実機スクショを見て調整する
ALPHA=0.6

nix run nixpkgs#imagemagick -- \
  -size "${W}x${H}" \
  -define "gradient:center=${W},0" \
  -define "gradient:radii=${W},${H}" \
  "radial-gradient:rgba(0,0,0,${ALPHA})-rgba(0,0,0,0)" \
  "PNG32:${OUT}"
echo "generated: $OUT"
echo "git diff で確認してコミットしてください。"
