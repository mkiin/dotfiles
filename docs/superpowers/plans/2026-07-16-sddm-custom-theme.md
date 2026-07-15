# SDDM カスタムテーマ実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** sddm-astronaut-theme の QML を流用し、login.png 壁紙と matugen 生成配色を焼き込んだ custom.conf でログイン画面を構築する。

**Architecture:** matugen プレースホルダ入りの conf テンプレートを `home-manager/desktop/matugen/templates/` に置き、`pkgs.sddm-astronaut.overrideAttrs` の postInstall でビルド時に matugen を実行して `Themes/custom.conf` を生成、`metadata.desktop` を書き換える。

**Tech Stack:** Nix (NixOS module / overrideAttrs), matugen, sddm-astronaut-theme

**Spec:** `docs/superpowers/specs/2026-07-16-sddm-theme-layout-design.md`

## Global Constraints

- パッケージ宣言は集約 `packages.nix` のみ。ただし配送目的の `environment.systemPackages`（テーマ・カーソル）は既存の例外に従う
- `../` で遡るパス参照禁止。リポジトリ横断参照は `"${inputs.self}/..."`（ビルド入力のため。`dotfilesDir`/`lnk` は実行時 symlink 用で不可）
- コメントは非自明な理由のみ 1〜2 行
- 検証は `nix run .#build` + `nix run .#fmt -- --fail-on-change` を必ず通す
- `nixos/desktop/sddm/default.nix` の既存設定（weston.ini による DP-2 単独表示、Bibata カーソル、`GreeterEnvironment=XCURSOR_PATH=...`、`fonts.packages`）は変更しない

---

### Task 1: matugen テンプレート `sddm-theme.conf` の作成

**Files:**

- Create: `home-manager/desktop/matugen/templates/sddm-theme.conf`

**Interfaces:**

- Produces: matugen `{{colors.<token>.default.hex}}` プレースホルダ入りの astronaut conf 全体。Task 2 の derivation が matugen の `input_path` としてこのファイルを読む。`Background="Backgrounds/login.png"` は Task 2 がコピーする壁紙の相対パスと一致していること。

- [ ] **Step 1: テンプレートファイルを作成**

`home-manager/desktop/matugen/templates/sddm-theme.conf` を以下の内容で作成する（astronaut.conf のキーセットに準拠。色はすべて matugen プレースホルダ）:

```ini
[General]
ScreenWidth="2560"
ScreenHeight="1440"
ScreenPadding=""
Font="Open Sans"
FontSize=""
KeyboardSize="0.4"
RoundCorners="20"
Locale="en_US"
HourFormat="HH:mm"
DateFormat="dddd, MMMM d"
HeaderText=""

BackgroundPlaceholder=""
Background="Backgrounds/login.png"
BackgroundSpeed=""
PauseBackground=""
DimBackground="0.2"
CropBackground="true"
BackgroundHorizontalAlignment="center"
BackgroundVerticalAlignment="center"

HeaderTextColor="{{colors.on_surface.default.hex}}"
DateTextColor="{{colors.on_surface.default.hex}}"
TimeTextColor="{{colors.on_surface.default.hex}}"

FormBackgroundColor="{{colors.surface.default.hex}}"
BackgroundColor="{{colors.surface.default.hex}}"
DimBackgroundColor="{{colors.scrim.default.hex}}"

LoginFieldBackgroundColor="{{colors.surface_container_high.default.hex}}"
PasswordFieldBackgroundColor="{{colors.surface_container_high.default.hex}}"
LoginFieldTextColor="{{colors.on_surface.default.hex}}"
PasswordFieldTextColor="{{colors.on_surface.default.hex}}"
UserIconColor="{{colors.on_surface.default.hex}}"
PasswordIconColor="{{colors.on_surface.default.hex}}"

PlaceholderTextColor="{{colors.on_surface_variant.default.hex}}"
WarningColor="{{colors.error.default.hex}}"

LoginButtonTextColor="{{colors.on_primary.default.hex}}"
LoginButtonBackgroundColor="{{colors.primary.default.hex}}"
SystemButtonsIconsColor="{{colors.on_surface.default.hex}}"
SessionButtonTextColor="{{colors.on_surface.default.hex}}"
VirtualKeyboardButtonTextColor="{{colors.on_surface.default.hex}}"

DropdownTextColor="{{colors.on_surface.default.hex}}"
DropdownSelectedBackgroundColor="{{colors.primary_container.default.hex}}"
DropdownBackgroundColor="{{colors.surface_container.default.hex}}"

HighlightTextColor="{{colors.on_primary_container.default.hex}}"
HighlightBackgroundColor="{{colors.primary_container.default.hex}}"
HighlightBorderColor="{{colors.primary.default.hex}}"

HoverUserIconColor="{{colors.primary.default.hex}}"
HoverPasswordIconColor="{{colors.primary.default.hex}}"
HoverSystemButtonsIconsColor="{{colors.primary.default.hex}}"
HoverSessionButtonTextColor="{{colors.primary.default.hex}}"
HoverVirtualKeyboardButtonTextColor="{{colors.primary.default.hex}}"

PartialBlur="false"
FullBlur=""
BlurMax=""
Blur=""

HaveFormBackground="false"
FormPosition="center"

VirtualKeyboardPosition="center"

HideVirtualKeyboard="true"
HideSystemButtons="false"
HideLoginButton="false"

UseRealName="true"
ForceLastUser="true"
PasswordFocus="true"
HideCompletePassword="true"
AllowEmptyPassword="false"
BypassSystemButtonsChecks="false"
RightToLeftLayout="false"

TranslatePlaceholderUsername=""
TranslatePlaceholderPassword=""
TranslateLogin=""
TranslateLoginFailedWarning=""
TranslateCapslockWarning=""
TranslateSuspend=""
TranslateHibernate=""
TranslateReboot=""
TranslateShutdown=""
TranslateSessionSelection=""
TranslateVirtualKeyboardButtonOn=""
TranslateVirtualKeyboardButtonOff=""
```

- [ ] **Step 2: matugen 単体でレンダリングできることを検証（失敗→成功の確認）**

リポジトリ直下で実行:

```bash
ROOT="$(git rev-parse --show-toplevel)"
TMP=$(mktemp -d)
cat > "$TMP/config.toml" <<EOF
[templates.sddm]
input_path = '$ROOT/home-manager/desktop/matugen/templates/sddm-theme.conf'
output_path = '$TMP/custom.conf'
EOF
matugen image "$ROOT/images/login/login.png" --config "$TMP/config.toml" --mode dark
grep -c '{{' "$TMP/custom.conf" || echo "OK: プレースホルダ残りなし"
grep -E '^(TimeTextColor|LoginButtonBackgroundColor)=' "$TMP/custom.conf"
```

Expected: matugen がエラーなく終了し、`{{` が 1 件も残らず（`OK: プレースホルダ残りなし`）、色キーに `"#xxxxxx"` 形式の実値が入っている。プレースホルダの綴りミスがあれば matugen がレンダリングエラーを出すか `{{` が残るのでここで検出する。

- [ ] **Step 3: コミット**

```bash
git add home-manager/desktop/matugen/templates/sddm-theme.conf
git commit -m "feat(sddm): astronaut conf の matugen テンプレートを追加"
```

---

### Task 2: テーマ derivation の差し替え（overrideAttrs）

**Files:**

- Modify: `nixos/desktop/sddm/default.nix`

**Interfaces:**

- Consumes: Task 1 の `sddm-theme.conf`（`"${inputs.self}/home-manager/desktop/matugen/templates/sddm-theme.conf"` で参照）、`"${inputs.self}/images/login/login.png"`
- Produces: `$out/share/sddm/themes/sddm-astronaut-theme/` に `Backgrounds/login.png`・`Themes/custom.conf` を持ち、`metadata.desktop` が custom.conf を指すテーマパッケージ

- [ ] **Step 1: default.nix の theme 定義を書き換え**

`nixos/desktop/sddm/default.nix` の先頭部分（`{ lib, pkgs, ... }:` から `westonIni` の手前まで）を以下に置き換える。`westonIni` 以降と module 本体（`services.displayManager.sddm`、`environment.systemPackages`、`fonts.packages`）は現状のまま変更しない:

```nix
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  wallpaper = "${inputs.self}/images/login/login.png";
  confTemplate = "${inputs.self}/home-manager/desktop/matugen/templates/sddm-theme.conf";

  theme = pkgs.sddm-astronaut.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.matugen ];
    # 壁紙焼き込みと matugen による custom.conf 生成。モード/スキームは
    # デスクトップ側 matugen (dark, デフォルトスキーム) と揃える
    postInstall = (old.postInstall or "") + ''
      themeDir=$out/share/sddm/themes/sddm-astronaut-theme
      chmod -R u+w "$themeDir"
      cp ${wallpaper} "$themeDir/Backgrounds/login.png"

      printf '%s\n' \
        '[templates.sddm]' \
        "input_path = '${confTemplate}'" \
        "output_path = '$themeDir/Themes/custom.conf'" \
        > matugen-build.toml
      HOME=$TMPDIR matugen image ${wallpaper} --config matugen-build.toml --mode dark

      sed -i 's|^ConfigFile=.*|ConfigFile=Themes/custom.conf|' "$themeDir/metadata.desktop"
    '';
  });
```

既存の `theme = pkgs.sddm-astronaut.override { embeddedTheme = "black_hole"; };` は削除する（`override` は使わない。custom.conf が唯一の設定になるため）。

- [ ] **Step 2: ビルドして検証**

```bash
nix run .#build
nix run .#fmt -- --fail-on-change
```

Expected: 両方成功。

- [ ] **Step 3: 成果物の中身を検証**

```bash
sys=$(nix build .#nixosConfigurations.nixos.config.system.build.toplevel --no-link --print-out-paths)
themeDir="$sys/sw/share/sddm/themes/sddm-astronaut-theme"
grep '^ConfigFile=' "$themeDir/metadata.desktop"
ls "$themeDir/Backgrounds/login.png"
grep -E '^(Background|FormPosition|Locale|DateFormat|HideVirtualKeyboard)=' "$themeDir/Themes/custom.conf"
grep -E '^TimeTextColor="#' "$themeDir/Themes/custom.conf"
grep -c '{{' "$themeDir/Themes/custom.conf" || echo "OK"
```

Expected:

- `ConfigFile=Themes/custom.conf`
- `Backgrounds/login.png` が存在
- `Background="Backgrounds/login.png"` / `FormPosition="center"` / `Locale="en_US"` / `DateFormat="dddd, MMMM d"` / `HideVirtualKeyboard="true"`
- `TimeTextColor` が `"#xxxxxx"` の実値
- `{{` の残りゼロ（`OK`）

- [ ] **Step 4: コミット**

```bash
git add nixos/desktop/sddm/default.nix
git commit -m "feat(sddm): login.png と matugen 配色を焼き込む custom.conf テーマに差し替え"
```

---

### Task 3: 目視確認と実機反映

**Files:** なし（検証のみ。調整が必要なら Task 1 のテンプレート値を変更して Task 2 の Step 2-3 を再実行）

**Interfaces:**

- Consumes: Task 2 のテーマパッケージ

- [ ] **Step 1: test-mode でレイアウト目視（ログアウト不要）**

```bash
sys=$(nix build .#nixosConfigurations.nixos.config.system.build.toplevel --no-link --print-out-paths)
sddm-greeter-qt6 --test-mode --theme "$sys/sw/share/sddm/themes/sddm-astronaut-theme"
```

確認項目: login.png が背景に出る / フォームが中央 / ブラー・フォーム背景なし / 日付が `Wednesday, July 16` 形式 / 仮想キーボードボタンなし / 電源ボタンとセッション選択あり / 文字色が壁紙と調和。

- [ ] **Step 2: 調整（必要な場合のみ）**

可読性が低ければ `DimBackground`（0.0-1.0）、色の役割が合わなければ該当プレースホルダを Task 1 のテンプレートで変更し、`nix run .#build` から再確認する。

- [ ] **Step 3: 実機反映**

ユーザーが `nix run .#switch` を実行し、ログアウトしてログイン画面を確認する（DP-2 単独表示と Bibata カーソルの継続確認も含む）。

- [ ] **Step 4: 調整があればコミット**

```bash
git add -A home-manager/desktop/matugen/templates/sddm-theme.conf
git commit -m "fix(sddm): 実機確認に基づく配色/減光の調整"
```
