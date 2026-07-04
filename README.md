# dotfiles

Nix flake による個人環境の宣言的管理リポジトリ。
以下の2つを1つの flake で管理する。

- **NixOS**（ホスト名 `nixos`） — Hyprland デスクトップ環境。システムごと NixOS で構築し、home-manager は NixOS モジュールとして統合する。
- **WSL**（`mkiin@wsl`） — 既存ディストリビューション上で home-manager を単体（standalone）で動かす。CLI とエディタのみで、デスクトップ関連は含まない。

> [!IMPORTANT]
> このリポジトリの実体は `~/ghq/github.com/<username>/dotfiles` に置く。
> `lib/default.nix` がこのパスを前提に `lnk`（後述）のリンク先を解決するため、別の場所には置かない。

## セットアップ（NixOS）

### 1. git/ghq を一時導入してリポジトリを取得する

```bash
# experimental features 不要の安定版 CLI で git/ghq を一時的に使う
sudo nixos-rebuild switch --flake .#nixos --option experimental-features "nix-command flakes"
cd "$(nix-shell -p ghq --run 'ghq root')/github.com/mkiin/dotfiles"
```

### 2. ハードウェア構成を生成する

マシン固有のため実機で生成し直す。

```bash
nix-shell -p git --run 'sudo nixos-generate-config --show-hardware-config > hosts/nixos/hardware-configuration.nix'
```

### 3. 初回 rebuild（その場で flakes を有効化）

```bash
sudo nixos-rebuild switch --flake .#nixos \
  --extra-experimental-features 'nix-command flakes'
```

一度成功すれば `nixos/core/nix` の設定が効くため、以降は `--extra-experimental-features` も `nix-shell` も不要になる。

```bash
sudo nixos-rebuild switch --flake .#nixos
```

## セットアップ（WSL / home-manager 単体）

Nix 未導入なら [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) を入れる。
これは `nix-command` / `flakes` をデフォルトで有効にするため、NixOS のような鶏卵問題は起きない。

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

リポジトリを取得して初回適用する。

```bash
nix shell nixpkgs#git nixpkgs#ghq --command ghq get github.com/mkiin/dotfiles
cd "$(ghq root)/github.com/mkiin/dotfiles"

git add .
nix run github:nix-community/home-manager -- switch --flake .#"mkiin@wsl"
```

2回目以降は `home-manager` コマンドが使える。

```bash
home-manager switch --flake .#"mkiin@wsl"
```

## 日常の使い方

`nixos/` や `home-manager/` の変更（パッケージ追加、サービス設定など）を反映する。

```bash
git add .

# NixOS
sudo nixos-rebuild switch --flake .#nixos

# WSL
home-manager switch --flake .#"mkiin@wsl"
```

新規ファイルを追加したときは `git add` を先に実行する。flake は git-tracked なファイルのみを参照する。

### lnk による即時反映

`hypr/`, `quickshell/`, `nvim/`, `matugen/` など頻繁に編集する設定は、`lib/default.nix` の `lnk` ヘルパーでリポジトリ実体へのシンボリックリンクとして配置している。
これらの中身はリポジトリを直接編集すれば即座に反映される（`rebuild` / `switch` の再実行は不要）。リンクの追加・削除など配置そのものを変えたときだけ再適用する。

## シークレット管理（agenix / rbw）

R2 認証などの秘密は [agenix](https://github.com/ryantm/agenix) で暗号化して `nixos/core/secrets/*.age` にコミットし、NixOS の activation 時に個人 age 鍵で復号して `/run/agenix/` に配置する。
復号鍵 `~/.config/agenix/key.txt` はリポジトリに入れず、[rbw](https://github.com/doy/rbw)（Bitwarden CLI）で退避・復元する。

> [!IMPORTANT]
> この age 鍵を失うと、暗号化した秘密を二度と復号できなくなる。生成したら必ず Bitwarden に退避する。

`programs.rbw`（`home-manager/cli/rbw`）で rbw を宣言的に導入し、鍵の保管・復元は 2 つの flake app で行う。

### 鍵の生成と保管（初回に 1 回）

```bash
# age 鍵を生成する
mkdir -p ~/.config/agenix
nix shell nixpkgs#age -c age-keygen -o ~/.config/agenix/key.txt
chmod 600 ~/.config/agenix/key.txt

# 表示された公開鍵を nixos/core/secrets/secrets.nix のルールに登録しておく（新規/鍵更新時）

# 秘密鍵を Bitwarden に退避する
rbw login && rbw unlock
nix run .#backup-agenix-key
```

`backup-agenix-key` は `AGE-SECRET-KEY-` 行を Bitwarden のエントリ `agenix-age-key` に保管する（既存なら更新）。鍵を作り直したときだけ再実行する。

### フレッシュインストールでの復元（最初の switch の前）

新マシンでは、最初の `nixos-rebuild switch` の**前**に秘密鍵を戻す。鍵が無いと agenix の復号に失敗して switch がこける。

```bash
rbw login
nix run .#restore-agenix-key   # Bitwarden → ~/.config/agenix/key.txt（mode 400）
```

`restore-agenix-key` は既存の `key.txt` があると上書きを拒否する。マスターパスワードの手入力が唯一の手作業で、以降は自動化される。

### 日常運用

普段は何もしない。`switch` のたびに agenix が `key.txt` を読んで秘密を自動復号する。

## 構成

```
dotfiles/
├── flake.nix            # エントリーポイント（nixosConfigurations / homeConfigurations）
├── lib/                 # makeNixosConfig / makeHomeManagerConfig / lnk ヘルパー
├── hosts/
│   ├── nixos/           # NixOS ホスト（system 設定 + hardware-configuration.nix）
│   └── wsl/             # WSL の home-manager 単体エントリ
├── nixos/               # NixOS システムモジュール
│   ├── core/            # boot, nix, locale, network, users, fonts など
│   ├── hardware/        # nvidia, bluetooth
│   └── desktop/         # display-manager, hyprland, sound, fcitx5 など
├── home-manager/        # home-manager モジュール
│   ├── cli/             # zsh, git, mise, starship, yazi など
│   ├── editor/          # neovim
│   ├── ai/              # claude-code, codex, agent-skills
│   └── desktop/         # hyprland, waybar, quickshell, zen, terminal など
├── packages/            # Arch/Ubuntu 時代のパッケージスナップショット（参考）
├── scripts/             # ブートストラップ・パッケージ同期スクリプト
├── hooks/               # apt/pacman 自動スナップショットフック
├── local/               # ~/.local 以下に配置するファイル
└── docs/                # 設計メモ・SDD の spec / plan
```

### モジュール階層

```
home-manager/         全ターゲット共通（cli, editor, ai）
home-manager/desktop/ デスクトップ環境（NixOS ホストのみ）
nixos/                NixOS システム設定（NixOS ホストのみ）
```

`hosts/nixos/default.nix` は `nixos/` と `home-manager` に加えて `home-manager/desktop` を読み込む。
`hosts/wsl/home-manager.nix` は `home-manager` のみを読み込むため、Hyprland・Waybar・Quickshell などデスクトップ関連は WSL には適用されない。

## 壁紙と配色

[matugen](https://github.com/InioX/matugen) で壁紙から Material You の配色を生成し、Hyprland, Waybar, Quickshell, Wlogout, hyprlock に適用する。
[wallust](https://codeberg.org/explosion-mental/wallust) は matugen が出さない Pywal 互換の `@color0..15` を Waybar 用に補完する。

壁紙の切り替えと配色更新は `home-manager/desktop/hyprland/scripts/wallpaper/apply.sh` がまとめて行う（matugen → wallust → reload の順を制御する）。手動で当てる場合は次を実行する。

```bash
matugen image <画像パス>
wallust run <画像パス>
```
