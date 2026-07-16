#!/usr/bin/env bash
# ビルド済みテーマを store から直接 test-mode で表示する（ログアウト不要）。
# コピーを挟むと古い状態を掴むため、必ず store のパスを渡すこと。
# 使い方: theme-preview.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
sddm="(builtins.getFlake \"path:$ROOT\").nixosConfigurations.nixos.config.services.displayManager.sddm"

# toplevel を建てると 28s かかる。テンプレート編集の反復で効くのはテーマの derivation だけ(約 4s)。
# head なのは extraPackages にテーマ 1 つしか入れていないため。
theme="$(nix eval --impure --raw --expr "$sddm.theme")"
pkg="$(nix build --impure --no-link --print-out-paths --expr "builtins.head $sddm.extraPackages")"
exec sddm-greeter-qt6 --test-mode --theme "$pkg/share/sddm/themes/$theme"
