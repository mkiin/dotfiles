# 環境再構成プラン (ドラフト)

Nix home-manager を廃止し、dotfiles は chezmoi、パッケージは pacman / yay / mise に整理する。

---

## 1. ツールの役割分担

| レイヤ | ツール | 役割 |
|---|---|---|
| システム/公式パッケージ | **pacman** | 基本ツール・CLIユーティリティ・デスクトップ周辺・フォント・カーネル等 |
| AUR (非公式) | **yay** | 公式リポジトリに無いもの。`paru` → `yay` に置換 |
| 言語ランタイム / 開発ツール | **mise** | 現状維持 |
| dotfiles | **chezmoi** | 設定ファイルの配置・テンプレート化 |
| GUIアプリ(一部) | **flatpak** | Zen ブラウザなど。現状維持 |

---

## 2. パッケージの割り当て

### 2.1 pacman (公式リポジトリ)

**基本ツール**
- `git`, `curl`, `wget`, `zip`, `unzip`, `zsh`, `gnupg`, `openssh`

**CLIユーティリティ**
- `ripgrep`, `fd`, `fzf`, `bat`, `eza`, `jq`, `git-delta`, `zoxide`, `lazygit`, `lazydocker`, `github-cli`, `starship`, `neovim`, `sheldon`

**シェルユーティリティ**
- `shellcheck`, `shfmt`

**Hyprland / デスクトップ周辺**
- `hyprland`, `hyprlock`, `hypridle`, `hyprshot`
- `waybar`, `swaync`, `rofi-wayland`, `wlogout`, `awww`, `quickshell`
- `walker` (CachyOS 公式リポジトリにあることを確認済)
- `matugen` (extra/matugen 4.1.0 確認済)
- `ghostty`, `sddm`, `uwsm`

**日本語入力**
- `fcitx5`, `fcitx5-mozc`, `fcitx5-gtk`, `fcitx5-qt`, `fcitx5-configtool`

**dotfiles 管理**
- `chezmoi` (extra/chezmoi 2.70.1 確認済)

**フォント / GPU / カーネル等**
- 既存維持 (`cachyos-*`, `linux-cachyos`, `nvidia-*`, `ttf-*` 等)

### 2.2 yay (AUR)

公式に無いものだけ最小限に。

- `elephant-all-bin` (Walker の backend、21プロバイダ全部入りパッケージ)
- `wallust`
- `hyprshutdown` (必要なら)

> 確認済: walker, sheldon, matugen は CachyOS 公式 repo にある → AUR 不要

### 2.3 mise (現状維持)

- **ランタイム**: `node (24)`, `bun`, `deno`, `rust`, `go`, `uv`
- **開発ツール**: `supabase`, `claude-code`

### 2.4 flatpak (現状維持)

- Zen ブラウザ
- 付随ランタイム (Freedesktop / Mesa / NVIDIA GL / VAAPI / codecs)

### 2.5 削除対象

**即削除 OK (確認済)**

| パッケージ | 理由 |
|---|---|
| `cachyos-fish-config` | fish 未使用 |
| `cachyos-wallpapers` | 自前壁紙使用 |
| `cachyos-themes-sddm` | astronaut テーマ使用 |
| `cachyos-micro-settings` | micro 未使用 |
| `cachyos-hello` | ウェルカム GUI、日常的に使わない |
| `cachyos-zsh-config` | 自前 zshrc と競合、oh-my-zsh/powerlevel10k を強制依存で引き込む |
| `alacritty` | ghostty + kitty でカバー |
| `hyprlauncher` | walker で代替 |
| `wofi` | 用途重複 |
| `micro` | 未使用 |
| `meld` | 未使用 |
| `glances` | 未使用(btop と機能重複) |
| `shelly` | CachyOS 独自 GUI、ターミナル運用で不要 |
| `paru` | yay に置換 |

**Nix 一式**

| パッケージ | 理由 |
|---|---|
| Nix + home-manager 一式 | 廃止。`~/.nix-profile/`, `/nix/store`, `result`, `flake.nix`, `flake.lock`, `home.nix` を除去 |

> 注: `rustup` (`~/.cargo/bin`, `~/.rustup/`) は削除しない。mise の rust プラグインは rustup のラッパーで、`~/.local/share/mise/installs/rust/1.95.0` は `~/.cargo/bin` への symlink。削除すると mise rust も壊れる。層構造(mise=UI, rustup=実体)として併存が正解。

**保持するもの(判断済)**

| パッケージ | 理由 |
|---|---|
| `cachyos-grub-theme` | Windows とのデュアルブート用。ただし Windows 側設定未完 → backlog |
| `cachyos-plymouth-theme`, `cachyos-plymouth-bootanimation` | ブート時アニメーションを残したい |
| `nano`, `vim` | `sudo visudo` 等で使用 |
| `firefox`, `firefox-i18n-ja` | Zen の fallback |
| `kitty` | 気分転換用のターミナル |
| `discord` | pacman 版で問題なく動作中 |
| `btop` | リソースモニタ TUI として常用 |
| `fastfetch` | ログインバナー・スクショ用に保持 |

**判断保留**

| パッケージ | 備考 |
|---|---|
| `dolphin` | GUI ファイルマネージャ変更予定(yazi/nautilus/thunar 等と比較) |

### 2.6 Nix と pacman で二重だったものの整理方針

以下は両方に入っていたが、**pacman に寄せて Nix 側を捨てる**:

`git`, `curl`, `wget`, `unzip`, `zsh`, `gnupg`, `openssh`, `ripgrep`, `awww`

---

## 3. dotfiles 管理 (chezmoi)

- ソース: `~/.local/share/chezmoi/` (デフォルト)
- リポジトリ: 現 `~/personal/dotfiles` の中身を chezmoi 構造に移行
- 現在 `config/*` に実体がある運用(mkOutOfStoreSymlink経由)から、chezmoi の `dot_*` / `private_*` 命名規則ベースに置き換え
- テンプレート機能は当面使わない(マルチOS対応が必要になった時だけ)

### 主な移行対象(config/ 以下)

zsh / git / ghostty / nvim / starship / sheldon / lazygit / lazydocker / mise / uv / pip / wezterm / hypr / matugen / awww / quickshell / waybar / swaync / wlogout / walker / elephant (menus) / fcitx5

---

## 4. パッケージ一覧の宣言的管理

chezmoi 自体にはパッケージ宣言機能がないため、git で管理するテキストファイルで補う。

```
dotfiles/
├── packages/
│   ├── pacman.txt    # pacman -Qqen (明示導入 & 公式リポジトリ由来)
│   ├── aur.txt       # pacman -Qqem (明示導入 & foreign = AUR)
│   └── flatpak.txt   # flatpak list --app --columns=application
└── scripts/
    └── sync-packages.sh   # 現状をダンプして packages/ 以下を更新
```

mise は `~/.config/mise/config.toml` が宣言ファイルなのでそのまま chezmoi 管理下に置く。

### 新 PC セットアップ手順(想定)

```bash
# 1. CachyOS インストール完了後
sudo pacman -S chezmoi yay

# 2. パッケージ復元
sudo pacman -S --needed - < packages/pacman.txt
yay -S --needed - < packages/aur.txt
flatpak install $(cat packages/flatpak.txt)

# 3. dotfiles 配置
chezmoi init --apply git@github.com:mkiin/dotfiles.git

# 4. 言語ランタイム
curl https://mise.run | sh
mise install
```

---

## 5. 現状との差分マトリクス

| カテゴリ | 現在 | 提案後 |
|---|---|---|
| dotfiles 配置 | Nix HM (`mkOutOfStoreSymlink`) | chezmoi |
| 基本ツール (git/curl/zsh等) | Nix HM + pacman (二重) | pacman のみ |
| CLIユーティリティ | Nix HM | pacman |
| シェルユーティリティ | Nix HM | pacman |
| Hyprland 周辺 (wayland系) | pacman | pacman (変更なし) |
| `walker` | Nix HM (flake input) | pacman (CachyOS 公式 repo) |
| `elephant` | Nix HM (flake input) | yay (`elephant-all-bin`) |
| `sheldon` | Nix HM | pacman |
| `matugen` | Nix HM | pacman (CachyOS 公式 repo) |
| `wallust` | Nix HM | yay (AUR) |
| AURヘルパー | paru (未使用) | yay |
| ランタイム / 開発ツール | mise | mise (変更なし) |
| GUIアプリ | pacman + flatpak | pacman + flatpak (変更なし) |
| パッケージ宣言管理 | `home.nix` | `packages/*.txt` + `mise/config.toml` |

---

## 6. SETUP.md の扱い

現行 SETUP.md は Nix 前提のため、移行完了後に全面書き換え。
新手順は「OSインストール → pacman → yay → flatpak → chezmoi → mise」の順。

---

## 7. Backlog (別途対応)

- [ ] **Windows デュアルブート設定** — `cachyos-grub-theme` が活きるのは GRUB メニューから Windows を選べる状態になってから。Windows 側の設定を行う
- [ ] `dolphin` の代替を検討(yazi / nautilus / thunar など比較)
- [ ] フォント明示リスト見直し(`cantarell-fonts`, `ttf-bitstream-vera`, `ttf-dejavu`, `ttf-liberation`, `ttf-opensans` 等は依存で残るので明示リストから外しても可)
- [ ] `linux-cachyos-lts` 併存の要否判断

---

## 8. 移行の実行順(ドラフト)

1. 現状のパッケージリストをスナップショット (`pacman -Qqen`, `pacman -Qqem`, `flatpak list`, `mise ls`)
2. Nix HM にしかない必要なパッケージを pacman / yay で先に入れる(git, ripgrep 等は既に pacman にもあるので実質 matugen/wallust/elephant-all-bin が対象)
3. dotfiles を chezmoi 形式に移行(別ブランチで作業)
4. Nix home-manager をアンインストール (`home-manager uninstall` → `/nix/nix-installer uninstall`)
5. `flake.nix`, `home.nix`, `result` を dotfiles から除去
6. `paru` → `yay` 置換 (`yay -S yay && pacman -Rns paru`)
7. 削除対象パッケージを `pacman -Rns` で削除
8. `rustup` / `~/.cargo/bin` / `~/.rustup/` 除去
9. SETUP.md 全面書き換え
