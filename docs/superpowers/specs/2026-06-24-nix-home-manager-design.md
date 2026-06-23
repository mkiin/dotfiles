# Nix と Home Manager の移行設計

## 目的

CachyOS と WSL2 で、共通の開発環境と端末設定を再現する。

chezmoi を廃止し、ユーザー設定の唯一の所有者を Home Manager にする。

## 対象環境

- CachyOS（Wayland、Hyprland）
- WSL2（notePC と dualboot で共用）

Home Manager の出力は `.#cachyos` と `.#wsl` の2つとする。

差分が必要になった時点でだけ、個別の WSL 出力を追加する。

## リポジトリ構成

```text
flake.nix
nix/
├── home.nix
└── home/
    ├── common.nix
    ├── wsl.nix
    ├── cachyos.nix
    ├── neovim.nix
    ├── wezterm.nix
    ├── zsh.nix
    ├── git.nix
    ├── mise.nix
    ├── codex.nix
    ├── claude.nix
    └── agent-skills.nix
nvim/
wezterm/
zsh/
git/
mise/
codex/
claude/
agents/skills/
cachyos/
scripts/
```

`nix/home.nix` は共通設定を読み込む。

`wsl.nix` と `cachyos.nix` は環境固有のパッケージ、環境変数、設定配布を定義する。

アプリ固有の設定本体はトップレベルの同名ディレクトリに置く。

Nix モジュールはパッケージ導入と設定ファイルの配布だけを担当する。

モジュールが複数に増えたドメインだけを `nix/home/<domain>/default.nix` へ分割する。

## 設定の所有者

Home Manager は、Nix package と native package manager のどちらがアプリ本体を導入するかにかかわらず、追跡対象の全ユーザー設定を配布する。

zsh と Git の本体および設定は Nix が管理する。

zsh をログインシェルにするための `/etc/shells` と `chsh` の処理は、後で確定する bootstrap の責務とする。

Neovim 本体は Nix が管理する。

既存の Lazy.nvim と Lua 設定は Nixvim へ移行せず、`nvim/` から配布する。

Codex と Claude Code の設定は Home Manager が配布する。

ローカル AI skill は `agents/skills/` を単一のソースとして、agent-skills-nix で両方へ展開する。

## パッケージの分担

Nix は共通 CLI、zsh、Git、Neovim、WezTerm、Yazi、mise 本体、AI skill 管理を担当する。

mise は言語ランタイム、Supabase、uv、Codex、Claude Code、Serena、rtk のような高頻度更新ツールを担当する。

CachyOS のユーザー空間 package は、Nixpkgs にある場合に Nix を第一候補とする。

`awww`、`matugen`、`wallust` は Nix 管理に確定する。

Docker daemon、driver、Bluetooth と IME の daemon、desktop portal は pacman が管理する。

native package manager が導入するアプリも、設定ファイルは Home Manager が配布する。

Nix と native package manager の重複 package は、Nix 版を検証した後に native 側を削除する。

詳細な対象と検証済み Nixpkgs attribute は [移行台帳](../../nix-migration-ledger.md) に記録する。

## 移行

現在の chezmoi source `home/` の全設定を、共通のトップレベルディレクトリまたは `cachyos/` へ移す。

Home Manager を backup extension 付きで初回適用し、既存の配置先を退避する。

Nix 版の起動と設定を確認してから、chezmoi、旧 package snapshot、重複する pacman/AUR package を削除する。

CopyQ と SwayNC は移行せず削除する。

## 検証

- `nix flake check`
- `home-manager build --flake .#cachyos`
- `home-manager build --flake .#wsl`
- zsh、Git、Neovim、WezTerm、mise、Codex、Claude Code skills の起動確認
- CachyOS で awww、matugen、wallust と Hyprland 関連の起動確認
- `command -v` で package 所有者を確認

## 保留事項

- ghq を導入するかどうか
- dotfiles と AI 用 source の clone 運用
- CachyOS と WSL の bootstrap が導入する native package と system setting の全項目
