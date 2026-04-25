# File Structure

## リポジトリ直下

```
dotfiles/
├── .claude/             # Claude Code 用設定 (CLAUDE.md, settings.json)
├── docs/                # 本ドキュメント (リポジトリのみ、chezmoi 管理外)
├── home/                # chezmoi の source-of-truth
│   ├── dot_config/      # → ~/.config/   に展開される
│   ├── dot_gitconfig    # → ~/.gitconfig
│   ├── dot_npmrc        # → ~/.npmrc
│   ├── dot_zshenv       # → ~/.zshenv
│   └── dot_zshrc        # → ~/.zshrc
├── config/              # chezmoi 管理外の設定 (sddm 等の system-wide)
├── scripts/             # repo メンテ用スクリプト
│   └── sync-packages.sh
├── packages/            # arch + AUR + cachyos-baseline のパッケージリスト
│   ├── pacman.txt
│   ├── aur.txt
│   └── cachyos-baseline.txt
├── hooks/               # pacman post-transaction hook
├── hyprland-config-sample/   # 参考用 (他人の dotfiles を clone した参照ライブラリ)
├── official-example/    # 同上、コードマップ等の参考集
├── wiki/                # 各ツールの wiki ローカルキャッシュ (awww, matugen 等)
├── DESKTOP_SPEC.md
├── ENV_MIGRATION_PLAN.md
├── SETUP.md
├── backlog.md
├── memo.md
└── hypr-audit.md
```

## chezmoi 命名変換ルール

`home/` 以下のファイル名は chezmoi が live tree に展開する際に変換される:

| Source 名 | Live tree | 意味 |
|---|---|---|
| `dot_foo` | `.foo` | 隠しファイル / 隠しディレクトリ |
| `executable_foo.sh` | `foo.sh` (mode 0755) | 実行権限つき |
| その他 | そのまま | 普通のファイル |

詳細フローは `.claude/CLAUDE.md` の **5. Dotfiles Workflow (chezmoi)** を参照。

## `home/dot_config/` の内訳

```
home/dot_config/
├── elephant/                   # Walker の backend
│   └── menus/
│       └── wallselect.lua      # 壁紙セレクタ menu (Walker provider)
├── environment.d/              # systemd user environment
├── fcitx5/                     # IME 設定
├── ghostty/                    # ターミナル
│   └── config
├── hypr/                       # Hyprland 本体
│   ├── hyprland.conf           # メインエントリ + source 順序
│   ├── env.conf                # Hyprland セッション env (NVIDIA, IME 等)
│   ├── monitors.conf           # モニター構成 (desk-mode の真)
│   ├── input.conf              # 入力デバイス
│   ├── keybinds.conf           # キーバインド全て
│   ├── cursor.conf             # カーソル
│   ├── appearance.conf         # ウィンドウ装飾
│   ├── appearance/             # appearance の補助 (色等)
│   ├── colors.conf             # ⚠️  matugen 生成 (壁紙変更で上書き)
│   ├── rules.conf              # ウィンドウルール
│   ├── autostart.conf          # exec-once 群
│   ├── hyprlock.conf           # ロックスクリーン
│   └── scripts/                # シェルスクリプト群 (詳細は scripts.md)
│       ├── wallset-backend-startup.sh    # 起動時 entry: awww-daemon + ランダム/復元 (backend に委譲)
│       ├── wallset-backend.sh             # 壁紙変更エンジン (1 枚 → 全テーマ適用)
│       ├── wallpaper-thumb.sh          # Walker 用サムネ生成 (systemd path triggered)
│       ├── waybar-reload-css.sh        # matugen post_hook
│       ├── bed-mode.sh                 # 1モニター運用へ切替
│       └── desk-mode.sh                # 3モニター運用へ復帰
├── lazydocker/
├── lazygit/
├── matugen/                    # 色生成器
│   ├── config.toml             # 各 consumer の input/output template マッピング
│   └── templates/              # 色テンプレ (matugen 変数 → consumer 形式)
│       ├── hyprland-colors.conf
│       ├── waybar-colors.css
│       ├── walker-colors.css
│       └── wlogout-colors.css
├── mise/                       # CLI ツール manager
├── nvim/                       # LazyVim ベース
├── pip/
├── quickshell/
├── sheldon/                    # zsh plugin manager
├── starship/                   # shell prompt
├── systemd/
│   └── user/                   # systemd user units
│       ├── wallpaper-thumb.path        # 壁紙ディレクトリ監視
│       └── wallpaper-thumb.service     # サムネ再生成 (oneshot)
├── uv/
├── walker/                     # Launcher GUI
│   ├── config.toml
│   └── themes/
│       └── matugen/            # 壁紙連動テーマ (matugen で colors.css 生成)
├── waybar/                     # Status bar
│   ├── config.jsonc            # メイン設定
│   ├── style.css               # メインスタイル (CSS reload のフックポイント)
│   ├── CSS/                    # 分割 CSS
│   │   └── colors.css          # ⚠️  matugen 生成 (壁紙変更で上書き)
│   ├── Modules/                # モジュール JSON 群
│   └── Scripts/                # waybar から呼ぶスクリプト
├── wezterm/
└── wlogout/                    # 電源メニュー (logout / shutdown 等)
    └── colors.css              # ⚠️  matugen 生成
```

## ⚠️ マークの意味

`⚠️` が付いたファイルは **matugen が壁紙変更の度に上書きする生成物**。手動で編集してもすぐ消える。色を変えたいときは:

- 壁紙ごとの色味は壁紙を変更すれば追従する (matugen 自動)
- テンプレ自体を変えたいときは `home/dot_config/matugen/templates/<app>-colors.<ext>` を編集

## ランタイム生成ファイル (chezmoi 管理外)

```
~/.cache/wallpaper-thumbs/   # wallpaper-thumb.sh が生成する 416x234 JPEG キャッシュ
~/.cache/awww/               # awww-daemon の per-monitor 壁紙キャッシュ
~/.cache/matugen/            # matugen 内部キャッシュ (あれば)
$XDG_RUNTIME_DIR/hypr/       # Hyprland IPC socket (起動毎に異なる UUID)
```

これらは消しても matugen / awww / Hyprland が再生成する。git で管理しない。

## 関連ドキュメント

- [Architecture](./architecture.md) — システム全体像
- [Theming Pipeline](./theming-pipeline.md) — 色生成の詳細フロー
- [Scripts Reference](./scripts.md) — 各スクリプトの責務
