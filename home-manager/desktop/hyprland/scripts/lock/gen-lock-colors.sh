#!/usr/bin/env bash
# selection.json の lock 壁紙から hyprlock 用カラーパレット (lock-colors.conf) を再生成する。
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
IMG="$ROOT/images/wallpaper/$(jq -r .lock "$ROOT/images/wallpaper/selection.json")"
TEMPLATE="$ROOT/home-manager/desktop/hyprland/lock-colors.template.conf"
OUT="$ROOT/home-manager/desktop/hyprland/lock-colors.conf"

if [[ ! -f $IMG ]]; then
  echo "error: lock image not found: $IMG" >&2
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
