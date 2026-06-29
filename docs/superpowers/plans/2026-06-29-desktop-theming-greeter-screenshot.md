# デスクトップ環境4課題の修正 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Quickshell アイコン・マウスカーソル・ログイン画面(greeter)・hyprshot Esc の4つの不具合を、home-manager 層 / NixOS システム層の二層構成で修正する。

**Architecture:** 外観テーマはログイン後セッション(home 層)とログイン画面(システム層 greeter)で別々に設定する。home 層に `gtk/`・`cursor/` モジュールを新設し、システム層は SDDM を greetd+regreet に置換する。スクリーンショットは hyprshot をやめ slurp+grim で自前選択し Esc キャンセルを制御する。

**Tech Stack:** Nix flake / home-manager / NixOS modules / Hyprland (Lua config) / bash

## Global Constraints

- 各コミット前に必ず `nix fmt`（treefmt: nixfmt/stylua/shfmt/prettier）を実行する。CI は冪等性を検証するため、未フォーマットのコミットは失敗する。
- 設定は機能別ディレクトリ + `default.nix` パターンに従う（例: `home-manager/desktop/mouse/`, `nixos/desktop/vesktop/`）。
- 検証は `nix build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run` で評価が通ること（home層も `hosts/nixos/default.nix` 経由でこの config に含まれる）。
- home 層モジュールの第一引数は `{ pkgs, ... }:`、システム層も同様。未使用引数は付けない。
- `gtk.iconTheme.package` / `home.pointerCursor.package` / `programs.regreet.*.package` は各パッケージをプロファイル/greeter 環境へ自動導入するため、`packages.nix` 側に重複登録しない。

---

### Task 1: gtk モジュール（課題1: アイコン紫黒解消）

**Files:**

- Create: `home-manager/desktop/gtk/default.nix`
- Modify: `home-manager/desktop/default.nix`（`imports` に `./gtk` 追加）
- Modify: `home-manager/desktop/packages.nix`（`papirus-icon-theme` を削除）
- Modify: `home-manager/desktop/hyprland/lua/input.lua`（`QT_QPA_PLATFORMTHEME` 行を削除）

**Interfaces:**

- Produces: `gtk.iconTheme`（`Papirus-Dark` / `pkgs.papirus-icon-theme`）と `qt.platformTheme.name = "gtk"`。後続の Task 3 が同じアイコンテーマ名 `Papirus-Dark` を greeter 側で参照する。

- [ ] **Step 1: gtk モジュールを作成**

Create `home-manager/desktop/gtk/default.nix`:

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

- [ ] **Step 2: imports に追加**

`home-manager/desktop/default.nix` の `imports` リスト、`./packages.nix` の次行に `./gtk` を追加する。

```nix
  imports = [
    ./packages.nix
    ./gtk
    ./hyprland
```

- [ ] **Step 3: packages.nix から papirus を削除**

`home-manager/desktop/packages.nix` の以下2行（コメント + パッケージ）を削除する（アイコンテーマは gtk モジュールが導入するため重複回避）:

```nix
    # icon theme (fonts are managed system-wide in nixos/core/fonts)
    papirus-icon-theme
```

- [ ] **Step 4: input.lua の QT_QPA 行を削除**

`home-manager/desktop/hyprland/lua/input.lua` の以下の1行を削除する（qt モジュールが宣言的に設定するため）:

```lua
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
```

- [ ] **Step 5: フォーマット**

Run: `nix fmt`
Expected: 変更ファイルが整形され、エラーなく終了。

- [ ] **Step 6: 評価検証**

Run: `nix build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run`
Expected: 評価が通り、ビルド予定の derivation 一覧が表示される（エラーなし）。

- [ ] **Step 7: コミット**

```bash
git add home-manager/desktop/gtk/default.nix home-manager/desktop/default.nix home-manager/desktop/packages.nix home-manager/desktop/hyprland/lua/input.lua
git commit -m "feat(home): add gtk module with Papirus-Dark icon theme and qt platform theme"
```

---

### Task 2: cursor モジュール（課題2: 雫カーソル→Bibata）

**Files:**

- Create: `home-manager/desktop/cursor/default.nix`
- Modify: `home-manager/desktop/default.nix`（`imports` に `./cursor` 追加）
- Modify: `home-manager/desktop/hyprland/lua/input.lua`（カーソル env 4行を削除）

**Interfaces:**

- Consumes: Task 1 で追加済みの `imports` リスト（`./gtk` の次に `./cursor` を追加）。
- Produces: `home.pointerCursor`（`Bibata-Modern-Classic` / `pkgs.bibata-cursors` / size 24）。後続の Task 3 が同じカーソル名 `Bibata-Modern-Classic` を greeter 側で参照する。

- [ ] **Step 1: cursor モジュールを作成**

Create `home-manager/desktop/cursor/default.nix`:

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

- [ ] **Step 2: imports に追加**

`home-manager/desktop/default.nix` の `imports` リスト、`./gtk` の次行に `./cursor` を追加する。

```nix
    ./packages.nix
    ./gtk
    ./cursor
    ./hyprland
```

- [ ] **Step 3: input.lua のカーソル env 4行を削除**

`home-manager/desktop/hyprland/lua/input.lua` の先頭4行を削除する（`home.pointerCursor` が XCURSOR/HYPRCURSOR とサイズを一括設定するため）:

```lua
hl.env("XCURSOR_THEME", "phinger-cursors-light")
hl.env("HYPRCURSOR_THEME", "phinger-cursors-light")
hl.env("XCURSOR_SIZE", "40")
hl.env("HYPRCURSOR_SIZE", "40")
```

- [ ] **Step 4: フォーマット**

Run: `nix fmt`
Expected: 変更ファイルが整形され、エラーなく終了。

- [ ] **Step 5: 評価検証**

Run: `nix build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run`
Expected: 評価が通る（エラーなし）。

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/cursor/default.nix home-manager/desktop/default.nix home-manager/desktop/hyprland/lua/input.lua
git commit -m "feat(home): add cursor module with Bibata-Modern-Classic pointer"
```

---

### Task 3: greetd + regreet（課題3: ログイン画面の置換）

**Files:**

- Rename: `nixos/desktop/display-manager/` → `nixos/desktop/greetd/`（`git mv`）
- Modify: `nixos/desktop/greetd/default.nix`（SDDM → greetd+regreet に全面置換）
- Modify: `nixos/desktop/default.nix`（`imports` の `./display-manager` → `./greetd`）

**Interfaces:**

- Consumes: Task 1 のアイコンテーマ名 `Papirus-Dark`、Task 2 のカーソル名 `Bibata-Modern-Classic`（greeter 側に同名で適用し二層の見た目を揃える）。
- Produces: `services.greetd.enable` + `programs.regreet`（greeter スタック）。

- [ ] **Step 1: ディレクトリをリネーム**

Run:

```bash
git mv nixos/desktop/display-manager nixos/desktop/greetd
```

Expected: ディレクトリと中の `default.nix` が移動される。

- [ ] **Step 2: greetd/default.nix を置換**

`nixos/desktop/greetd/default.nix` の内容を以下で全面置換する:

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
  };
}
```

- [ ] **Step 3: import パスを更新**

`nixos/desktop/default.nix` の `imports` 内 `./display-manager` を `./greetd` に変更する。

```nix
  imports = [
    ./hyprland
    ./greetd
    ./fcitx5
```

- [ ] **Step 4: フォーマット**

Run: `nix fmt`
Expected: 変更ファイルが整形され、エラーなく終了。

- [ ] **Step 5: 評価検証**

Run: `nix build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run`
Expected: 評価が通る。`programs.regreet` がデフォルトで `services.greetd.settings.default_session.command` を cage ラップ起動に設定するため、DM の重複定義エラーが出ないこと。

- [ ] **Step 6: コミット**

```bash
git add nixos/desktop/greetd nixos/desktop/default.nix
git commit -m "feat(nixos): replace SDDM with greetd + regreet greeter"
```

---

### Task 4: screenshot.sh の Esc キャンセル対応（課題4）

**Files:**

- Modify: `home-manager/desktop/hyprland/scripts/screenshot.sh`（slurp+grim ベースに書換）
- Modify: `home-manager/desktop/packages.nix`（`hyprshot` 削除、`grim`・`slurp` 追加）

**Interfaces:**

- Consumes: なし（独立）。
- Produces: `screenshot.sh <region|window|output>` の振る舞い（Esc/空選択で撮影せず静かに終了）。

- [ ] **Step 1: screenshot.sh を書き換え**

`home-manager/desktop/hyprland/scripts/screenshot.sh` の内容を以下で全面置換する:

```bash
#!/usr/bin/env bash
set -euo pipefail

mode="${1:?usage: screenshot.sh <region|window|output>}"
base_dir="${HOME}/Pictures/Screenshots"
monitor=""
geom=""

case "$mode" in
region)
  class=$(hyprctl activewindow -j | jq -r '.class // "unknown"')
  class="${class//[\/\\ ]/_}"
  out_dir="${base_dir}/${class}"
  # slurp で範囲選択。Esc / 空選択ならキャンセル（撮影も通知もせず終了）
  geom=$(slurp) || exit 0
  [ -z "$geom" ] && exit 0
  ;;
window)
  class=$(hyprctl activewindow -j | jq -r '.class // "unknown"')
  class="${class//[\/\\ ]/_}"
  out_dir="${base_dir}/${class}"
  # 表示中ウィンドウの矩形を slurp に渡して選択。Esc / 空選択でキャンセル
  geom=$(hyprctl clients -j |
    jq -r '.[] | select(.mapped == true and .hidden == false) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' |
    slurp) || exit 0
  [ -z "$geom" ] && exit 0
  ;;
output)
  monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name // "unknown"')
  out_dir="${base_dir}/output/${monitor}"
  ;;
*)
  echo "[screenshot.sh] unknown mode: $mode" >&2
  exit 1
  ;;
esac

mkdir -p "$out_dir"
file="${out_dir}/$(date +%Y%m%d_%H%M%S).png"

if [ -n "$geom" ]; then
  grim -g "$geom" "$file"
else
  grim -o "$monitor" "$file"
fi

notify-send -a "screenshot" "スクリーンショット" "$file に保存しました"
```

- [ ] **Step 2: 構文チェック**

Run: `bash -n home-manager/desktop/hyprland/scripts/screenshot.sh`
Expected: 出力なし・終了コード 0（構文エラーなし）。

- [ ] **Step 3: packages.nix を更新**

`home-manager/desktop/packages.nix` の `home.packages` リストで、`hyprshot` 行を削除し、スクリプト依存コメントの下に `grim` と `slurp` を追加する。最終的に該当箇所は以下の形にする:

```nix
    # session essentials (lock, screenshot, clipboard, media keys)
    hyprlock
    wl-clipboard
    brightnessctl
    pamixer
    # script dependencies (screenshot.sh, record.sh)
    grim
    slurp
    jq
    libnotify
```

- [ ] **Step 4: フォーマット**

Run: `nix fmt`
Expected: `screenshot.sh`（shfmt）と `packages.nix`（nixfmt）が整形され、エラーなく終了。

- [ ] **Step 5: 評価検証**

Run: `nix build .#nixosConfigurations.nixos.config.system.build.toplevel --dry-run`
Expected: 評価が通る（`grim`/`slurp` が解決され、`hyprshot` 参照が残っていないこと）。

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/hyprland/scripts/screenshot.sh home-manager/desktop/packages.nix
git commit -m "fix(screenshot): use slurp+grim so Esc cancels without capturing"
```

---

### Task 5: 適用と実機検証（手動）

**Files:** なし（実機反映と動作確認のみ）

- [ ] **Step 1: システムを適用**

Run: `sudo nixos-rebuild switch --flake .#nixos`
Expected: ビルド・適用が成功する。

- [ ] **Step 2: 再起動して greeter を確認**

Run: `sudo reboot`
Expected: 再起動後、regreet のグラフィカルログイン画面が表示される。カーソルが Bibata（雫でない）、アイコンが Papirus で表示される。

- [ ] **Step 3: ログイン後の外観を確認**

- Quickshell のアイコンが紫黒プレースホルダでなく正しく表示される。
- マウスカーソルが Bibata-Modern-Classic になっている。

- [ ] **Step 4: スクリーンショットの Esc キャンセルを確認**

- `Super+P`（region）で選択待機 → Esc → 撮影されず通知も出ない。
- `Super+Shift+P`（window）で選択待機 → Esc → 撮影されず通知も出ない。
- 各モードで正常に選択 → 撮影され `~/Pictures/Screenshots/...` に保存、通知が出る。
- `Super+Ctrl+P`（output）でフォーカス中モニタ全体が撮影される。

---

## Self-Review

**Spec coverage:**

- 課題1（アイコン）→ Task 1 ✓
- 課題2（カーソル）→ Task 2 ✓
- 課題3（greeter）→ Task 3 ✓（display-manager→greetd リネーム含む）
- 課題4（screenshot Esc）→ Task 4 ✓
- 変更ファイル一覧の全項目に対応タスクあり ✓
- 二層構成（home/system でテーマ名を共有）→ Task 1/2 の名前を Task 3 が参照 ✓
- スコープ外（壁紙・gtk.theme・HiDPI）→ 計画に含めず ✓

**Placeholder scan:** TBD/TODO/「適切に処理」等なし。全コードブロックに実内容を記載 ✓

**Type consistency:** アイコンテーマ名 `Papirus-Dark`、カーソル名 `Bibata-Modern-Classic` を Task 1/2/3 で統一 ✓。パッケージ名 `papirus-icon-theme` / `bibata-cursors` / `grim` / `slurp` を全タスクで一致 ✓
