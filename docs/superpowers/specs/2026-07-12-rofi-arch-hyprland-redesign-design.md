# rofi レイアウト刷新（arch-hyprland デザイン移植）設計

## 目的

rofi ランチャーの見た目を `binnewbs/arch-hyprland` の rofi デザインへ全面的に寄せる。
具体的には横レイアウト（左に壁紙 imagebox、右にリスト、1000px 幅）と、matugen が
生成する Material You（M3）フルカラートークンを採用する。現状デザインからは
「fuzzy 検索でヒットした文字に下線が引かれる」挙動だけを引き継ぐ。

## 背景（現状と参照元の差分）

- **現状** `home-manager/desktop/rofi/app-launcher.rasi`: 縦レイアウト、600×516px、
  上部にピル型検索バー＋モードボタン、下にリスト。壁紙は inputbar 背景へ注入。
  色は簡易 7 トークン（`background`/`background-alt`/`foreground`/`selected`/`active`/
  `urgent`/`border-color`）。matugen テンプレートは `~/.config/rofi/themes/colors.rasi`
  を生成し、`app-launcher.rasi`・`capture.rasi` が `@import "colors.rasi"` で参照。
- **参照元** `binnewbs/arch-hyprland/.config/rofi/config.rasi`: 横レイアウト、1000px 幅、
  左 imagebox（壁紙の上に inputbar＋mode-switcher を縦に重ねる）＋右 listbox。
  M3 フルトークン（43 個: `primary`/`on-surface`/`secondary-container` 等）を使用。

## 決定事項（確定）

- 壁紙: **arch 通り全面採用**（左 imagebox に壁紙を大きく表示）。
- 寸法: **arch の値をそのまま採用**（width 1000px / lines 8 / border-radius 15px 等）。
- capture メニュー（スクショ/録画の東端縦アイコン列）: **色トークンだけ移行**し
  レイアウトは維持。
- modi: **arch 通り `window,run,drun` の 3 モードのみ**（現状の filebrowser は削除）。
  - `drun`: `.desktop` を読み GUI アプリを名前＋アイコンで一覧・起動（主モード）。
  - `run`: `$PATH` 上の実行バイナリを名前検索して直接起動（アイコンなし）。
  - `window`: 開いているウィンドウ一覧 → 選択でフォーカス切替。
- Colloid アイコン: **rofi ランチャーだけ**に適用（GTK 全体・greetd は Papirus-Dark 据置）。
- fuzzy ヒット下線: arch には highlight 指定が無いため、**`highlight: underline;` を
  明示追加**して保証する。

## 変更ファイル（6 点）

### 1. `home-manager/desktop/matugen/templates/rofi-colors.rasi`

7 トークン → arch の M3 フルセット（43 トークン）へ置換。matugen プレースホルダ
（`{{colors.<name>.default.hex}}`）で各トークンを出力する。出力先
`~/.config/rofi/themes/colors.rasi` は現状の matugen 設定のまま変更しない。

出力トークン一覧（arch の template に一致）:
`primary` / `primary-fixed` / `primary-fixed-dim` / `on-primary` / `on-primary-fixed` /
`on-primary-fixed-variant` / `primary-container` / `on-primary-container` /
`secondary` / `secondary-fixed` / `secondary-fixed-dim` / `on-secondary` /
`on-secondary-fixed` / `on-secondary-fixed-variant` / `secondary-container` /
`on-secondary-container` / `tertiary` / `tertiary-fixed` / `tertiary-fixed-dim` /
`on-tertiary` / `on-tertiary-fixed` / `on-tertiary-fixed-variant` / `tertiary-container` /
`on-tertiary-container` / `error` / `on-error` / `error-container` / `on-error-container` /
`surface` / `on-surface` / `on-surface-variant` / `outline` / `outline-variant` /
`shadow` / `scrim` / `inverse-surface` / `inverse-on-surface` / `inverse-primary` /
`surface-dim` / `surface-bright` / `surface-container-lowest` / `surface-container-low` /
`surface-container` / `surface-container-high` / `surface-container-highest`。

### 2. `home-manager/desktop/matugen/fallback/colors.rasi`

初回ブート時（matugen 未実行で `colors.rasi` が無い）の seed。arch の静的
`colors.rasi`（上記 43 トークンの具体値）へ置換し、テンプレートとトークン集合を一致
させる。これにより新 rasi の `@` 参照が seed 段階でも解決する。

### 3. `home-manager/desktop/rofi/app-launcher.rasi`

arch の横レイアウトへ全面書換。

- **configuration ブロック**:
  - `modi: "window,run,drun";`（filebrowser 削除）
  - `icon-theme: "Colloid";`
  - `display-window` / `display-run` / `display-drun` の 3 モードのみ（グリフは現状の
    アイコン踏襲、`display-filebrowser` は削除）
  - `drun-display-format` / `window-format` は現状維持
- **レイアウト**（arch に準拠）:
  - window: width 1000px / border 2px solid `@secondary-container` / border-radius 15px /
    background `@on-primary-fixed` / location・anchor center / transparency real
  - mainbox: orientation horizontal / children `[ "imagebox", "listbox" ]`
  - imagebox: 壁紙背景（下記 launch.sh が注入）/ orientation vertical /
    children `[ "inputbar", "dummy", "mode-switcher" ]`
  - listbox: orientation vertical / children `[ "message", "listview" ]`
  - inputbar: background `@on-primary` / text `@on-surface` /
    children `[ "textbox-prompt-colon", "entry" ]`
  - mode-switcher: text `@primary-fixed` / button 背景 `@on-primary` /
    button selected 背景 `@primary`・text `@on-secondary`
  - listview: lines 8 / spacing 10px
  - element: text `@on-surface` / selected.normal 背景 `@primary`・text `@on-secondary` /
    active 背景 `@primary` / urgent `@error`
  - element-icon: size 32px
  - message/textbox/error-message: 背景 `@on-primary`
- **fuzzy ヒット下線**: `highlight: underline;` を追加（matched 文字に下線）。

### 4. `home-manager/desktop/rofi/capture.rasi`

色トークン参照のみ張替（レイアウトは変更しない）:
`@background` → `@surface` / `@foreground` → `@on-surface` / `@active` → `@primary`。

### 5. `home-manager/desktop/rofi/launch.sh`

壁紙注入先を変更。現状は `-theme-str 'inputbar { background-image: url("$wp", width); }'`。
これを imagebox 対象・height スケールへ:
`-theme-str 'imagebox { background-image: url("$wp", height); }'`。
壁紙パスは現状通り `$XDG_STATE_HOME/hypr/last_wallpaper`（無ければ注入せず、imagebox は
背景色のみでグレースフルに表示）。`-show drun` の初期モードは維持。

### 6. `home-manager/desktop/packages.nix`

`colloid-icon-theme` を rofi 付近に追加（規約: パッケージ本体は集約点で宣言）。これで
rofi の XDG データパス検索に Colloid が載り、`icon-theme: "Colloid"` が解決する。

## 変更しないもの

- `home-manager/desktop/rofi/config.rasi`（グローバルの keybind・既定 config）。
- `home-manager/desktop/gtk/default.nix`（GTK は Papirus-Dark 据置）。
- `nixos/desktop/greetd`（Papirus-Dark 据置）。
- `home-manager/desktop/rofi/default.nix`（配線は既存のまま）。

## 検証

- `nix run .#build`（nixos 構成ビルド）を通す。
- `nix run .#fmt -- --fail-on-change`（treefmt / deadnix）を通す。
- 実機反映は `nix run .#switch`。反映後に以下を目視確認:
  - ランチャーが横レイアウトで左に壁紙 imagebox が出る。
  - mode-switcher で window / run / drun を切替できる。
  - drun アイコンが Colloid で描画される。
  - fuzzy 検索でヒット文字に下線が付く。
  - capture（スクショ/録画）メニューが従来レイアウトのまま色は新トークンで表示。
