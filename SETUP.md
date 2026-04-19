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
| **Nix (Home Manager)** | CLIツール、設定ファイル |
| **pacman** | 日本語入力（fcitx5 + mozc）、Docker、フォント、システム基盤 |
| **mise** | 言語ランタイム（node, bun, deno, rust, uv）、supabase, claude-code |

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
- 全 CLI ツール（ripgrep, fzf, neovim 等）
- 全設定ファイル（.zshrc, .gitconfig, nvim 等）
- fcitx5 の設定ファイル配置と環境変数

### 4. pacman でシステム連携が必要なパッケージをインストール

非 NixOS では nix の fcitx5/ghostty はシステムの GTK/Qt と統合できないため、pacman で入れる。

```bash
sudo pacman -S fcitx5 fcitx5-mozc fcitx5-gtk fcitx5-qt fcitx5-configtool ghostty
```

### 5. pacman でデスクトップ環境ツールをインストール

Wayland/GUI 依存のため Nix ではなく pacman で管理する。

```bash
sudo pacman -S waybar swaync rofi-wayland wlogout awww hyprlock hypridle hyprshot
```

### 6. pacman で GUIアプリをインストール

NixのDiscordはfcitx5(IME)・カーソルテーマ・フォントとの連携で問題が出るため pacman で管理する。

```bash
sudo pacman -S discord
```

### 6.5. AUR で hyprshutdown をインストール（NVIDIA+SDDM対応）

NVIDIA + SDDM 環境では `hyprctl dispatch exit` や `loginctl terminate-user` だとログアウト時に画面が戻らない。
公式推奨の `hyprshutdown` を AUR から導入し、`--vt 2` で TTY 切替を行うことで解消する。

```bash
paru -S hyprshutdown
```

さらに `hyprshutdown --vt N` が `sudo chvt N` を内部で呼ぶため、パスワードなしで実行できるよう sudoers を設定する:

```bash
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/chvt" | sudo tee /etc/sudoers.d/chvt
sudo chmod 440 /etc/sudoers.d/chvt
```

wlogout の logout アクションは `hyprshutdown --vt 2` を使用している (config/wlogout/layout)。

### 6.6. SDDM テーマをデプロイ（Astronaut）

SDDM は root 権限のグリーターのため、テーマは `/usr/share/sddm/themes/` に置く必要がある。
home-manager では管理不可なので手動で配置する。

```bash
# テーマ本体を /usr/share/sddm/themes/astronaut にコピー
sudo cp -r ~/personal/dotfiles/config/sddm/themes/astronaut /usr/share/sddm/themes/
```

テーマ切替は `/etc/sddm.conf` の `[Theme] Current=` を `astronaut` に変更する。
dropin (`/etc/sddm.conf.d/*.conf`) は SDDM 0.21 で期待通り上書きされないケースがあったため、直接編集が確実:

```bash
sudo sed -i 's/^Current=.*/Current=astronaut/' /etc/sddm.conf
```

### 6.7. SDDM のマルチモニター配置（Xsetup）

SDDM は X11 で動くため、Hyprland の `monitors.conf`（Wayland）を参照しない。
xrandr を Xsetup フックで実行して配置を再現する。

```bash
# xrandr をインストール（SDDM の X セッション用）
sudo pacman -S xorg-xrandr

# Xsetup スクリプトを配置
sudo cp ~/personal/dotfiles/config/sddm/scripts/Xsetup /usr/share/sddm/scripts/Xsetup
sudo chmod +x /usr/share/sddm/scripts/Xsetup
```

出力名が変わった場合は `journalctl -u sddm` で `xrandr:` エラーを確認し、
スクリプト内のモニター名を調整する。

### 6.8. SDDM 反映

テーマ更新時（色や背景を変えた時）も同じ `cp -r` を再実行する。
反映確認は SDDM を再起動: `sudo systemctl restart sddm`（**現在のセッションが落ちる**ため再ログイン覚悟）。

### 7. mise をインストール（ランタイム用）

```bash
curl https://mise.run | sh
mise install
```

### 8. 再ログイン

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
| 基本ツール | git, curl, wget, zip, unzip, zsh, gnupg, openssh |

## pacman 管理パッケージ一覧

| カテゴリ | パッケージ |
|---|---|
| 入力メソッド | fcitx5, fcitx5-mozc, fcitx5-gtk, fcitx5-qt, fcitx5-configtool |
| ターミナル | ghostty |
| デスクトップバー | waybar |
| 通知/コントロールセンター | swaync |
| ランチャー | rofi-wayland |
| 電源メニュー | wlogout |
| 壁紙 | awww |
| ロック画面 | hyprlock |
| アイドル管理 | hypridle |
| スクリーンショット | hyprshot |
| GUIアプリ | discord (NixはIME/カーソル/フォント連携で問題が出るため) |

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
