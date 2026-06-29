#!/usr/bin/env bash
# Snapshot currently installed packages into dotfiles/packages/
# pacman.txt: baseline を差し引いた native パッケージ
# yay.txt:    AUR パッケージ
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$REPO_ROOT/packages"
BASELINE="$OUT_DIR/cachyos-baseline.txt"

mkdir -p "$OUT_DIR"

if [[ -f $BASELINE ]]; then
  pacman -Qqen | sort | comm -23 - <(sort -u "$BASELINE") >"$OUT_DIR/pacman.txt"
else
  pacman -Qqen | sort >"$OUT_DIR/pacman.txt"
fi

pacman -Qqem 2>/dev/null | sort >"$OUT_DIR/yay.txt" || true

echo "[sync-packages] wrote:"
wc -l "$OUT_DIR/pacman.txt" "$OUT_DIR/yay.txt"
