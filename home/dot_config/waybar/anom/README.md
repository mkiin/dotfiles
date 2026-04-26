# anom-style waybar (アーカイブ)

このフォルダは [anom-dotfiles](https://github.com/atif-1402/anom-dots) の Material Pills テーマを当環境に移植したスナップショット。
現在の `~/.config/waybar/{config.jsonc,style.css}` がこの内容と一致している (active = anom)。

別テーマ (noro 等) に切り替えた時の **戻し方** は:

1. このフォルダの `config.jsonc` と `style.css` を `~/.config/waybar/` 直下にコピー上書き
2. `pkill -x waybar && uwsm app -- waybar &; disown`

## 依存関係

| 何が | どこ |
|---|---|
| matugen テンプレート (anom 用 colors.css 生成) | `~/.config/matugen/config.toml` の `[templates.waybar-anom]` セクション。出力先: `~/.config/waybar/colors.css` |
| カスタムフォント (Claude ロゴグリフ U+F1B00 - 現状未参照) | `~/.local/share/fonts/ClaudeSymbols.ttf` |
| メインフォント | JetBrainsMono Nerd Font (`/usr/share/fonts/TTF/`) |
| アイコン: ghostty, Nvim, VSCode 等 | window-rewrite で class/title 正規表現マッチ |

## anom 元実装との差分

| | anom 公式 | この環境 |
|---|---|---|
| `custom/apps` クリック | `~/.config/rofi/scripts/menu.sh` | `walker` (no args) |
| `network` クリック | `omarchy-launch-wifi` | コメントアウト (TODO) |
| `mpris` スクロール | `~/.config/hypr/scripts/volume.sh` | コメントアウト (TODO) |
| `pulseaudio` クリック | `pulsemixer` | コメントアウト (TODO) |
| `custom/screenrecording-indicator` | あり (orphan) | 削除 |
| ws 番号フォーマット | `{windows}` (window-rewrite) | 同左 |
| `title<*.VSCode.*>` / `class<.*code.*>` | あり (誤マッチの温床) | 削除 |
| Nvim title マッチ | `title<.*nvim ~.*>` + `title<.*vim.*>` | `title<.*Nvim.*>` 1 本 (neovim 専用アイコン使用) |

詳細は `docs/waybar-anom-analysis.md` (もし作るなら) や `hyprland-config-sample/anom-dotfiles/WAYBAR_ANALYSIS.md` を参照。
