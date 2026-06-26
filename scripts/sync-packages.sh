#!/usr/bin/env bash
# Snapshot currently installed packages into dotfiles/packages/yay.txt
# baseline を差し引いた native + AUR を一本にまとめる。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$REPO_ROOT/packages"
BASELINE="$OUT_DIR/cachyos-baseline.txt"

mkdir -p "$OUT_DIR"

{
  if [[ -f "$BASELINE" ]]; then
    pacman -Qqen | sort | comm -23 - <(sort -u "$BASELINE")
  else
    pacman -Qqen | sort
  fi
  pacman -Qqem 2>/dev/null || true
} | sort -u > "$OUT_DIR/yay.txt"

echo "[sync-packages] wrote $OUT_DIR/yay.txt ($(wc -l < "$OUT_DIR/yay.txt") packages)"
