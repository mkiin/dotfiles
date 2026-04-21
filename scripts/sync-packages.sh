#!/usr/bin/env bash
# Snapshot currently installed packages into dotfiles/packages/
# Usage: ./scripts/sync-packages.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$REPO_ROOT/packages"

mkdir -p "$OUT_DIR"

# 明示インストール & 公式リポジトリ由来
pacman -Qqen > "$OUT_DIR/pacman.txt"

# 明示インストール & foreign (AUR)。0 件のとき pacman は exit 1 を返すので吸収。
pacman -Qqem > "$OUT_DIR/aur.txt" || true

# flatpak アプリ
if command -v flatpak >/dev/null 2>&1; then
  flatpak list --app --columns=application > "$OUT_DIR/flatpak.txt"
fi

echo "[sync-packages] wrote:"
wc -l "$OUT_DIR"/*.txt
