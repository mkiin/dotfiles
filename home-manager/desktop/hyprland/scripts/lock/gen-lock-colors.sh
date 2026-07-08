#!/usr/bin/env bash
# lock.jpg から hyprlock 専用カラーパレット (lock-colors.conf) を再生成する。
# 【lock 壁紙の変更手順】
#   1. images/lock/lock.jpg を差し替える（参照名は lnk と hyprlock.conf で固定）
#   2. このスクリプトを実行して色トークンを再生成する
#   3. lock.jpg と lock-colors.conf をコミットする
# scrim (lock-scrim.png) は壁紙非依存なので再生成不要。反映は lnk のライブ反映のみで
# nixos-rebuild は不要。
# 使い方: dotfiles リポジトリ内で実行する。
#   ./home-manager/desktop/hyprland/scripts/lock/gen-lock-colors.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
IMG="$ROOT/images/lock/lock.jpg"
TEMPLATE="$ROOT/home-manager/desktop/hyprland/lock-colors.template.conf"
OUT="$ROOT/home-manager/desktop/hyprland/lock-colors.conf"

if [[ ! -f $IMG ]]; then
  echo "error: lock image not found: $IMG" >&2
  echo "先に lock.jpg を配置してください。" >&2
  exit 1
fi

TMPCONF="$(mktemp --suffix=.toml)"
trap 'rm -f "$TMPCONF"' EXIT
cat >"$TMPCONF" <<EOF
[config]

[templates.lock]
input_path = "$TEMPLATE"
output_path = "$OUT"
EOF

matugen image "$IMG" --config "$TMPCONF" --mode dark --source-color-index 0
echo "generated: $OUT"
echo "git diff で確認してコミットしてください。"
