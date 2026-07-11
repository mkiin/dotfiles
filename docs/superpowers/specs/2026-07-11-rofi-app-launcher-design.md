# rofi アプリランチャー（HynDuf 風・matugen 連動）設計

## 目的

現在 quickshell 製のアプリランチャーを rofi へ置き換える。rofi のデフォルト UI は完成度が高く、HynDuf の rofi デザイン（センター配置・ピル型検索バー・壁紙プレビュー・アイコン付きアプリ一覧）をそのまま採用できるため。配色は既存の matugen パイプラインに連動させ、壁紙変更でランチャーの色も追従させる。

参照元デザイン: `~/ghq/github.com/HynDuf/dotfiles/.config/rofi/`（`config.rasi` / `themes/app-launcher.rasi`）。

## 確定した設計判断

| 項目                  | 決定                                                                      | 理由                                                                                                                                                                                                        |
| --------------------- | ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| モード構成            | 3 モード `drun,filebrowser,window`                                        | HynDuf オリジナル（画像）と同一。mode-switcher ボタン 3 つ                                                                                                                                                  |
| 配色パイプライン      | **matugen**                                                               | rofi の elevation 依存デザイン（凹み/浮き）に Material の surface 階層が構造的に合致。既存シェル UI（waybar/wlogout/hyprland/quickshell）と一貫。wallust はフラット 16 色で面の段階を保証できず色崩れリスク |
| 選択行のハイライト    | ニュートラル凹ませ（HynDuf 忠実）                                         | 落ち着いた見た目。色味を抑える                                                                                                                                                                              |
| 壁紙プレビュー        | 起動時に現壁紙を動的注入                                                  | `last_wallpaper` を読み `-theme-str` で注入                                                                                                                                                                 |
| 壁紙配線              | `launch.sh` + `-theme-str`                                                | `post.sh` 無改変。rofi ロジックが `rofi/` に閉じる。起動コマンドの単一情報源                                                                                                                                |
| パッケージ導入        | `packages.nix` で `rofi-wayland` 宣言 + `xdg.configFile` で実ファイル配置 | `programs.rofi`（Nix で設定生成）は使わない。Nerd Font グリフ保全とプロジェクト規約（本体=packages.nix／設定=ディレクトリ）の両立                                                                           |
| quickshell ランチャー | 完全撤去                                                                  | 死んだコードを残さない                                                                                                                                                                                      |
| アイコン / フォント   | Papirus-Dark / JetBrainsMono Nerd Font                                    | 既存導入済み。追加パッケージ不要                                                                                                                                                                            |

## アーキテクチャ（データフロー）

```
壁紙変更 (pyprland wallpapers, 30s 巡回) → post.sh [file]
   ├ matugen image → ~/.config/rofi/themes/colors.rasi 生成（rofi テンプレート新規追加）
   └ last_wallpaper に現壁紙の絶対パスを書く（既存動作・無改変）

起動トリガー (waybar nix アイコン on-click / Super+A)
   → rofi/launch.sh
        wp=$(cat ~/.local/state/hypr/last_wallpaper)
        rofi -show drun -theme app-launcher \
             -theme-str 'inputbar { background-image: url("<wp>", width); }'
             │
             ├ config.rasi        … modi=drun,filebrowser,window + show-icons + icon-theme + font + キーバインド
             ├ app-launcher.rasi  … レイアウト（Nerd Font グリフ埋め込み実ファイル）+ @import "colors.rasi"
             └ themes/colors.rasi … matugen 生成の配色（rofi 起動毎に読む）
```

## 配色マッピング（matugen ロール → rofi トークン）

`matugen/templates/rofi-colors.rasi` が以下を `* { ... }` として出力する。

| rofi トークン    | 用途                                                | matugen ロール                                 |
| ---------------- | --------------------------------------------------- | ---------------------------------------------- |
| `background`     | パネル全体の背景                                    | `surface`                                      |
| `background-alt` | 検索バー/ボタンのピル背景（浮き）                   | `surface_container_high`                       |
| `selected`       | 選択行の背景（凹み）                                | `surface_container_lowest`                     |
| （選択行の文字） |                                                     | `on_surface`                                   |
| `foreground`     | 通常テキスト                                        | `on_surface`                                   |
| `active`         | 起動中/フォーカス中のアクセント                     | `primary`                                      |
| `urgent`         | 緊急ウィンドウ（drun では未使用だが意味的に正しく） | `error_container`（文字 `on_error_container`） |
| `border-color`   | ウィンドウ枠                                        | `outline_variant`                              |

rofi のエントリ色は「状態(normal/active/urgent) × カーソル(normal/selected)」の 6 マスで決まる。app-launcher では実質 `background` / `foreground` / `selected` / `active` の 4 色を意識すればよい。urgent は drun では発生しないが window モード併用時のため意味的に正しくマップする。

## コンポーネントと変更ファイル

### 新規

| ファイル                                                  | 役割                                                                                                                                                              |
| --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `home-manager/desktop/rofi/default.nix`                   | 設定専用モジュール。`xdg.configFile` で下記 `.rasi` / `launch.sh` を配置。`programs.rofi` は使わない                                                              |
| `home-manager/desktop/rofi/config.rasi`                   | `modi: "drun,filebrowser,window"`, `show-icons: true`, `icon-theme: "Papirus-Dark"`, `font`, キーバインド群。HynDuf から流用（実ファイル）                        |
| `home-manager/desktop/rofi/app-launcher.rasi`             | HynDuf のレイアウトをそのまま採用（実ファイル）。**Nerd Font グリフ保全のため Nix 文字列化しない**。先頭の `* { 色定義 }` を削除し `@import "colors.rasi"` に置換 |
| `home-manager/desktop/rofi/launch.sh`                     | `last_wallpaper` を読み `-theme-str` で壁紙注入して rofi 起動。起動コマンドの単一情報源                                                                           |
| `home-manager/desktop/matugen/templates/rofi-colors.rasi` | 上記マッピングで `* { ... }` を出力する matugen テンプレート                                                                                                      |

### 変更

| ファイル                                         | 変更内容                                                                                                                                                              |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `home-manager/desktop/packages.nix`              | `rofi-wayland` を宣言に追記                                                                                                                                           |
| `home-manager/desktop/default.nix`               | `./rofi` を import に追記                                                                                                                                             |
| `home-manager/desktop/matugen/config.toml`       | `[templates.rofi]`（input=テンプレート, output=`~/.config/rofi/themes/colors.rasi`）を追記。post_hook 不要（rofi は起動毎に読む）                                     |
| `home-manager/desktop/matugen/default.nix`       | rofi テンプレートの `xdg.configFile` 配置を 1 行追記＋初回フォールバックのシード（既存 `matugen/fallback/` パターンに倣い activation で `themes/colors.rasi` を置く） |
| `home-manager/desktop/waybar/modules.nix`        | `custom/nix#accent` の `on-click` を `qs ... launcher toggle` → `rofi/launch.sh` 実行へ                                                                               |
| `home-manager/desktop/hyprland/lua/keybinds.lua` | Super+A（21 行目）を `rofi/launch.sh` 実行へ                                                                                                                          |

### 撤去

| ファイル                                                                    | 内容                                                                       |
| --------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| `home-manager/desktop/quickshell/shell/shell.qml`                           | `LauncherWindow {}` インスタンスと `IpcHandler(target: "launcher")` を削除 |
| `home-manager/desktop/quickshell/shell/modules/launcher/LauncherWindow.qml` | ファイル削除                                                               |

他の quickshell モジュール（audio/bluetooth 等）には触れない。

## 実装上の注意点（ハマりどころ）

- **グリフ保全**: `app-launcher.rasi` の検索アイコン・mode-switcher アイコンは Nerd Font 私用領域グリフが `.rasi` に直接埋め込まれている。Nix の文字列リテラルに書くと壊れる恐れがあるため必ず実ファイルとしてコロケーション配置し、`lnk ./app-launcher.rasi` で参照する。
- **colors.rasi の書き込み先**: home-manager は `xdg.configFile` で個別ファイルを symlink する。matugen が書き込む `~/.config/rofi/themes/colors.rasi` は home-manager 管理下に置かない（管理すると store への read-only symlink になり matugen が書けない）。`app-launcher.rasi` からは同ディレクトリ相対で `@import "colors.rasi"`（`../` は使わない）。
- **@import の相対解決**: rofi の `@import` はカレントファイルのディレクトリ基準。`app-launcher.rasi` と `colors.rasi` を同じ `themes/` に置くことで親遡り（`../`）を避ける。
- **初回起動フォールバック**: matugen 未実行の初回ブートでも `@import "colors.rasi"` が失敗しないよう、activation で `themes/colors.rasi` のシードを置く（`matugen/fallback/colors.css` と同型）。
- **webp 壁紙**: cairo/gdk-pixbuf が webp をデコードできない場合、背景プレビューだけ出ない可能性がある（アプリ一覧は正常）。jpg/png 運用中心なら実害小。許容する。
- **rofi-wayland**: Hyprland は Wayland なので `rofi-wayland` を使う。

## スコープ外（今回やらない）

- HynDuf の他 rofi メニュー（powermenu / calc / emojimenu / wifimenu）の移植。必要になれば別スペックで。
- rofi の `run` / `ssh` 等 3 モード以外の追加。
