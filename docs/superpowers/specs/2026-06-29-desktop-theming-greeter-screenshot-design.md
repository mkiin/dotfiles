# デスクトップ環境4課題の修正 設計

## 目的

NixOS / Hyprland 環境で発生している以下4つの独立した不具合・改善を、二層構成
（home-manager 層 = ログイン後セッション / NixOS システム層 = ログイン画面）で解決する。

1. Quickshell でアイコンが紫黒のフォールバックプレースホルダ表示になる
2. マウスカーソルが Hyprland 組み込みの雫デザインのまま
3. SDDM ログイン画面の設定が反映されない（Wayland/Hyprland との相性問題）
4. hyprshot でスクリーンショット選択中に Esc を押すと撮影されてしまう

## アーキテクチャ

外観テーマは「ログイン後セッション」と「ログイン画面(greeter)」で別ユーザー・別レイヤー
となるため、二層で設定する。

- **home-manager 層** (`home-manager/desktop/`): ログイン後セッションの外観
- **NixOS システム層** (`nixos/desktop/`): greeter（`greeter` システムユーザー）の外観 +
  ログインスタック

既存の機能別ディレクトリモジュールパターン（例: `mouse/`, `matugen/`, `nixos/desktop/vesktop/`）
に従い、関心ごとに1ディレクトリを追加する。

---

## 課題1: Quickshell アイコンの紫黒フォールバック解消

### 原因

`papirus-icon-theme` は `packages.nix` で導入済みだが、GTK 側のアイコンテーマ名が未設定。
`input.lua` で `QT_QPA_PLATFORMTHEME=gtk3` を指定しているため Qt/Quickshell は GTK の
`gtk-icon-theme-name` を参照するが、それが空のためアイコンを解決できずプレースホルダ表示になる。

### 対応: 新規 `home-manager/desktop/gtk/default.nix`

```nix
{ pkgs, ... }:
{
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };
}
```

`qt.enable` + `qt.platformTheme.name = "gtk"` により、`input.lua` の
`QT_QPA_PLATFORMTHEME=gtk3` ハードコードを宣言的設定へ置き換える。

---

## 課題2: マウスカーソル（雫 → Bibata-Modern-Classic）

### 原因

`input.lua` で `phinger-cursors-light` を環境変数指定しているが、カーソルパッケージが
未インストールでテーマが存在しないため、Hyprland 組み込みの雫カーソルにフォールバックする。

### 対応: 新規 `home-manager/desktop/cursor/default.nix`

```nix
{ pkgs, ... }:
{
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    hyprcursor.enable = true;
  };
}
```

`home.pointerCursor` はパッケージ導入と `XCURSOR_THEME`/`XCURSOR_SIZE`/GTK カーソル/
hyprcursor を一括で設定する。サイズは現状の 40 から標準的な 24 へ変更する。

---

## 課題3: ログイン画面（SDDM → greetd + regreet）

### 原因 / 方針

SDDM はテーマ未指定かつ Wayland/Hyprland との相性問題がある。NixOS 標準の
`programs.regreet` + `services.greetd` に置換する。regreet は Wayland-native な GTK ベース
greeter で、`programs.regreet.enable = true` がデフォルトで cage にラップして greetd を
起動する（`dbus-run-session cage -- regreet`）。

`theme`/`iconTheme`/`cursorTheme` で指定したパッケージは regreet モジュールが自動で
greeter 環境（`environment.systemPackages`）へ投入する。これにより二層構成のシステム層が
成立し、ログイン画面でも home 層と同じ Bibata カーソル / Papirus アイコンが適用される。

### 対応: `nixos/desktop/display-manager/` → `nixos/desktop/greetd/` にリネーム

`greetd/default.nix`（旧 SDDM 設定を全面置換）:

```nix
{ pkgs, ... }:
{
  services.greetd.enable = true;

  programs.regreet = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
    };
    font = {
      name = "Inter";
      size = 12;
    };
    # settings.background = { path = ...; fit = "Cover"; };  # 壁紙は任意（後日追加可）
  };
}
```

`nixos/desktop/default.nix` の `imports` を `./display-manager` → `./greetd` に変更する。

---

## 課題4: hyprshot Esc キャンセル

### 原因

`screenshot.sh` の `hyprshot -m region/window` は内部 slurp で Esc を押しても撮影を続行する。
さらに `|| true` でエラーを握りつぶしている。

### 対応: `home-manager/desktop/hyprland/scripts/screenshot.sh` を slurp + grim ベースに書換

選択キャンセルを明示検出し、キャンセル時は通知も出さず静かに終了する。

- **region**: `geom=$(slurp) || exit 0` → 空文字でも `exit 0`。`grim -g "$geom"` で撮影
- **window**: `hyprctl clients -j` のウィンドウ矩形を `slurp` に渡してウィンドウ選択。
  Esc / 空選択でキャンセル → 静かに終了
- **output**: 選択不要なので `grim` で直接撮影
- 撮影成功時のみ `notify-send` で通知

依存パッケージの変更（`packages.nix`）:

- 追加: `grim`, `slurp`
- 撤去: `hyprshot`（他スクリプトで未使用を確認済み。`record.sh` は gpu-screen-recorder を使用）

---

## 変更ファイル一覧

| 層     | パス                                                       | 操作                                          |
| ------ | ---------------------------------------------------------- | --------------------------------------------- |
| home   | `home-manager/desktop/gtk/default.nix`                     | 新規（iconTheme + qt）                        |
| home   | `home-manager/desktop/cursor/default.nix`                  | 新規（pointerCursor = Bibata）                |
| home   | `home-manager/desktop/default.nix`                         | `imports` に `./gtk` `./cursor` 追加          |
| home   | `home-manager/desktop/packages.nix`                        | bibata-cursors/grim/slurp 追加、hyprshot 撤去 |
| home   | `home-manager/desktop/hyprland/lua/input.lua`              | カーソル env 4行 + QT_QPA 行を削除            |
| home   | `home-manager/desktop/hyprland/scripts/screenshot.sh`      | slurp+grim ベースに書換                       |
| system | `nixos/desktop/display-manager/` → `nixos/desktop/greetd/` | リネーム + SDDM→greetd+regreet 置換           |
| system | `nixos/desktop/default.nix`                                | `imports` を `./display-manager` → `./greetd` |

## 設計判断

- **二層構成**: greeter は `greeter` システムユーザーで起動するため home-manager のテーマが
  効かない。ログイン画面の外観は `programs.regreet` のテーマオプション（システム層）で別途指定する。
- **テーマは home 層が慣例**: 参考リポジトリ（asa1984, takeokunn）でも gtk/icon/cursor は
  home-manager 層に置かれている。本設計もこれに従う。
- **gtk/ と cursor/ を分離**: `gtk.iconTheme` は gtk のサブオプション、`home.pointerCursor` は
  トップレベルオプションで関心が異なるため、ディレクトリを分ける。
- **regreet 採用**: tuigreet（TUI）も候補だったが、グラフィカルなログイン画面を優先し regreet を採用。
  NixOS 公式モジュールがあり cage ラップを自動構成するため実装は確実。
- **hyprshot 撤去**: Esc キャンセルを確実に制御するため、選択を自前で slurp に任せ grim で撮影する。
  これにより hyprshot 依存が不要になる。

## 検証

- `nixos-rebuild`（または既存のビルドフロー）でビルドが成功すること
- 再起動後、regreet のログイン画面が表示され、Bibata カーソル / Papirus アイコンが適用されること
- ログイン後、Quickshell のアイコンがプレースホルダでなく正しく表示されること
- マウスカーソルが Bibata になっていること
- `Super+P` / `Super+Shift+P` でスクショ選択中に Esc を押すと、撮影されず通知も出ずに終了すること
- 正常に範囲選択した場合は撮影され通知が出ること

## スコープ外（YAGNI）

- regreet の壁紙画像 / カスタム CSS（`settings.background`, `extraCss`）— 後日追加可
- GTK ウィジェットテーマ（`gtk.theme`）— アイコン解決には不要なため今回は設定しない
- カーソルサイズの HiDPI 個別調整
