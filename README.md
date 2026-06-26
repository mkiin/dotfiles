# dotfiles

Home Manager による個人設定管理リポジトリ。
CachyOS（Hyprland デスクトップ）と WSL の2環境をサポートする。

## セットアップ

### 1. Nix をインストールする

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

インストール後、シェルを再起動する。

```bash
exec zsh
```

### 2. リポジトリをクローンする

```bash
git clone https://github.com/mkiin/dotfiles ~/dotfiles
cd ~/dotfiles
```

### 3. Home Manager を初回適用する

Home Manager がまだインストールされていない場合、`nix run` で直接実行する。

```bash
git add .
nix run github:nix-community/home-manager -- switch --flake .#cachyos   # CachyOS
nix run github:nix-community/home-manager -- switch --flake .#wsl       # WSL
```

初回適用後は `home-manager` コマンドが使えるようになる。

```bash
home-manager switch --flake .#cachyos
```

## 日常の使い方

`nix/modules/` の変更（パッケージ追加、サービス設定など）を反映するには `home-manager switch` を実行する。

```bash
git add .
home-manager switch --flake .#cachyos
```

新規ファイルを追加したとき、`git add` を先に実行する。
Nix flake は git-tracked なファイルのみを参照するため、未追跡のファイルはエラーになる。

`hypr/`, `waybar/`, `quickshell/` など頻繁に編集する設定は `mkOutOfStoreSymlink` でシンボリックリンクとして配置している。
このリポジトリを直接編集すれば即時に反映される（`home-manager switch` は不要）。

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

### モジュール階層

```
home/          全ホスト共通
linux/         Linux 共通（WSL を含む）
linux/desktop/ デスクトップ環境（CachyOS のみ）
```

`linux/desktop/` 以下の設定（Hyprland, Waybar, Quickshell, fcitx5 など）は WSL には適用されない。

## 壁紙と配色

[matugen](https://github.com/InioX/matugen) で壁紙から Material You の配色を生成し、Hyprland, Waybar, Quickshell, Wlogout, hyprlock に適用する。
[wallust](https://codeberg.org/explosion-mental/wallust) は Pywal 互換のテンプレートエンジンとして補完的に使用する。

壁紙を変更したあと、以下を実行して配色を更新する。

```bash
matugen image <画像パス>
wallust run <画像パス>
```
