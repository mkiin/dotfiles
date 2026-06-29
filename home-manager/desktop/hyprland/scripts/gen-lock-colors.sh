#!/usr/bin/env bash
# lock.png から hyprlock 専用カラーパレット (lock-colors.conf) を再生成する。
# Ambient ロック画面の固定背景画像に調和した色を matugen で生成し、
# リポジトリ内の生成物を上書きする。生成後は git diff を確認してコミットすること。
# 使い方: dotfiles リポジトリ内で実行する。
#   ./home-manager/desktop/hyprland/scripts/gen-lock-colors.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
IMG="$ROOT/home-manager/desktop/hyprland/lock.png"
TEMPLATE="$ROOT/home-manager/desktop/matugen/templates/lock-colors.conf"
OUT="$ROOT/home-manager/desktop/hyprland/lock-colors.conf"

if [[ ! -f $IMG ]]; then
  echo "error: lock image not found: $IMG" >&2
  echo "先に lock.png を配置してください。" >&2
  exit 1
fi

TMPCONF="$(mktemp --suffix=.toml)"
trap 'rm -f "$TMPCONF"' EXIT
cat >"$TMPCONF" <<EOF
[templates.lock]
input_path = "$TEMPLATE"
output_path = "$OUT"
EOF

matugen image "$IMG" --config "$TMPCONF" --mode dark --source-color-index 0
echo "generated: $OUT"
echo "git diff で確認してコミットしてください。"
