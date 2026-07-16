#!/usr/bin/env bash
# ビルド済みテーマを store から直接 test-mode で表示する（ログアウト不要）。
# コピーを挟むと古い状態を掴むため、必ず store のパスを渡すこと。
# 使い方: theme-preview.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
theme="$(nix eval --raw "$ROOT#nixosConfigurations.nixos.config.services.displayManager.sddm.theme")"
sys="$(nix build "$ROOT#nixosConfigurations.nixos.config.system.build.toplevel" --no-link --print-out-paths)"
exec sddm-greeter-qt6 --test-mode --theme "$sys/sw/share/sddm/themes/$theme"
