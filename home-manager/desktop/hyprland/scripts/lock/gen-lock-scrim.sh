#!/usr/bin/env bash
# hyprlock 用コーナー減光 PNG (images/lock/lock-scrim.png) を生成する。左上隅を暗くする。
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
OUT="$ROOT/images/lock/lock-scrim.png"
W=1400
H=800
ALPHA=0.6

nix run nixpkgs#imagemagick -- \
  -size "${W}x${H}" \
  -define "gradient:center=0,0" \
  -define "gradient:radii=${W},${H}" \
  "radial-gradient:rgba(0,0,0,${ALPHA})-rgba(0,0,0,0)" \
  "PNG32:${OUT}"
echo "generated: $OUT"
