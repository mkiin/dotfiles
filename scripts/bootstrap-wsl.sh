#!/usr/bin/env bash
# WSL (Ubuntu/Debian) 用 dotfiles ブートストラップ。冪等。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }

# 1. Nix インストール
if ! command -v nix >/dev/null 2>&1; then
  log "Nix をインストール"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
    sh -s -- install --no-confirm
fi
# 現セッションで nix を有効化
NIX_PROFILE=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
if [[ -f $NIX_PROFILE ]]; then
  # shellcheck source=/dev/null
  . "$NIX_PROFILE"
else
  warn "nix-daemon.sh が見つかりません。新しいシェルで再実行してください。"
  exit 1
fi
log "Nix $(nix --version)"

# 2. Home Manager 適用
log "Home Manager を適用"
cd "$REPO_ROOT"
git add .
nix run github:nix-community/home-manager -- switch --flake .#wsl

# 3. apt パッケージを復元
if [[ -s "$REPO_ROOT/packages/apt.txt" ]]; then
  log "apt パッケージを復元"
  xargs sudo apt install -y <"$REPO_ROOT/packages/apt.txt"
fi

# 4. apt 自動スナップショットフックを配置
APT_HOOK_SRC="$REPO_ROOT/hooks/99-sync-user-packages.apt.conf"
APT_HOOK_DST="/etc/apt/apt.conf.d/99sync-user-packages"
if [[ ! -f $APT_HOOK_DST ]]; then
  log "apt フックを配置"
  sudo install -m 644 -o root -g root "$APT_HOOK_SRC" "$APT_HOOK_DST"
else
  log "apt フック導入済み"
fi

# 5. ログインシェルを zsh に
zsh_bin="$(command -v zsh 2>/dev/null || true)"
if [[ -z $zsh_bin ]]; then
  warn "zsh が見つかりません"
elif [[ "$(grep "^$USER:" /etc/passwd | cut -d: -f7)" != "$zsh_bin" ]]; then
  log "ログインシェルを zsh に変更"
  chsh -s "$zsh_bin"
else
  log "ログインシェルは既に zsh"
fi

log "完了。新しいターミナルを開くか 'exec zsh' で反映。"
