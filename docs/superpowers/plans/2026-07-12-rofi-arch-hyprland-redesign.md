# rofi arch-hyprland デザイン移植 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** rofi ランチャーを `binnewbs/arch-hyprland` の横レイアウト＋M3 フルカラートークンへ全面移植し、fuzzy ヒット文字の下線だけ現状から引き継ぐ。

**Architecture:** matugen テンプレートが生成する色トークンを 7 個から M3 フル 43 個へ拡張し、`app-launcher.rasi` を arch の横レイアウト（左 imagebox＋右 listbox）へ書き換える。`capture.rasi` は色参照のみ張替、`launch.sh` は壁紙注入先を imagebox へ移す。Colloid アイコンは集約 `packages.nix` で導入しランチャーのみ適用。

**Tech Stack:** Nix (home-manager), rofi rasi テーマ, matugen テンプレート, bash。

## Global Constraints

- パッケージ本体は集約 `home-manager/desktop/packages.nix` にのみ宣言する（機能ディレクトリの `default.nix` へ直書き禁止）。
- `../` で親を遡る相対パス参照を書かない。
- コメントは「なぜ」を 1〜2 行のみ。逐条コメント禁止。
- Nix 変更後は `nix run .#fmt -- --fail-on-change` と `nix run .#build` を通す。
- matugen 出力先は現状のまま `~/.config/rofi/themes/colors.rasi`（`config.toml` は変更しない）。
- 色トークンは arch-hyprland のフルセット（43 個）を採用。
- rofi ランチャーのみ Colloid、GTK 全体・greetd は Papirus-Dark 据置。

---

### Task 1: 色トークンを M3 フルセットへ拡張（matugen テンプレート＋フォールバック）

**Files:**

- Modify: `home-manager/desktop/matugen/templates/rofi-colors.rasi`（全置換）
- Modify: `home-manager/desktop/matugen/fallback/colors.rasi`（全置換）

**Interfaces:**

- Consumes: なし
- Produces: `~/.config/rofi/themes/colors.rasi` に以下 43 トークンを出力（後続タスクの rasi が `@` 参照する）:
  `primary` `primary-fixed` `primary-fixed-dim` `on-primary` `on-primary-fixed` `on-primary-fixed-variant` `primary-container` `on-primary-container` `secondary` `secondary-fixed` `secondary-fixed-dim` `on-secondary` `on-secondary-fixed` `on-secondary-fixed-variant` `secondary-container` `on-secondary-container` `tertiary` `tertiary-fixed` `tertiary-fixed-dim` `on-tertiary` `on-tertiary-fixed` `on-tertiary-fixed-variant` `tertiary-container` `on-tertiary-container` `error` `on-error` `error-container` `on-error-container` `surface` `on-surface` `on-surface-variant` `outline` `outline-variant` `shadow` `scrim` `inverse-surface` `inverse-on-surface` `inverse-primary` `surface-dim` `surface-bright` `surface-container-lowest` `surface-container-low` `surface-container` `surface-container-high` `surface-container-highest`

- [ ] **Step 1: matugen テンプレートを全置換**

`home-manager/desktop/matugen/templates/rofi-colors.rasi` の内容を以下に置き換える:

```rasi
* {
    primary: {{colors.primary.default.hex}};
    primary-fixed: {{colors.primary_fixed.default.hex}};
    primary-fixed-dim: {{colors.primary_fixed_dim.default.hex}};
    on-primary: {{colors.on_primary.default.hex}};
    on-primary-fixed: {{colors.on_primary_fixed.default.hex}};
    on-primary-fixed-variant: {{colors.on_primary_fixed_variant.default.hex}};
    primary-container: {{colors.primary_container.default.hex}};
    on-primary-container: {{colors.on_primary_container.default.hex}};
    secondary: {{colors.secondary.default.hex}};
    secondary-fixed: {{colors.secondary_fixed.default.hex}};
    secondary-fixed-dim: {{colors.secondary_fixed_dim.default.hex}};
    on-secondary: {{colors.on_secondary.default.hex}};
    on-secondary-fixed: {{colors.on_secondary_fixed.default.hex}};
    on-secondary-fixed-variant: {{colors.on_secondary_fixed_variant.default.hex}};
    secondary-container: {{colors.secondary_container.default.hex}};
    on-secondary-container: {{colors.on_secondary_container.default.hex}};
    tertiary: {{colors.tertiary.default.hex}};
    tertiary-fixed: {{colors.tertiary_fixed.default.hex}};
    tertiary-fixed-dim: {{colors.tertiary_fixed_dim.default.hex}};
    on-tertiary: {{colors.on_tertiary.default.hex}};
    on-tertiary-fixed: {{colors.on_tertiary_fixed.default.hex}};
    on-tertiary-fixed-variant: {{colors.on_tertiary_fixed_variant.default.hex}};
    tertiary-container: {{colors.tertiary_container.default.hex}};
    on-tertiary-container: {{colors.on_tertiary_container.default.hex}};
    error: {{colors.error.default.hex}};
    on-error: {{colors.on_error.default.hex}};
    error-container: {{colors.error_container.default.hex}};
    on-error-container: {{colors.on_error_container.default.hex}};
    surface: {{colors.surface.default.hex}};
    on-surface: {{colors.on_surface.default.hex}};
    on-surface-variant: {{colors.on_surface_variant.default.hex}};
    outline: {{colors.outline.default.hex}};
    outline-variant: {{colors.outline_variant.default.hex}};
    shadow: {{colors.shadow.default.hex}};
    scrim: {{colors.scrim.default.hex}};
    inverse-surface: {{colors.inverse_surface.default.hex}};
    inverse-on-surface: {{colors.inverse_on_surface.default.hex}};
    inverse-primary: {{colors.inverse_primary.default.hex}};
    surface-dim: {{colors.surface_dim.default.hex}};
    surface-bright: {{colors.surface_bright.default.hex}};
    surface-container-lowest: {{colors.surface_container_lowest.default.hex}};
    surface-container-low: {{colors.surface_container_low.default.hex}};
    surface-container: {{colors.surface_container.default.hex}};
    surface-container-high: {{colors.surface_container_high.default.hex}};
    surface-container-highest: {{colors.surface_container_highest.default.hex}};
}
```

- [ ] **Step 2: フォールバック seed を全置換**

`home-manager/desktop/matugen/fallback/colors.rasi` の内容を以下に置き換える（テンプレートとトークン集合を一致させる静的値）:

```rasi
* {
    primary: #80d4dc;
    primary-fixed: #9df0f8;
    primary-fixed-dim: #80d4dc;
    on-primary: #00363a;
    on-primary-fixed: #002022;
    on-primary-fixed-variant: #004f54;
    primary-container: #004f54;
    on-primary-container: #9df0f8;
    secondary: #b1cbce;
    secondary-fixed: #cce8ea;
    secondary-fixed-dim: #b1cbce;
    on-secondary: #1b3437;
    on-secondary-fixed: #051f21;
    on-secondary-fixed-variant: #324b4d;
    secondary-container: #324b4d;
    on-secondary-container: #cce8ea;
    tertiary: #b7c7ea;
    tertiary-fixed: #d7e2ff;
    tertiary-fixed-dim: #b7c7ea;
    on-tertiary: #21304c;
    on-tertiary-fixed: #0a1b36;
    on-tertiary-fixed-variant: #384764;
    tertiary-container: #384764;
    on-tertiary-container: #d7e2ff;
    error: #ffb4ab;
    on-error: #690005;
    error-container: #93000a;
    on-error-container: #ffdad6;
    surface: #0e1415;
    on-surface: #dee4e4;
    on-surface-variant: #bec8c9;
    outline: #899393;
    outline-variant: #3f4849;
    shadow: #000000;
    scrim: #000000;
    inverse-surface: #dee4e4;
    inverse-on-surface: #2b3232;
    inverse-primary: #006970;
    surface-dim: #0e1415;
    surface-bright: #343a3b;
    surface-container-lowest: #090f10;
    surface-container-low: #161d1d;
    surface-container: #1a2121;
    surface-container-high: #252b2c;
    surface-container-highest: #303636;
}
```

- [ ] **Step 3: フォーマット確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なしで PASS（rasi は treefmt 対象外なら no-op。差分が出たらフォーマッタ適用後の状態でコミットする）

- [ ] **Step 4: コミット**

```bash
git add home-manager/desktop/matugen/templates/rofi-colors.rasi home-manager/desktop/matugen/fallback/colors.rasi
git commit -m "feat(rofi): 色トークンを arch-hyprland の M3 フルセットへ拡張"
```

---

### Task 2: capture.rasi の色参照を新トークンへ張替

**Files:**

- Modify: `home-manager/desktop/rofi/capture.rasi`

**Interfaces:**

- Consumes: Task 1 が出力する `@surface` `@on-surface` `@primary`
- Produces: なし（capture メニューのレイアウトは不変）

- [ ] **Step 1: 3 箇所のトークン参照を張替**

`home-manager/desktop/rofi/capture.rasi` で以下を置換する（レイアウト・寸法は変更しない）:

- `background-color: @background;`（`*` ブロックと `window` ブロックの 2 箇所）→ `background-color: @surface;`
- `text-color:       @foreground;`（`*` ブロックと `element` ブロックの 2 箇所）→ `text-color:       @on-surface;`
- `text-color:   @active;`（`element selected` ブロック）→ `text-color:   @primary;`
- `border-color: @active;`（`element selected` ブロック）→ `border-color: @primary;`

置換後の該当ブロックは以下になる:

```rasi
* {
    background-color: @surface;
    text-color:       @on-surface;
}

window {
    transparency:     "real";
    border-radius:    12px;
    location:         east;
    anchor:           east;
    width:            100px;
    x-offset:         -15px;
    y-offset:         0px;
    background-color: @surface;
}
```

```rasi
element {
    text-color:       @on-surface;
    orientation:      vertical;
    border-radius:    8px;
    background-color: transparent;
}
```

```rasi
element selected {
    text-color:   @primary;
    border-radius: 8px;
    border:       1px;
    border-color: @primary;
}
```

- [ ] **Step 2: フォーマット確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: PASS

- [ ] **Step 3: コミット**

```bash
git add home-manager/desktop/rofi/capture.rasi
git commit -m "fix(rofi): capture メニューの色参照を M3 トークンへ張替"
```

---

### Task 3: Colloid 導入＋app-launcher.rasi を arch 横レイアウトへ全面書換

**Files:**

- Modify: `home-manager/desktop/packages.nix`
- Modify: `home-manager/desktop/rofi/app-launcher.rasi`（全置換）

**Interfaces:**

- Consumes: Task 1 の M3 トークン（`@on-primary-fixed` `@secondary-container` `@on-primary` `@on-surface` `@primary` `@on-secondary` `@primary-fixed` `@error`）
- Produces: imagebox セレクタ（Task 4 の `launch.sh` が `-theme-str` で背景画像を注入する対象）

- [ ] **Step 1: packages.nix に Colloid を追加**

`home-manager/desktop/packages.nix` の `rofi` の直後に `colloid-icon-theme` を追加する:

```nix
    wlogout
    rofi
    # rofi ランチャー専用アイコンテーマ(icon-theme: "Colloid")。GTK 全体は Papirus 据置。
    colloid-icon-theme
    socat
```

- [ ] **Step 2: app-launcher.rasi を全置換**

`home-manager/desktop/rofi/app-launcher.rasi` の内容を以下に置き換える:

```rasi
/*****----- Configuration -----*****/
configuration {
    modi:                       "window,run,drun";
    show-icons:                 true;
    icon-theme:                 "Colloid";
    display-drun:               " ";
    display-run:                " ";
    display-window:             " ";
    drun-display-format:        "{name}";
    window-format:              "{w} · {c} · {t}";
}

/*****----- Global Properties -----*****/
@import "colors.rasi"

* {
    font:                        "JetBrains Mono Nerd Font 11";
    highlight:                   underline;
}

/*****----- Main Window -----*****/
window {
    transparency:                "real";
    location:                    center;
    anchor:                      center;
    fullscreen:                  false;
    width:                       1000px;
    x-offset:                    0px;
    y-offset:                    0px;

    enabled:                     true;
    border:                      2px solid;
    border-color:                @secondary-container;
    border-radius:               15px;
    cursor:                      "default";
    background-color:            @on-primary-fixed;
}

/*****----- Main Box -----*****/
mainbox {
    enabled:                     true;
    spacing:                     0px;
    background-color:            transparent;
    orientation:                 horizontal;
    children:                    [ "imagebox", "listbox" ];
}

imagebox {
    padding:                     20px;
    background-color:            transparent;
    /* 壁紙は launch.sh が -theme-str で background-image を注入する */
    orientation:                 vertical;
    children:                    [ "inputbar", "dummy", "mode-switcher" ];
}

listbox {
    spacing:                     20px;
    padding:                     20px;
    background-color:            transparent;
    orientation:                 vertical;
    children:                    [ "message", "listview" ];
}

dummy {
    background-color:            transparent;
}

/*****----- Inputbar -----*****/
inputbar {
    enabled:                     true;
    spacing:                     10px;
    padding:                     15px;
    border-radius:               10px;
    background-color:            @on-primary;
    text-color:                  @on-surface;
    children:                    [ "textbox-prompt-colon", "entry" ];
}
textbox-prompt-colon {
    enabled:                     true;
    expand:                      false;
    str:                         "  ";
    background-color:            inherit;
    text-color:                  inherit;
}
entry {
    enabled:                     true;
    background-color:            inherit;
    text-color:                  inherit;
    cursor:                      text;
    placeholder:                 "Search";
    placeholder-color:           inherit;
}

/*****----- Mode Switcher -----*****/
mode-switcher{
    enabled:                     true;
    spacing:                     20px;
    background-color:            transparent;
    text-color:                  @primary-fixed;
}
button {
    padding:                     15px;
    border-radius:               10px;
    background-color:            @on-primary;
    text-color:                  inherit;
    cursor:                      pointer;
}
button selected {
    background-color:            @primary;
    text-color:                  @on-secondary;
}

/*****----- Listview -----*****/
listview {
    enabled:                     true;
    columns:                     1;
    lines:                       8;
    cycle:                       true;
    dynamic:                     true;
    scrollbar:                   false;
    layout:                      vertical;
    reverse:                     false;
    fixed-height:                true;
    fixed-columns:               true;

    spacing:                     10px;
    background-color:            transparent;
    text-color:                  @on-surface;
    cursor:                      "default";
}

/*****----- Elements -----*****/
element {
    enabled:                     true;
    spacing:                     15px;
    padding:                     8px;
    border-radius:               10px;
    background-color:            transparent;
    text-color:                  @on-surface;
    cursor:                      pointer;
}
element normal.normal {
    background-color:            inherit;
    text-color:                  inherit;
}
element normal.urgent {
    background-color:            @error;
    text-color:                  @on-surface;
}
element normal.active {
    background-color:            @primary;
    text-color:                  @on-surface;
}
element selected.normal {
    background-color:            @primary;
    text-color:                  @on-secondary;
}
element selected.urgent {
    background-color:            @error;
    text-color:                  @on-secondary;
}
element selected.active {
    background-color:            @error;
    text-color:                  @on-secondary;
}
element-icon {
    background-color:            transparent;
    text-color:                  inherit;
    size:                        32px;
    cursor:                      inherit;
}
element-text {
    background-color:            transparent;
    text-color:                  inherit;
    cursor:                      inherit;
    vertical-align:              0.5;
    horizontal-align:            0.0;
}

/*****----- Message -----*****/
message {
    background-color:            transparent;
}
textbox {
    padding:                     15px;
    border-radius:               10px;
    background-color:            @on-primary;
    text-color:                  @on-surface;
    vertical-align:              0.5;
    horizontal-align:            0.0;
}
error-message {
    padding:                     15px;
    border-radius:               20px;
    background-color:            @on-primary;
    text-color:                  @on-surface;
}
```

- [ ] **Step 3: フォーマット確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: PASS（packages.nix が deadnix / nixfmt を通る）

- [ ] **Step 4: ビルド確認**

Run: `nix run .#build`
Expected: nixos 構成が成功（`colloid-icon-theme` が解決しビルドが緑）

- [ ] **Step 5: コミット**

```bash
git add home-manager/desktop/packages.nix home-manager/desktop/rofi/app-launcher.rasi
git commit -m "feat(rofi): app-launcher を arch-hyprland 横レイアウトへ全面移植+Colloid 導入"
```

---

### Task 4: launch.sh の壁紙注入を imagebox へ移す

**Files:**

- Modify: `home-manager/desktop/rofi/launch.sh:14-17`

**Interfaces:**

- Consumes: Task 3 の imagebox セレクタ
- Produces: なし

- [ ] **Step 1: 壁紙注入先を inputbar → imagebox、スケールを width → height へ変更**

`home-manager/desktop/rofi/launch.sh` の壁紙注入部を置換する。

置換前:

```bash
# 現壁紙が読めるときだけ inputbar 背景に注入する（webp 等でデコード不可でも一覧は出す）
if [[ -n $wp && -f $wp ]]; then
  exec rofi -show drun -theme "$theme" \
    -theme-str "inputbar { background-image: url(\"$wp\", width); }"
fi
```

置換後:

```bash
# 現壁紙が読めるときだけ imagebox 背景に注入する（webp 等でデコード不可でも一覧は出す）
if [[ -n $wp && -f $wp ]]; then
  exec rofi -show drun -theme "$theme" \
    -theme-str "imagebox { background-image: url(\"$wp\", height); }"
fi
```

- [ ] **Step 2: フォーマット確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: PASS

- [ ] **Step 3: コミット**

```bash
git add home-manager/desktop/rofi/launch.sh
git commit -m "fix(rofi): 壁紙注入先を imagebox へ移し height スケール化"
```

---

### Task 5: 実機反映と目視確認

**Files:** なし（反映と検証のみ）

- [ ] **Step 1: 実機へ反映**

Run: `nix run .#switch`
Expected: switch 成功

- [ ] **Step 2: ランチャー目視確認**

`Super+A`（または launch.sh の起動キー）でランチャーを開き、以下を確認する:

- 横レイアウトで左に壁紙 imagebox が表示される（1000px 幅・角丸 15px）。
- mode-switcher で window / run / drun を切り替えられる（3 ボタン）。
- drun のアイコンが Colloid で描画される。
- 検索文字を入力すると、ヒットしたアルファベットに下線が付く。

- [ ] **Step 3: capture メニュー目視確認**

スクショ/録画メニューを開き、従来の東端縦アイコン列レイアウトのまま、色が新トークン（surface 系背景・primary 系選択）で表示されることを確認する。
