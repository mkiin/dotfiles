#!/usr/bin/env bash
# CachyOS 用 dotfiles ブートストラップ。冪等。
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
nix run github:nix-community/home-manager -- switch --flake .#cachyos

# 3. pacman / AUR パッケージを復元
if [[ -s "$REPO_ROOT/packages/pacman.txt" ]]; then
  log "pacman パッケージを復元"
  sudo pacman -S --needed --noconfirm - <"$REPO_ROOT/packages/pacman.txt"
fi
if [[ -s "$REPO_ROOT/packages/yay.txt" ]]; then
  log "AUR パッケージを復元"
  yay -S --needed --noconfirm - <"$REPO_ROOT/packages/yay.txt"
fi

# 4. pacman 自動スナップショットフックを配置
HOOK_SRC="$REPO_ROOT/hooks/99-sync-user-packages.hook"
HOOK_DST="/etc/pacman.d/hooks/99-sync-user-packages.hook"
if [[ ! -f $HOOK_DST ]]; then
  log "pacman フックを配置"
  sudo install -Dm 644 -o root -g root "$HOOK_SRC" "$HOOK_DST"
else
  log "pacman フック導入済み"
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
