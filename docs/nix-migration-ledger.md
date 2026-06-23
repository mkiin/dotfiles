# Nix 移行台帳

調査日：2026-06-24。

Nixpkgs の有無は、未固定の `nixpkgs` registry（commit `3e41b24abd260e8f71dbe2f5737d24122f972158`）で確認した。

実装では `flake.lock` に固定した Nixpkgs に対して再検証する。

## 所有者の原則

| 所有者 | 管理するもの |
| --- | --- |
| Home Manager と Nix | 共通 CLI、zsh、Git、ユーザー設定、Neovim 本体、WezTerm、AI skills、mise 本体 |
| mise | 言語ランタイム、プロジェクトごとの開発ツール、高頻度更新の AI CLI |
| pacman または apt | Nix 導入前の最小依存、OS サービス、ドライバ、デスクトップ統合 |
| yay または AUR | Nixpkgs にない CachyOS 専用パッケージ |
| winget | Windows 側で実行するアプリケーションとフォント |
| 管理対象外 | 秘密鍵、トークン、認証済みセッション、個人データ |

Home Manager は、native package manager が導入するアプリケーションを含め、追跡対象の全ユーザー設定ファイルを配布する。

`zsh` のパッケージ本体と設定は Nix が管理する。

初回適用後に `~/.nix-profile/bin/zsh` を `/etc/shells` へ登録し、ログインシェルとして設定する。

`git` のパッケージ本体と設定は Nix が管理する。

新規環境での clone 方法は、ghq の採用判断が終わるまで保留する。

## 設定ファイルの移行台帳

| 現在の場所 | 範囲 | 移行先 | 所有者 | 方針 |
| --- | --- | --- | --- | --- |
| `home/dot_zshrc.tmpl`、`home/dot_zshenv` | 共通、WSL、CachyOS | `zsh/` と `nix/home/zsh.nix` | Home Manager | 共通設定を `zsh/` へ移し、WSL と CachyOS の環境変数は環境モジュールで定義する |
| `home/dot_gitconfig`、`home/dot_npmrc` | 共通 | `git/`、`npm/` と各 Nix モジュール | Home Manager | ファイル配置を Home Manager に移管する |
| `home/dot_config/nvim` | 共通 | `nvim/` と `nix/home/neovim.nix` | Home Manager と Lazy.nvim | Neovim 本体は Nix で導入し、既存の Lua と Lazy.nvim 構成をそのまま配布する |
| `home/dot_config/wezterm` | 共通 | `wezterm/` と `nix/home/wezterm.nix` | Home Manager | Linux の設定を配布する。Windows 側 WezTerm には bootstrap の PowerShell 手順で同じ設定をリンクする |
| `home/dot_config/mise` | 共通 | `mise/` と `nix/home/mise.nix` | Home Manager と mise | mise 本体と設定配布は Nix、`[tools]` のツール取得は mise が担当する |
| `home/dot_config/starship`、`sheldon`、`lazygit`、`lazydocker`、`yazi`、`uv`、`pip` | 共通 | 同名のトップレベルディレクトリと各 Nix モジュール | Home Manager | 現在の設定をそのまま配布し、必要な CLI は Nix で導入する |
| `.claude`、将来の `claude/` | 共通 | `claude/` と `nix/home/claude.nix` | Home Manager | 認証情報を除く設定だけを配布する |
| 将来の `codex/` | 共通 | `codex/` と `nix/home/codex.nix` | Home Manager | 認証情報を除く設定だけを配布する |
| 将来の `agents/skills/` | 共通 | `agents/skills/` と `nix/home/agent-skills.nix` | agent-skills-nix | Codex と Claude Code の両方へ同一 skill を展開する |
| `home/dot_config/hypr`、`waybar`、`quickshell`、`wlogout`、`matugen`、`wallust`、`fcitx5`、`mouse`、`systemd/user`、`menus` | CachyOS | `cachyos/` と `nix/home/cachyos.nix` | Home Manager | アプリ本体が native package manager 管理でも、設定は Home Manager が配布する |
| `home/dot_local/share/applications`、`icons`、`bin` | CachyOS | `cachyos/` | Home Manager | desktop entry、アイコン、ゲーム起動スクリプトを配布する |
| `home/dot_config/swaync`、`home/dot_config/systemd/user/symlink_swaync.service` | CachyOS | 削除 | 削除 | SwayNC を廃止する |
| copyq の設定と package 宣言 | CachyOS | 削除 | 削除 | CopyQ を廃止する |
| `config/sddm` | CachyOS | `cachyos/sddm/` | native package manager と手動 root 操作 | SDDM は root 権限で動くため Home Manager の対象外とする |

## mise の台帳

| 現在の定義 | 移行後 | 理由 |
| --- | --- | --- |
| `go`、`bun`、`rust`、`deno`、`node` | mise | 言語ランタイムであり、プロジェクトごとの版指定を許容する |
| `uv` | mise | Python 開発ツールとして更新頻度が高い |
| `supabase` | mise | プロジェクト開発用 CLI |
| `claude-code`、`pipx:serena-agent`、`github:rtk-ai/rtk`、`aqua:codex` | mise | AI 開発 CLI と関連ツールは `latest` 追従を維持する |
| `ripgrep`、`fd`、`bat`、`eza`、`jq`、`fzf`、`zoxide`、`lazygit`、`lazydocker`、`gh`、`starship`、`sheldon`、`neovim`、`shellcheck`、`shfmt`、`delta`、`mo` | Nix | クロスプラットフォームの共通 CLI として flake lock に固定する |
| `chezmoi` | 削除 | Home Manager に移行して廃止する |

## Nixpkgs の検証済み候補

| Nixpkgs attribute | 確認した version | 予定 |
| --- | --- | --- |
| `ripgrep`、`fd`、`bat`、`eza`、`jq`、`fzf`、`zoxide` | すべて提供あり | Nix |
| `lazygit`、`lazydocker`、`gh`、`starship`、`sheldon` | すべて提供あり | Nix |
| `neovim`、`shellcheck`、`shfmt`、`delta`、`mo` | すべて提供あり | Nix |
| `wezterm`、`yazi` | 提供あり | Nix |
| `mise`、`uv` | 提供あり | mise 本体は Nix、uv は mise |
| `awww`、`matugen`、`wallust` | 提供あり | Nix |
| `cava`、`cliphist`、`gpu-screen-recorder`、`hypridle`、`hyprlock`、`hyprpolkitagent`、`hyprshot`、`hyprshutdown`、`pwvucontrol`、`waybar`、`wlogout` | 提供あり | Nix を第一候補 |
| `piper`、`solaar`、`bibata-cursors`、`phinger-cursors`、`discord` | 提供あり | 個別に決定 |
| `zen-browser` | 確認できず | AUR の `zen-browser-bin` を維持 |

## CachyOS パッケージの分担

Nixpkgs にあり、root 権限のサービス、udev rule、kernel module、desktop portal の登録を必要としないユーザー空間のプログラムは、Home Manager の `home.packages` で管理する。

| package | 所有者 | 理由 |
| --- | --- | --- |
| `awww`、`matugen`、`wallust` | Nix | Wayland セッション内でユーザーとして動く。設定は Home Manager が配布する |
| `cava`、`cliphist`、`hypridle`、`hyprlock`、`hyprpolkitagent`、`hyprshot`、`hyprshutdown`、`waybar`、`wlogout`、`mpv`、`pwvucontrol`、`resvg`、`socat` | Nix を第一候補 | Nixpkgs にあり、ユーザー空間で動く。実機で起動とセッション統合を検証してから pacman を削除する |
| Docker daemon、NVIDIA Container Toolkit、Bluetooth daemon、IME daemon | pacman | root 権限の service、driver、system-wide configuration を必要とする |
| `xdg-desktop-portal-gtk` | pacman | desktop portal の system-wide discovery と Wayland session integration を優先する |
| `piper`、`solaar` | pacman を当面維持 | hardware access と udev rule の動作を確認するまで native を優先する |
| `steam`、`discord` | 個別に決める | Nixpkgs に提供があるが、unfree package、game runtime、desktop integration の検証が必要 |
| `zen-browser-bin` | AUR | 検証した Nixpkgs に `zen-browser` はない |

Nix 化する package は、Home Manager の適用後に実行ファイル、desktop entry、Hyprland 起動、関連 script を確認する。

検証が通ってから pacman または AUR の同一 package を削除する。

同じプログラムを Nix と native package manager の両方で恒久的に管理しない。

## Native package manager の台帳

| 環境 | 最小依存または維持対象 | 理由 |
| --- | --- | --- |
| WSL apt | `ca-certificates`、`curl`、`sudo` | Nix installer を実行するための最小依存 |
| CachyOS pacman | `curl`、`sudo`、`base-devel`、`yay` | Nix installer と、Nixpkgs 非提供の AUR package を導入するための最小依存 |
| CachyOS pacman | Docker daemon、NVIDIA 関連、Bluetooth、IME、Hyprland、Wayland portal、systemd user と hardware utility | OS サービス、デバイス、ログインセッションと結合している |
| CachyOS AUR | `zen-browser-bin`、Nixpkgs 非提供のパッケージ | Nixpkgs に確実な候補がない |
| Windows winget | Windows Terminal、Windows 版 WezTerm、Nerd Font | Windows 側で描画または実行される |

## 保留事項

- ghq を導入するかどうか
- dotfiles repository の正規 clone パス
- AI が読む repository の clone と検索の運用
- CachyOS と WSL の bootstrap が導入する native package と system setting の全項目

## 削除対象

第1段階で削除する。

- chezmoi の source である `home/`（全設定をトップレベルの共通ディレクトリまたは `cachyos/` へ移した後）
- `.chezmoiroot`
- `packages/`、`hooks/`、旧 package snapshot script
- chezmoi 用 bootstrap の処理
- mise に重複定義された共通 CLI

第2段階まで native package manager がアプリ本体を管理する。

- SDDM 設定
- Wayland、Hyprland、GPU、入力機器に関する native package 定義

## 検証項目

- `nix flake check` が成功する。
- `home-manager switch --flake .#cachyos` と `.#wsl` が成功する。
- `command -v` が各 CLI の唯一の所有者を示す。
- `mise doctor` と `mise install` が成功する。
- 新しい WSL 環境で bootstrap 後に zsh、Git、Neovim、WezTerm 設定、Codex、Claude Code skills が利用できる。
