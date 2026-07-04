#!/usr/bin/env bash
# tokens.nix + mk-style.nix から ../style.css を再生成する。
# style.css は lnk 経由で実機に届くため、waybar の reload_style_on_change で即反映される。
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$dir/../../../.." && pwd)"
nix eval --raw --impure --expr "(import $dir/mk-style.nix) (import $dir/tokens.nix)" >"$dir/../style.css"
nix run "$repo#fmt" -- "$dir/../style.css" >/dev/null 2>&1 || true
echo "rendered: $dir/../style.css"
