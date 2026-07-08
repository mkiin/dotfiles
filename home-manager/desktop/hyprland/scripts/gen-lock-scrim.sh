#!/usr/bin/env bash
# hyprlock 右上の時計クラスタ用コーナー減光 PNG (lock-scrim.png) を生成する。
# 右上角が最も濃い黒のラジアルグラデーションで、image ウィジェットとして
# 壁紙の上・文字の下に重ねる（境界線のない減光で文字直載せの透明感を保つ）。
# 使い方: dotfiles リポジトリ内で実行する。
#   ./home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
OUT="$ROOT/images/lock/lock-scrim.png"
W=1100
H=650
# 右上角の黒の濃さ (0.0-1.0)。実機スクショを見て調整する
ALPHA=0.55

nix run nixpkgs#imagemagick -- \
  -size "${W}x${H}" \
  -define "gradient:center=${W},0" \
  -define "gradient:radii=${W},${H}" \
  "radial-gradient:rgba(0,0,0,${ALPHA})-rgba(0,0,0,0)" \
  "PNG32:${OUT}"
echo "generated: $OUT"
echo "git diff で確認してコミットしてください。"
