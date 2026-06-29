# ReGreet Tokyo Night ログイン画面 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** greetd + ReGreet のログイン画面を、デフォルトの Adwaita から Tokyo Night 配色のモダンなダークデザインに作り込む。

**Architecture:** NixOS の `programs.regreet` モジュールを使い、GTK4 テーマ `Tokyonight-Dark` を基盤にする。背景画像（配置済み）を `fit="Cover"` で nix store に同梱し、見た目の作り込みは外出しした `style.css`（GTK4 CSS）で行う。グリーターはログイン前にシステムユーザーで起動するため配色は固定（Tokyo Night）。

**Tech Stack:** Nix（NixOS module）、ReGreet（GTK4）、GTK4 CSS、tokyonight-gtk-theme

## Global Constraints

- 設定ファイルは `nixos/desktop/greetd/` 配下に閉じる（`default.nix` / `style.css` / `assets/`）。
- 配色は **Tokyo Night 固定**: 背景 `#1a1b26` / カード `#24283b` / 入力欄 `#414868` / 本文 `#c0caf5` / 控えめ `#a9b1d6` / アクセント `#7aa2f7` / 危険操作 `#f7768e`。
- GTK4 で確実に効くプロパティのみ使用（`background-color` / `color` / `border` / `border-radius` / `padding` / `margin` / `min-width` / `min-height` / `box-shadow` / `font-size`）。`backdrop-filter` 等の Web CSS 専用プロパティは使わない。
- 既存の icon（`Papirus-Dark`）・cursor（`Bibata-Modern-Classic`）は維持する。
- 背景画像は配置済み: `nixos/desktop/greetd/assets/2025068-final.png`。
- このリポジトリは Nix 構成のため、検証は `nix` 評価チェックと（可能なら）`regreet --demo` の目視で行う。ユニットテストは存在しない。
- コミットメッセージは Conventional Commits 形式（既存の git 履歴に準拠）。

---

### Task 1: style.css を作成（GTK4 CSS で見た目を作り込む）

**Files:**

- Create: `nixos/desktop/greetd/style.css`

**Interfaces:**

- Consumes: なし
- Produces: `nixos/desktop/greetd/style.css`（Task 2 が `builtins.readFile ./style.css` で読み込む）

- [ ] **Step 1: style.css を作成する**

`nixos/desktop/greetd/style.css` に以下を書く:

```css
/* ReGreet Tokyo Night theme
 * GTK4 CSS。backdrop-filter 等の Web CSS 専用プロパティは使わず、
 * 半透明 + box-shadow で擬似ガラスに見せる。
 * セレクタ階層は ReGreet のバージョンで変わりうるため、効かない箇所は
 * `regreet --demo` + GTK Inspector で実際の階層を確認して調整する。
 */

/* 最背面: 背景画像が敷かれるが、読み込み失敗時のフォールバック色 */
window.background {
  background-color: #1a1b26;
}

/* ログインカード本体 */
box.vertical {
  background-color: alpha(#24283b, 0.86);
  border: 1px solid alpha(#c0caf5, 0.14);
  border-radius: 22px;
  box-shadow: 0 18px 48px alpha(#000000, 0.45);
  padding: 28px;
}

/* テキスト全般（挨拶・時計・ラベル） */
label {
  color: #c0caf5;
}

/* 入力欄・コンボボックス・ボタン共通の角丸と高さ */
entry,
combobox,
button {
  border-radius: 12px;
  min-height: 38px;
}

/* パスワード入力欄 */
entry {
  background-color: alpha(#414868, 0.88);
  color: #c0caf5;
  border: 1px solid alpha(#c0caf5, 0.12);
  padding: 8px 12px;
}

entry:focus {
  border-color: #7aa2f7;
  box-shadow: 0 0 0 2px alpha(#7aa2f7, 0.25);
}

/* 通常ボタン */
button {
  background-color: alpha(#414868, 0.9);
  color: #c0caf5;
  border: 1px solid alpha(#c0caf5, 0.1);
  padding: 8px 14px;
}

button:hover {
  background-color: alpha(#565f89, 0.95);
}

/* ログインなど主要アクション */
button.suggested-action {
  background-color: #7aa2f7;
  color: #1a1b26;
  border-color: #7aa2f7;
}

button.suggested-action:hover {
  background-color: #89b4fa;
}

/* 電源・再起動など破壊的アクション */
button.destructive-action {
  background-color: #f7768e;
  color: #1a1b26;
  border-color: #f7768e;
}
```

- [ ] **Step 2: CSS 構文の目視確認**

ファイル全体を読み返し、Global Constraints の配色値と一致していること、`backdrop-filter` など禁止プロパティを使っていないことを確認する。

- [ ] **Step 3: コミット**

```bash
git add nixos/desktop/greetd/style.css
git commit -m "feat(greetd): add Tokyo Night GTK4 CSS for regreet"
```

---

### Task 2: default.nix を更新（テーマ・背景・時計・CSS を配線）

**Files:**

- Modify: `nixos/desktop/greetd/default.nix`

**Interfaces:**

- Consumes: `nixos/desktop/greetd/style.css`（Task 1）、`nixos/desktop/greetd/assets/2025068-final.png`（配置済み）
- Produces: 完成した `programs.regreet` 設定

- [ ] **Step 1: default.nix を書き換える**

`nixos/desktop/greetd/default.nix` の内容を以下で置き換える:

```nix
{ pkgs, ... }:
{
  services.greetd.enable = true;

  programs.regreet = {
    enable = true;

    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };
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
      package = pkgs.inter;
      size = 15;
    };

    settings = {
      background = {
        path = "${./assets/2025068-final.png}";
        fit = "Cover";
      };
      GTK.application_prefer_dark_theme = true;
      appearance.greeting_msg = "Welcome back";
      widget.clock = {
        format = "%H:%M  %a";
        resolution = "1s";
        label_width = 180;
      };
    };

    extraCss = builtins.readFile ./style.css;
  };
}
```

- [ ] **Step 2: Nix 評価が通ることを確認する**

Run: `cd ~/ghq/github.com/mkiin/dotfiles && nix flake check 2>&1 | tail -20`
Expected: regreet/greetd 由来の評価エラーが出ないこと。`tokyonight-gtk-theme` / `inter` が解決できること。

（`nix flake check` が重い・他要因で失敗する場合は、構成名を特定して `nix eval` で当該モジュールだけ評価する。例: `nix eval .#nixosConfigurations.<host>.config.programs.regreet.settings --json | head`。ホスト名は `nix flake show` で確認する。）

- [ ] **Step 3: 背景画像パスが store に入ることを確認する**

Run: `nix eval --raw ".#nixosConfigurations.<host>.config.programs.regreet.settings.background.path"`（`<host>` は実機のホスト名）
Expected: `/nix/store/...-2025068-final.png` のような store パスが返る。

- [ ] **Step 4: コミット**

```bash
git add nixos/desktop/greetd/default.nix
git commit -m "feat(greetd): apply Tokyo Night theme, background and clock to regreet"
```

---

### Task 3: ビルドと目視確認

**Files:**

- なし（検証のみ）

**Interfaces:**

- Consumes: Task 1, Task 2 の成果物
- Produces: 動作確認済みのログイン画面

- [ ] **Step 1: 構成をビルドする**

Run: `cd ~/ghq/github.com/mkiin/dotfiles && nixos-rebuild build --flake .#<host> 2>&1 | tail -20`
Expected: ビルド成功（エラーなし）。`<host>` は実機ホスト名。

- [ ] **Step 2: 可能なら demo モードで目視確認する**

Run: `nix run nixpkgs#greetd.regreet -- --demo --style nixos/desktop/greetd/style.css 2>&1 | tail` もしくは実機にインストール済みの `regreet --demo`。
Expected: カード（半透明・角丸・影）、入力欄（角丸・フォーカス時に青リング）、ボタン（hover で明るく）、時計、"Welcome back" が Tokyo Night 配色で表示される。
セレクタが効かない箇所があれば GTK Inspector（`GTK_DEBUG=interactive`）で実際の widget 階層を確認し、Task 1 の `style.css` のセレクタを修正して再コミットする。

（demo 実行が環境的に難しい場合はこの Step をスキップし、Step 3 の実機切替で確認する。）

- [ ] **Step 3: 実機に適用して最終確認する**

Run: `sudo nixos-rebuild switch --flake .#<host>`
その後ログアウトし、ログイン画面で背景・カード・入力欄・ボタン・時計・挨拶の見た目を目視確認する。
Expected: Tokyo Night 配色のモダンなログイン画面が表示される。崩れがあれば `style.css` を調整して再ビルド。

- [ ] **Step 4: 調整があればコミット**

```bash
git add nixos/desktop/greetd/style.css
git commit -m "fix(greetd): adjust regreet CSS selectors after visual check"
```

（調整不要ならコミットなしで完了。）

---

## Self-Review

**1. Spec coverage:**

- ファイル構成（default.nix / style.css / assets）→ Task 1, 2 でカバー。
- GTK theme = Tokyonight-Dark、icon/cursor 維持、font Inter 15 → Task 2 でカバー。
- background path/fit=Cover → Task 2 でカバー。
- clock / greeting / prefer_dark_theme → Task 2 でカバー。
- Tokyo Night パレットでの CSS 作り込み → Task 1 でカバー。
- 検証（nix build / regreet --demo / 実機）→ Task 2, 3 でカバー。
- ギャップなし。

**2. Placeholder scan:** `<host>` は実機ホスト名を指す明示的なプレースホルダで、各 Step に確認手段（`nix flake show`）を併記済み。TODO/TBD なし。

**3. Type consistency:** `style.css`（Task 1 が作成）を Task 2 が `builtins.readFile ./style.css` で参照、`assets/2025068-final.png` を Task 2 が `${./assets/2025068-final.png}` で参照。パス・ファイル名は一貫。配色 HEX 値は Global Constraints と Task 1 で一致。
