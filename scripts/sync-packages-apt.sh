#!/usr/bin/env bash
# Snapshot manually-installed apt packages into dotfiles/packages/apt.txt
# apt.txt は「WSL Ubuntu インストール直後の baseline」を差し引いたユーザ選択のみ。
# baseline は packages/ubuntu-baseline.txt (初回 apt-mark showmanual から抽出)。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$REPO_ROOT/packages"
BASELINE="$OUT_DIR/ubuntu-baseline.txt"

mkdir -p "$OUT_DIR"

# apt: 明示導入 (manual) - baseline
if [[ -f "$BASELINE" ]]; then
  apt-mark showmanual | sort | comm -23 - <(sort -u "$BASELINE") > "$OUT_DIR/apt.txt"
else
  # baseline がまだ無ければ raw dump (初回セットアップ中の保険)
  apt-mark showmanual | sort > "$OUT_DIR/apt.txt"
fi

echo "[sync-packages-apt] wrote:"
wc -l "$OUT_DIR/apt.txt"
