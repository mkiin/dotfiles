# 環境セットアップ手順書

Nix + Home Manager でユーザー環境を宣言的に管理する。
新しい PC で以下の手順を実行すれば、同じ環境が再現される。

## 構成概要

```
~/personal/dotfiles/
├── flake.nix          # Nix 入力定義（nixpkgs, home-manager）
├── flake.lock         # バージョンロック
├── home.nix           # パッケージ + dotfiles 配置定義
└── config/            # 設定ファイル（実体）
    ├── zsh/           # .zshrc, .zshenv
    ├── git/           # .gitconfig
    ├── ghostty/       # Ghostty 設定
    ├── nvim/          # Neovim (LazyVim) 設定
    ├── starship/      # プロンプト
    ├── sheldon/       # Zsh プラグイン
    ├── lazygit/       # lazygit 設定
    ├── lazydocker/    # lazydocker 設定
    ├── mise/          # mise 設定（ランタイム管理）
    ├── fcitx5/        # 日本語入力設定
    ├── uv/            # Python パッケージマネージャ設定
    ├── pip/           # pip 設定
    ├── wezterm/       # WezTerm 設定
    ├── .npmrc         # npm 設定
    └── (environment.d/fcitx5.conf は home.nix 内で生成)
```

## 役割分担

| 管理ツール | 管理対象 |
|---|---|
| **Nix (Home Manager)** | CLIツール、設定ファイル、日本語入力環境 |
| **mise** | 言語ランタイム（node, bun, deno, rust, uv）、supabase, claude-code |
| **apt** | Docker、build-essential/gcc、フォント、ca-certificates 等のシステム基盤 |

## 新しい PC でのセットアップ（3ステップ）

### 1. Nix をインストール

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
```

インストール後、新しいシェルを開くか以下を実行:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### 2. dotfiles を clone

```bash
git clone git@github.com:mkiin/dotfiles.git ~/personal/dotfiles
```

### 3. Home Manager を適用

```bash
cd ~/personal/dotfiles
nix run home-manager/master -- switch --flake .
```

これで以下が一括セットアップされる:
- 全 CLI ツール（ripgrep, fzf, neovim, ghostty 等）
- 全設定ファイル（.zshrc, .gitconfig, nvim 等）
- 日本語入力（fcitx5 + mozc）の環境変数

### 4. mise をインストール（ランタイム用）

```bash
curl https://mise.run | sh
mise install
```

### 5. 再ログイン

fcitx5 の環境変数（`environment.d/fcitx5.conf`）はセッション起動時に読まれるため、
ログアウト → ログインが必要。

## 日常の運用

### 設定ファイルを編集した場合

設定ファイルは `~/personal/dotfiles/config/` 以下の実体を直接編集できる。
（`~/.config/ghostty/config` 等はシンボリンクなので直接編集してもOK）

```bash
cd ~/personal/dotfiles
git add -A
git commit -m "update ghostty config"
git push
```

### パッケージを追加/削除する場合

1. `home.nix` の `home.packages` を編集
2. 反映:

```bash
cd ~/personal/dotfiles
home-manager switch --flake .
git add -A && git commit -m "add xxx" && git push
```

### パッケージを全て最新に更新する場合

```bash
cd ~/personal/dotfiles
nix flake update nixpkgs
home-manager switch --flake .
git add -A && git commit -m "update nixpkgs" && git push
```

### Home Manager 本体を更新する場合

```bash
cd ~/personal/dotfiles
nix flake update home-manager
home-manager switch --flake .
```

更新後はリリースノートを確認し、`home.stateVersion` の変更が必要か確認する。
https://nix-community.github.io/home-manager/release-notes.xhtml

### ロールバック

設定ミスで環境が壊れた場合:

```bash
home-manager switch --rollback
```

世代一覧を確認:

```bash
home-manager generations
```

## Nix 管理パッケージ一覧

| カテゴリ | パッケージ |
|---|---|
| CLIユーティリティ | ripgrep, fd, fzf, bat, eza, jq, delta, zoxide, lazygit, lazydocker, gh, starship, sheldon, neovim |
| シェルユーティリティ | shellcheck, shfmt |
| 入力メソッド | fcitx5, fcitx5-mozc, fcitx5-gtk |
| ターミナル | ghostty |
| 基本ツール | git, curl, wget, zip, unzip, zsh, gnupg, openssh |

## mise 管理パッケージ一覧

| カテゴリ | パッケージ |
|---|---|
| ランタイム | node (24), bun, deno, rust, uv |
| インフラ | supabase |
| その他 | claude-code |

## アンインストール

### Home Manager

```bash
home-manager uninstall
```

### Nix

```bash
/nix/nix-installer uninstall
```

## 参考

- Nix 公式: https://nixos.org/
- Home Manager: https://github.com/nix-community/home-manager
- Nixpkgs パッケージ検索: https://search.nixos.org/packages
- Home Manager オプション検索: https://home-manager-options.extranix.com/
- チュートリアル「ちいさくはじめる Nix」: https://github.com/ryuryu333/zenn-contents/tree/main/books/1c0373f3570334
