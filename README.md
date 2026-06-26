# dotfiles

Home Manager による個人設定管理リポジトリ。
CachyOS（Hyprland デスクトップ）と WSL の2環境をサポートする。

## 構成

```
dotfiles/
├── flake.nix               # エントリーポイント
├── nix/
│   ├── hosts/              # ホスト別設定（cachyos / wsl）
│   ├── modules/
│   │   ├── home/           # 全ホスト共通（zsh, git, neovim など）
│   │   ├── linux/          # Linux 共通
│   │   └── linux/desktop/  # デスクトップ環境（CachyOS のみ）
│   │       └── hyprland/   # Hyprland 固有
│   └── lib/                # mkHome などのユーティリティ
├── hypr/                   # Hyprland 設定（Lua モード）
├── waybar/                 # Waybar
├── quickshell/             # Quickshell
├── wlogout/                # Wlogout
├── matugen/                # Matugen テンプレート
├── wallust/                # Wallust テンプレート
├── nvim/                   # Neovim
├── fcitx5/                 # fcitx5
├── mouse/                  # マウス設定・スクリプト（G703H / ERGO M575）
├── local/                  # ~/.local 以下のファイル
└── scripts/                # 汎用スクリプト
```

## モジュール階層

```
home/          全ホスト共通
linux/         Linux 共通（WSL を含む）
linux/desktop/ デスクトップ環境（CachyOS のみ）
```

`linux/desktop/` 以下の設定（Hyprland, Waybar, Quickshell, fcitx5 など）は WSL には適用されない。

## 適用

```bash
# 新規セットアップ（git add が必要）
git add .
home-manager switch --flake .#cachyos   # CachyOS
home-manager switch --flake .#wsl       # WSL
```

新規ファイルを追加したとき、`git add` を先に実行する。
Nix flake は git-tracked なファイルのみを参照するため、未追跡のファイルはエラーになる。

## シンボリックリンク管理

`hypr/`, `waybar/`, `quickshell/` など頻繁に編集する設定は `mkOutOfStoreSymlink` でシンボリックリンクとして配置している。
このリポジトリを直接編集すれば即時に反映される（`home-manager switch` は不要）。

`nix/modules/` の変更（パッケージ追加、サービス設定など）は `home-manager switch` が必要。

## 壁紙と配色

[matugen](https://github.com/InioX/matugen) で壁紙から Material You の配色を生成し、Hyprland, Waybar, Quickshell, Wlogout, hyprlock に適用する。
[wallust](https://codeberg.org/explosion-mental/wallust) は Pywal 互換のテンプレートエンジンとして補完的に使用する。

壁紙を変更したあと、以下を実行して配色を更新する。

```bash
matugen image <画像パス>
wallust run <画像パス>
```
