# ReGreet ログイン画面デザイン設計（Tokyo Night）

## 概要

greetd + ReGreet で実装しているログインマネージャーの見た目を、デフォルトの Adwaita 状態から
Tokyo Night 配色のモダンなダークデザインに作り込む。GTK4 テーマ（Tokyonight-Dark）を基盤に、
少量の GTK4 CSS でログインカード・入力欄・ボタンを整える。

## 背景・制約

- ReGreet は **GTK4 アプリ**で、見た目は **GTK4 CSS** でカスタマイズする（Web CSS のサブセット）。
- グリーターは **ログイン前にシステムの `greeter` ユーザーで起動する**ため、ログイン後ユーザーの
  動的配色（pywal / matugen）を読めない。**配色は固定（Tokyo Night）前提**とする。
- NixOS の `programs.regreet` モジュールを使う。背景画像・CSS は nix store に同梱した静的ファイルになる。
- モジュールは `theme` / `iconTheme` / `cursorTheme` / `font` を指定すると `settings.GTK.*` に自動反映する。
- `extraCss` はパス・文字列どちらも受け付ける（`builtins.readFile ./style.css` で読む）。
- `backdrop-filter` 等の Web CSS 専用プロパティは GTK4 では効かない。半透明 + 影で擬似ガラスに見せる。

## ファイル構成

```
nixos/desktop/greetd/
  default.nix                 # programs.regreet 設定一式
  style.css                   # GTK4 CSS（カード・入力欄・ボタンの作り込み）
  assets/
    2025068-final.png         # 背景画像（配置済み）
```

- CSS は生の `.css` に外出しし、`default.nix` で `extraCss = builtins.readFile ./style.css;` として読む。
- 背景画像はリポジトリに配置済み（`assets/2025068-final.png`）。`settings.background.path` に
  `"${./assets/2025068-final.png}"` で nix store パスとして渡す。

## テーマ／設定（default.nix）

| 項目                              | 値                                                         | 備考                             |
| --------------------------------- | ---------------------------------------------------------- | -------------------------------- |
| GTK theme                         | `Tokyonight-Dark`（`pkgs.tokyonight-gtk-theme`）           | ダーク基盤を任せ CSS を最小化    |
| icon                              | `Papirus-Dark`（`pkgs.papirus-icon-theme`、現状維持）      | デスクトップと統一               |
| cursor                            | `Bibata-Modern-Classic`（`pkgs.bibata-cursors`、現状維持） |                                  |
| font                              | `Inter` 15（`pkgs.inter`）                                 | 現状 12 → ログイン用に 15 へ拡大 |
| background.path                   | `"${./assets/2025068-final.png}"`                          | nix store に同梱                 |
| background.fit                    | `"Cover"`                                                  | 画面いっぱいに比率維持で敷く     |
| GTK.application_prefer_dark_theme | `true`                                                     |                                  |
| appearance.greeting_msg           | `"Welcome back"`                                           | 挨拶メッセージ                   |
| widget.clock.format               | `"%H:%M  %a"`                                              | 上部に時計                       |
| widget.clock.resolution           | `"1s"`                                                     |                                  |
| widget.clock.label_width          | `180`                                                      | レイアウト安定用                 |

## Tokyo Night パレット（CSS 固定値）

| 用途             | HEX       |
| ---------------- | --------- |
| 背景（最背面）   | `#1a1b26` |
| カード           | `#24283b` |
| 入力欄           | `#414868` |
| 本文テキスト     | `#c0caf5` |
| 控えめテキスト   | `#a9b1d6` |
| アクセント（青） | `#7aa2f7` |
| 危険操作（赤）   | `#f7768e` |

## style.css の方針

GTK4 で確実に効くプロパティ（`background-color` / `color` / `border` / `border-radius` /
`padding` / `margin` / `min-width` / `min-height` / `box-shadow` / `font-size`）のみ使用する。

- **最背面（`window.background`）**: 背景画像が透ける前提で、フォールバックの `background-color: #1a1b26`。
- **ログインカード（`box.vertical`）**: 半透明 `alpha(#24283b, 0.86)`・角丸 22px・
  `box-shadow: 0 18px 48px alpha(#000000, 0.45)` でガラス風・padding 28px・境界 `alpha(#c0caf5, 0.14)`。
- **入力欄（`entry`）**: 角丸 12px・min-height 38px・半透明背景 `alpha(#414868, 0.88)`・
  フォーカス時にアクセント色 `#7aa2f7` のボーダー + リング（`box-shadow`）。
- **ボタン（`button`）**: 角丸 12px・hover で明るく。
  `button.suggested-action` = アクセント色背景 + 暗い文字、`button.destructive-action` = 赤背景。
- **時計・挨拶ラベル（`label`）**: 本文色 `#c0caf5`。

実際のセレクタは `regreet --demo` + GTK Inspector で階層を確認しながら調整する余地を残す
（box の入れ子構造は ReGreet のバージョンで変わりうるため）。

## 検証

1. `nix build`（または `nixos-rebuild build`）で評価エラーがないことを確認する。
2. 可能なら `regreet --demo` でログイン画面を起動し、カード・入力欄・ボタン・時計・背景の
   見た目を目視確認する。CSS セレクタが効かない箇所は GTK Inspector で実際の階層を確認して修正する。
3. `nixos-rebuild switch` 後、実機でログアウト → ログイン画面で最終確認する。

## 想定外・非対象（YAGNI）

- pywal / matugen との動的連動はしない（グリーターは動的色を読めないため固定配色）。
- 複数モニタ個別の背景指定や、アニメーション背景・動画背景は対象外。
- ユーザーアバター画像のカスタマイズは対象外。
