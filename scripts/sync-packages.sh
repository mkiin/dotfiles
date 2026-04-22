#!/usr/bin/env bash
# Snapshot currently installed packages into dotfiles/packages/
# pacman.txt は「CachyOS インストール直後の baseline」を差し引いたユーザ選択のみ。
# baseline は packages/cachyos-baseline.txt (初回 install 日の pacman.log から抽出)。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$REPO_ROOT/packages"
BASELINE="$OUT_DIR/cachyos-baseline.txt"

mkdir -p "$OUT_DIR"

# pacman: 明示導入 - baseline
if [[ -f "$BASELINE" ]]; then
  pacman -Qqen | sort | comm -23 - <(sort -u "$BASELINE") > "$OUT_DIR/pacman.txt"
else
  # baseline がまだ無ければ raw dump (初回セットアップ中の保険)
  pacman -Qqen > "$OUT_DIR/pacman.txt"
fi

# AUR (foreign)。0件時は pacman が exit 1 を返すので吸収。
pacman -Qqem > "$OUT_DIR/aur.txt" 2>/dev/null || true
# 空ファイル保証
touch "$OUT_DIR/aur.txt"

echo "[sync-packages] wrote:"
wc -l "$OUT_DIR"/*.txt
