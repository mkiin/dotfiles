#!/usr/bin/env bash
# WSL (Ubuntu/Debian) 用 dotfiles ブートストラップ。冪等。
# mise(apt) → chezmoi(mise) → chezmoi apply → mise install(全ツール) → zsh ログインシェル化
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }

# 1. mise を apt 公式リポジトリから
if ! command -v mise >/dev/null 2>&1; then
  log "mise を apt 公式リポジトリから導入"
  sudo apt update -y
  sudo apt install -y curl git zsh ca-certificates build-essential
  sudo install -dm 755 /etc/apt/keyrings
  curl -fSs https://mise.en.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.asc >/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.en.dev/deb stable main" \
    | sudo tee /etc/apt/sources.list.d/mise.list >/dev/null
  sudo apt update -y && sudo apt install -y mise
else
  log "mise 導入済み ($(mise --version))"
fi

# 2. chezmoi で dotfiles を展開 (既存リポジトリを source に / 二重 clone しない)
log "chezmoi init + apply (source: $REPO_ROOT)"
mise exec chezmoi@latest -- chezmoi init --source="$REPO_ROOT"
mise exec chezmoi@latest -- chezmoi apply

# 3. 全ツール導入 (GitHub レート制限対策にトークンがあれば使う)
log "mise install (全ツール)"
if [ -z "${GITHUB_TOKEN:-}" ] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  GITHUB_TOKEN="$(gh auth token 2>/dev/null || true)"; export GITHUB_TOKEN
fi
if ! mise install; then
  warn "一部ツールが未導入。GitHub レート制限の可能性。'gh auth login' か GITHUB_TOKEN 設定後に 'mise install' を再実行。"
fi

# 4. apt パッケージ復元 + 自動スナップショットフック
if [ -s "$REPO_ROOT/packages/apt.txt" ]; then
  log "apt パッケージを復元"
  xargs -r sudo apt install -y < "$REPO_ROOT/packages/apt.txt"
fi
if [ ! -e /etc/apt/apt.conf.d/99sync-user-packages ]; then
  log "apt 自動スナップショットフックを配置"
  sudo install -m 644 -o root -g root \
    "$REPO_ROOT/hooks/99-sync-user-packages.apt.conf" \
    /etc/apt/apt.conf.d/99sync-user-packages
fi

# 5. ログインシェルを zsh に
zsh_bin="$(command -v zsh)"
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_bin" ]; then
  log "ログインシェルを zsh に変更 (パスワードを求められます)"
  chsh -s "$zsh_bin"
else
  log "ログインシェルは既に zsh"
fi

log "完了。反映するには新しいターミナルを開くか 'exec zsh'。bash で 'source ~/.zshrc' はしないこと。"
