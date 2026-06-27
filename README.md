# dotfiles

Home Manager による個人設定管理リポジトリ。
CachyOS（Hyprland デスクトップ）と WSL の2環境をサポートする。

## セットアップ

### 1. リポジトリをクローンする

```bash
git clone https://github.com/mkiin/dotfiles ~/dotfiles
```

### 2. ブートストラップスクリプトを実行する

```bash
bash ~/dotfiles/scripts/bootstrap-cachyos.sh   # CachyOS
bash ~/dotfiles/scripts/bootstrap-wsl.sh       # WSL
```

スクリプトは冪等で、以下を順に行う。

- Nix のインストール（Determinate Nix Installer）
- `nix run` による Home Manager の初回適用
- pacman フックの配置（CachyOS のみ）
- ログインシェルの zsh への変更

初回適用後は `home-manager` コマンドが使えるようになる。

```bash
home-manager switch --flake .#cachyos
```

### 3. Windows 版 WezTerm の設定をリンクする（WSL）

Windows 版 WezTerm は Windows 側の設定ファイルを読むため、WSL 側の dotfiles へシンボリックリンクを張る。
PowerShell で WSL ディストリビューション名を確認する。

```powershell
wsl -l -v
```

表示名が `Ubuntu-26.04` の場合は、PowerShell で以下を実行する。

```powershell
New-Item -ItemType Directory "$env:USERPROFILE\.config\wezterm" -Force

New-Item -ItemType SymbolicLink `
  -Path "$env:USERPROFILE\.config\wezterm\wezterm.lua" `
  -Target "\\wsl.localhost\Ubuntu-26.04\home\mkiin\dotfiles\wezterm\wezterm.lua" `
  -Force
```

通常の PowerShell で失敗する場合は、管理者 PowerShell で再実行する。
Windows の Developer Mode が有効なら、管理者権限なしで作成できる場合がある。

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
