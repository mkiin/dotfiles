# 環境セットアップ手順書

CachyOS + Hyprland のデスクトップ環境を chezmoi で再現する。
旧 Nix + home-manager 構成からの移行後版。

## 構成概要

```
~/personal/dotfiles/
├── home/                # chezmoi sourceDir (dotfiles 本体)
│   ├── dot_gitconfig    → ~/.gitconfig
│   ├── dot_npmrc        → ~/.npmrc
│   ├── dot_zshrc        → ~/.zshrc
│   ├── dot_zshenv       → ~/.zshenv
│   └── dot_config/
│       ├── awww/
│       ├── elephant/menus/ (wallselect.lua)
│       ├── environment.d/fcitx5.conf
│       ├── fcitx5/
│       ├── ghostty/
│       ├── hypr/
│       ├── lazydocker/
│       ├── lazygit/
│       ├── matugen/
│       ├── mise/
│       ├── nvim/        (LazyVim)
│       ├── pip/
│       ├── quickshell/
│       ├── sheldon/
│       ├── starship/
│       ├── systemd/user.conf
│       ├── uv/
│       ├── walker/
│       ├── waybar/
│       ├── wezterm/
│       └── wlogout/
├── packages/            # パッケージ宣言ファイル
│   ├── cachyos-baseline.txt  # CachyOS インストール直後のパッケージ (~1075)
│   ├── pacman.txt       # baseline 除外済のユーザ選択パッケージ (~30)
│   ├── aur.txt          # AUR (yay) インストール一覧
│   └── flatpak.txt      # flatpak list スナップショット
├── hooks/
│   └── 99-sync-user-packages.hook  # pacman hook (自動 snapshot)
├── scripts/
│   └── sync-packages.sh # packages/ を現在の状態で更新 (hook から自動実行)
├── config/sddm/         # chezmoi 管理外 (root 権限で手動コピー)
├── ENV_MIGRATION_PLAN.md
├── DESKTOP_SPEC.md
└── SETUP.md
```

## 役割分担

| 管理ツール | 管理対象 |
|---|---|
| **pacman** | 基本ツール・CLIユーティリティ・Hyprland周辺・フォント・カーネル・GPU・IME |
| **yay** | AUR パッケージ (wallust, elephant-*-bin) |
| **mise** | 言語ランタイム (node/bun/deno/rust/go/uv) + 開発ツール (supabase, claude-code) |
| **flatpak** | Zen browser 等 |
| **chezmoi** | dotfiles 配置 (テンプレート機能は当面不使用) |

## 新 PC でのセットアップ

### 1. CachyOS インストール

公式 ISO でインストール。Hyprland エディションを選ぶとベースが揃う。

### 2. chezmoi と yay をインストール

```bash
sudo pacman -S chezmoi yay
```

### 3. dotfiles を展開

```bash
chezmoi init --apply git@github.com:mkiin/dotfiles.git
```

chezmoi が `~/.local/share/chezmoi` ではなく本リポジトリを直接 source にする設定は、リポジトリ内の
`home/.chezmoi.toml.tmpl` で管理する(未整備なら手動で `~/.config/chezmoi/chezmoi.toml` に下記を配置):

```toml
sourceDir = "/home/mkiin/personal/dotfiles/home"
```

### 4. パッケージを復元

`packages/pacman.txt` は CachyOS baseline (1075 個) を除外した
ユーザ選択 (~30 個) のみ。CachyOS Hyprland edition を同じ profile でインストール
してあれば、baseline の差分だけ追加すれば再現できる。

```bash
cd ~/personal/dotfiles
sudo pacman -S --needed - < packages/pacman.txt
yay -S --needed - < packages/aur.txt
flatpak install $(cat packages/flatpak.txt)
```

### 4.1 pacman hook を有効化

install / remove のたびに `packages/*.txt` を自動で最新化するフックをデプロイ:

```bash
sudo install -m 644 -o root -g root \
  hooks/99-sync-user-packages.hook \
  /etc/pacman.d/hooks/99-sync-user-packages.hook
```

> 以降、`sudo pacman -S foo` / `yay -S bar` で自動的に `packages/pacman.txt` /
> `packages/aur.txt` が更新される。手動の `./scripts/sync-packages.sh` は不要。

### 5. mise と言語ランタイム

```bash
# mise は pacman にもあるが念のため
sudo pacman -S --needed mise
mise install
```

### 6. SDDM テーマ (Astronaut) を手動配置

SDDM は root 権限で動くため chezmoi 管理外。

```bash
sudo cp -r ~/personal/dotfiles/config/sddm/themes/astronaut /usr/share/sddm/themes/
sudo cp ~/personal/dotfiles/config/sddm/scripts/Xsetup /usr/share/sddm/scripts/Xsetup
sudo chmod +x /usr/share/sddm/scripts/Xsetup
sudo sed -i 's/^Current=.*/Current=astronaut/' /etc/sddm.conf
```

### 7. NVIDIA + SDDM 対応 (必要なら)

NVIDIA + SDDM 環境で `hyprshutdown --vt 2` を使うため、sudoers を設定:

```bash
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/chvt" | sudo tee /etc/sudoers.d/chvt
sudo chmod 440 /etc/sudoers.d/chvt
```

AUR から `hyprshutdown` を追加導入(必要に応じて):

```bash
yay -S hyprshutdown
```

### 8. 再ログイン

fcitx5 の環境変数 (`~/.config/environment.d/fcitx5.conf`) はセッション起動時に読まれるため、ログアウト→ログインが必要。

---

## 日常運用

### dotfiles を編集する

chezmoi の source を直接編集するのが確実:

```bash
chezmoi edit ~/.zshrc        # エディタで開く
# もしくは直接 repo を編集
$EDITOR ~/personal/dotfiles/home/dot_zshrc
chezmoi apply                # ~/.zshrc に反映
```

`~/.config/hypr/*.conf` 等も同様。chezmoi 管理下のファイルを直接編集しても、次回 `chezmoi apply` で上書きされる点に注意。

### 変更を git に記録

```bash
cd ~/personal/dotfiles
git add -A
git commit -m "update zshrc"
git push
```

### パッケージを追加する

```bash
# 例: ripgrep を入れる
sudo pacman -S ripgrep

# スナップショットを更新して commit
./scripts/sync-packages.sh
git add packages/*.txt
git commit -m "add ripgrep"
```

### パッケージを削除する

```bash
sudo pacman -Rns foo
./scripts/sync-packages.sh
git add packages/*.txt
git commit -m "remove foo"
```

### AUR パッケージを追加する

```bash
yay -S <aur-pkg>
./scripts/sync-packages.sh
git commit -am "add aur/<aur-pkg>"
```

### 孤児の掃除

```bash
# 孤児パッケージを確認
pacman -Qdtq

# あれば削除
sudo pacman -Rns $(pacman -Qdtq)
```

### システム全体の更新

```bash
# 公式リポジトリ
sudo pacman -Syu

# AUR
yay -Sua

# mise 管理のランタイム
mise up
```

---

## パッケージ早見表

### pacman (公式リポジトリ) — 主要カテゴリ

| カテゴリ | パッケージ |
|---|---|
| 基本ツール | `git`, `curl`, `wget`, `unzip`, `zsh`, `gnupg`, `openssh` |
| CLIユーティリティ | `ripgrep`, `fd`, `fzf`, `bat`, `eza`, `jq`, `git-delta`, `zoxide`, `lazygit`, `lazydocker`, `github-cli`, `starship`, `neovim`, `sheldon` |
| シェルユーティリティ | `shellcheck`, `shfmt` |
| dotfiles | `chezmoi` |
| 言語ランタイム管理 | `mise` |
| Hyprland 周辺 | `hyprland`, `hyprlock`, `hypridle`, `hyprshot`, `waybar`, `swaync`, `rofi-wayland`, `wlogout`, `awww`, `quickshell`, `walker`, `matugen`, `ghostty`, `sddm`, `uwsm` |
| IME | `fcitx5`, `fcitx5-mozc`, `fcitx5-gtk`, `fcitx5-qt`, `fcitx5-configtool` |
| GUI | `firefox`, `kitty`, `dolphin`, `discord` |
| AUR ヘルパー | `yay` |

完全な一覧は `packages/pacman.txt`。

### yay (AUR)

| パッケージ | 用途 |
|---|---|
| `wallust` | カラースキーム生成 (matugen 併用) |
| `elephant-bin` | Walker の backend |
| `elephant-desktopapplications-bin` | アプリランチャープロバイダ |
| `elephant-menus-bin` | カスタム Lua メニュー (wallselect.lua) |
| `elephant-calc-bin` | 電卓 |
| `elephant-runner-bin` | シェルコマンド実行 |
| `elephant-files-bin` | ファイル検索 |
| `elephant-clipboard-bin` | クリップボード履歴 |
| `elephant-windows-bin` | ウィンドウ切替 |
| `elephant-providerlist-bin` | プロバイダ切替 UI |

完全な一覧は `packages/aur.txt`。

### mise (`~/.config/mise/config.toml`)

| カテゴリ | ツール |
|---|---|
| ランタイム | `node (24)`, `bun`, `deno`, `rust`, `go`, `uv` |
| 開発ツール | `supabase`, `claude-code` |

`rust` は mise が rustup (`~/.cargo/bin`) をラップする構造のため、rustup は削除しないこと。

### flatpak

| アプリ |
|---|
| `app.zen_browser.zen` (Zen browser) |

---

## トラブルシューティング

### 新しいターミナルで mise や sheldon が見つからない

`~/.zshrc` の末尾で initialize してる。コマンドがインストール済みか確認:

```bash
which mise sheldon starship zoxide
```

インストール済みで `command not found` になるなら、シェルの command-cache をクリア:

```bash
hash -r
```

### chezmoi apply で target 書き換えの確認が出る

```
target has changed since chezmoi last wrote it?
> diff/overwrite/all-overwrite/skip/quit
```

- `diff` で差分確認
- 意図しない変更なら `overwrite` (chezmoi source 側を優先)
- 意図した変更なら `skip` + chezmoi source 側を後で更新

### 権限モードだけズレる (100600 ↔ 100644)

chezmoi は source のパーミッションで target を上書きする。機密ファイルを 0600 で配置したいなら、source ファイル名に `private_` prefix を付ける:

```
home/dot_config/fcitx5/conf/private_notifications.conf
```

### Walker/Elephant がランチャー起動しない

systemd ではなく `~/.config/hypr/autostart.conf` の exec-once 経由で起動する設定。Hyprland を再起動するか、手動で:

```bash
uwsm app -- elephant &
uwsm app -- walker --gapplication-service &
```

---

## アンインストール

### chezmoi が配置したファイルを撤去

chezmoi は target を「元に戻す」機能を直接は持たない。撤去するには `chezmoi managed` で管理対象一覧を取得して手動削除する。

### mise を削除

```bash
sudo pacman -Rns mise
rm -rf ~/.local/share/mise ~/.config/mise
```

### 全リセット

```bash
# パッケージ
sudo pacman -Rns $(pacman -Qqe | grep -v -f <(pacman -Qqg base base-devel))

# dotfiles
cd ~/personal/dotfiles && git clean -xdf
```

---

## 参考リンク

- chezmoi 公式: https://www.chezmoi.io/
- mise 公式: https://mise.jdx.dev/
- Walker: https://github.com/abenz1267/walker
- Elephant: https://github.com/abenz1267/elephant
- matugen: https://github.com/InioX/matugen
- wallust: https://codeberg.org/explosion-mental/wallust
