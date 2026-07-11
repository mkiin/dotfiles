# rofi アプリランチャー（HynDuf 風・matugen 連動）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** quickshell 製アプリランチャーを HynDuf 風の rofi ランチャーへ置き換え、配色を matugen に連動させる。

**Architecture:** rofi-wayland を `packages.nix` で宣言し、`.rasi` 実ファイルを `xdg.configFile` でコロケーション配置する（`programs.rofi` は使わず Nerd Font グリフを保全）。matugen が壁紙変更時に `themes/colors.rasi` を生成し、`app-launcher.rasi` が `@import` する。起動は `launch.sh` が `last_wallpaper` を読んで `-theme-str` で壁紙プレビューを注入する。

**Tech Stack:** Nix / home-manager, rofi-wayland, matugen, bash, Hyprland(Wayland)

## Global Constraints

- パッケージ本体の宣言は集約 `packages.nix` のみ（機能ディレクトリの `default.nix` に `home.packages` 直書き禁止）。設定は `xdg.configFile` 等の設定機構で行う。
- `../` で親ディレクトリへ遡る相対パス参照を書かない。Nix の同階層参照は `lnk ./file`、リポジトリ横断は `${dotfilesDir}/...`。
- コメントは「なぜ」だけを 1〜2 行。逐条コメント禁止。
- 検証は `nix run .#build`（NixOS 構成ビルド）と `nix run .#fmt -- --fail-on-change`（treefmt/deadnix）を必ず両方通す。実機反映は `nix run .#switch`。
- 参照元デザイン: `~/ghq/github.com/HynDuf/dotfiles/.config/rofi/`（`config.rasi` / `themes/app-launcher.rasi`）。glyph 保全のため retype せず `cp` で取り込む。
- matugen テンプレート構文は `{{colors.<role>.default.hex}}`（既存 `quickshell-colors.json` と同型）。

---

## Task 1: matugen による rofi カラー配線

matugen が壁紙変更時に rofi 用の `colors.rasi` を生成するようにし、初回ブート用フォールバックを置く。この時点で rofi 本体はまだ無いが、`~/.config/rofi/themes/colors.rasi` が生成/シードされることを検証できる。

**Files:**

- Create: `home-manager/desktop/matugen/templates/rofi-colors.rasi`
- Create: `home-manager/desktop/matugen/fallback/colors.rasi`
- Modify: `home-manager/desktop/matugen/config.toml`
- Modify: `home-manager/desktop/matugen/default.nix`

**Interfaces:**

- Produces: `~/.config/rofi/themes/colors.rasi`（rofi の `* {}` に `background` / `background-alt` / `foreground` / `selected` / `active` / `urgent` / `border-color` を定義）。Task 2 の `app-launcher.rasi` が `@import "colors.rasi"` で消費する。

- [ ] **Step 1: matugen テンプレートを作成**

Create `home-manager/desktop/matugen/templates/rofi-colors.rasi`:

```rasi
* {
    background:      {{colors.surface.default.hex}};
    background-alt:  {{colors.surface_container_high.default.hex}};
    foreground:      {{colors.on_surface.default.hex}};
    selected:        {{colors.surface_container_lowest.default.hex}};
    active:          {{colors.primary.default.hex}};
    urgent:          {{colors.error_container.default.hex}};
    border-color:    {{colors.outline_variant.default.hex}};
}
```

- [ ] **Step 2: フォールバック colors.rasi を作成**

Create `home-manager/desktop/matugen/fallback/colors.rasi`（matugen 未実行の初回ブートで `@import` が失敗しないための静的シード）:

```rasi
* {
    background:      #181825;
    background-alt:  #313244;
    foreground:      #cdd6f4;
    selected:        #11111b;
    active:          #89b4fa;
    urgent:          #f38ba8;
    border-color:    #45475a;
}
```

- [ ] **Step 3: config.toml に rofi テンプレートを追記**

Append to `home-manager/desktop/matugen/config.toml`:

```toml
[templates.rofi]
input_path = "~/.config/matugen/templates/rofi-colors.rasi"
output_path = "~/.config/rofi/themes/colors.rasi"
```

（post_hook は不要。rofi は起動毎に `colors.rasi` を読むため。）

- [ ] **Step 4: default.nix にテンプレート配置とフォールバックシードを追記**

Modify `home-manager/desktop/matugen/default.nix`。`xdg.configFile` に 1 行、`home.activation` を 1 ブロック追加する。編集後の全体:

```nix
{ lnk, lib, ... }:
{
  xdg.configFile = {
    "matugen/config.toml".source = lnk ./config.toml;
    "matugen/templates/hyprland-colors.lua".source = lnk ./templates/hyprland-colors.lua;
    "matugen/templates/waybar-colors.css".source = lnk ./templates/waybar-colors.css;
    "matugen/templates/wlogout-colors.css".source = lnk ./templates/wlogout-colors.css;
    "matugen/templates/quickshell-colors.json".source = lnk ./templates/quickshell-colors.json;
    "matugen/templates/rofi-colors.rasi".source = lnk ./templates/rofi-colors.rasi;
  };

  # 初回ブートは matugen 未実行で colors.css が無く waybar が @import に失敗する。
  # 壁紙適用で本物が生成されるまでの間だけ seed 由来のフォールバックを置く(存在時は触らない)。
  home.activation.fallbackWaybarColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/waybar/colors.css"
    [ -e "$t" ] || $DRY_RUN_CMD install -Dm644 ${./fallback/colors.css} "$t"
  '';

  # rofi も同様に、matugen 生成前の初回起動で @import "colors.rasi" が失敗しないよう seed する。
  home.activation.fallbackRofiColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/rofi/themes/colors.rasi"
    [ -e "$t" ] || $DRY_RUN_CMD install -Dm644 ${./fallback/colors.rasi} "$t"
  '';
}
```

- [ ] **Step 5: ビルドと整形を検証**

Run: `cd ~/ghq/github.com/mkiin/dotfiles && nix run .#build && nix run .#fmt -- --fail-on-change`
Expected: 両方成功（エラー・deadnix 指摘・差分なし）。

- [ ] **Step 6: 反映してフォールバックシードを確認**

Run: `nix run .#switch && cat ~/.config/rofi/themes/colors.rasi`
Expected: `* { background: #181825; ... }` が表示される（フォールバックシードが置かれた）。

- [ ] **Step 7: matugen 生成を確認**

Run: `pypr wall next && sleep 3 && cat ~/.config/rofi/themes/colors.rasi`
Expected: 壁紙由来の hex 値（`#181825` 等の固定値ではない実際のカラー）に書き換わっている。

- [ ] **Step 8: コミット**

```bash
cd ~/ghq/github.com/mkiin/dotfiles
git add home-manager/desktop/matugen/templates/rofi-colors.rasi \
        home-manager/desktop/matugen/fallback/colors.rasi \
        home-manager/desktop/matugen/config.toml \
        home-manager/desktop/matugen/default.nix
git commit -m "feat(rofi): matugen で rofi カラー(colors.rasi)を生成・フォールバック配置"
```

---

## Task 2: rofi モジュール（パッケージ・設定・起動スクリプト）

rofi-wayland を宣言し、HynDuf の `.rasi` を取り込んで matugen 連動・壁紙プレビュー付きで起動できるようにする。トリガー差し替えは Task 3 で行うため、この時点では `launch.sh` を手動実行して検証する。

**Files:**

- Modify: `home-manager/desktop/packages.nix`
- Create: `home-manager/desktop/rofi/default.nix`
- Create: `home-manager/desktop/rofi/config.rasi`（HynDuf からコピー後に編集）
- Create: `home-manager/desktop/rofi/app-launcher.rasi`（HynDuf からコピー後に編集）
- Create: `home-manager/desktop/rofi/launch.sh`
- Modify: `home-manager/desktop/default.nix`

**Interfaces:**

- Consumes: Task 1 が生成/シードする `~/.config/rofi/themes/colors.rasi`。
- Produces: 実行可能な `~/.config/rofi/launch.sh`（引数なしで rofi drun を toggle 起動）。Task 3 の waybar `on-click` と Super+A がこれを呼ぶ。

- [ ] **Step 1: HynDuf の設定ファイルを実ファイルとしてコピー（glyph 保全）**

Run:

```bash
cd ~/ghq/github.com/mkiin/dotfiles
mkdir -p home-manager/desktop/rofi
cp ~/ghq/github.com/HynDuf/dotfiles/.config/rofi/config.rasi \
   home-manager/desktop/rofi/config.rasi
cp ~/ghq/github.com/HynDuf/dotfiles/.config/rofi/themes/app-launcher.rasi \
   home-manager/desktop/rofi/app-launcher.rasi
```

Expected: 2 ファイルがコピーされる（Nerd Font グリフはバイト列のまま保持）。

- [ ] **Step 2: config.rasi の icon-theme を実環境に合わせる**

`home-manager/desktop/rofi/config.rasi` の 8 行目を編集:

- 変更前: `  icon-theme: "Papirus";`
- 変更後: `  icon-theme: "Papirus-Dark";`

（実環境に導入済みなのは `Papirus-Dark`。`home-manager/desktop/gtk/default.nix` 参照。）

- [ ] **Step 3: app-launcher.rasi の色定義を @import に置換**

`home-manager/desktop/rofi/app-launcher.rasi` の Global Properties ブロック（`* { font ... urgent }`、14〜22 行目付近）を編集する。`font` だけ残し、6 つの色定義を削除して先頭に `@import` を足す。

- 変更前:

```rasi
/*****----- Global Properties -----*****/
* {
    font:                        "JetBrains Mono Nerd Font 11";
    background:                  #181825;
    background-alt:              #181825;
    foreground:                  #cdd6f4;
    selected:                    #11111b;
    active:                      #89b4fa;
    urgent:                      #11111b;
}
```

- 変更後:

```rasi
/*****----- Global Properties -----*****/
@import "colors.rasi"

* {
    font:                        "JetBrains Mono Nerd Font 11";
}
```

- [ ] **Step 4: app-launcher.rasi の壁紙固定パス行を削除**

同ファイルの `inputbar` ブロック内、`background-image` 行（65 行目付近）を削除する。壁紙は `launch.sh` が `-theme-str` で注入するため固定行は持たない。

- 削除する行: `    background-image:            url("~/Pictures/hollow.jpg", width);`

（`inputbar { ... }` の他プロパティ・`children` はそのまま残す。）

- [ ] **Step 5: launch.sh を作成**

Create `home-manager/desktop/rofi/launch.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# すでに開いていれば閉じる（Super+A / アイコンクリックの toggle 挙動）
if pgrep -x rofi >/dev/null; then
  pkill -x rofi
  exit 0
fi

theme="$HOME/.config/rofi/themes/app-launcher.rasi"
wp="$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/hypr/last_wallpaper" 2>/dev/null || true)"

# 現壁紙が読めるときだけ inputbar 背景に注入する（webp 等でデコード不可でも一覧は出す）
if [[ -n "$wp" && -f "$wp" ]]; then
  exec rofi -show drun -theme "$theme" \
    -theme-str "inputbar { background-image: url(\"$wp\", width); }"
fi
exec rofi -show drun -theme "$theme"
```

- [ ] **Step 6: launch.sh に実行権を付与**

Run: `chmod +x ~/ghq/github.com/mkiin/dotfiles/home-manager/desktop/rofi/launch.sh`
Expected: exec bit が付く（`lnk` の symlink 先モードを rofi 起動時に継承させるため必須）。

- [ ] **Step 7: rofi モジュールの default.nix を作成**

Create `home-manager/desktop/rofi/default.nix`:

```nix
{ lnk, ... }:
{
  xdg.configFile = {
    "rofi/config.rasi".source = lnk ./config.rasi;
    "rofi/themes/app-launcher.rasi".source = lnk ./app-launcher.rasi;
    "rofi/launch.sh".source = lnk ./launch.sh;
  };
}
```

- [ ] **Step 8: packages.nix に rofi-wayland を宣言**

Modify `home-manager/desktop/packages.nix`。`desktop utilities` の束（`wlogout` の並び）に `rofi-wayland` を追加する:

- 変更前:

```nix
    # desktop utilities (waybar=programs.waybar, cliphist/hypridle=services)
    wlogout
    socat
```

- 変更後:

```nix
    # desktop utilities (waybar=programs.waybar, cliphist/hypridle=services)
    wlogout
    rofi-wayland
    socat
```

- [ ] **Step 9: desktop/default.nix に import を追加**

Modify `home-manager/desktop/default.nix` の `imports` に `./rofi` を追加する（`./wlogout` の並び）:

- 変更前:

```nix
    ./quickshell
    ./wlogout
```

- 変更後:

```nix
    ./quickshell
    ./wlogout
    ./rofi
```

- [ ] **Step 10: ビルドと整形を検証**

Run: `cd ~/ghq/github.com/mkiin/dotfiles && nix run .#build && nix run .#fmt -- --fail-on-change`
Expected: 両方成功。

- [ ] **Step 11: 反映して launch.sh を手動起動**

Run: `nix run .#switch && ~/.config/rofi/launch.sh`
Expected: センター配置の rofi ランチャーが開く。確認項目:

- 検索バー上部に現在の壁紙が表示される
- アプリ一覧に Papirus-Dark のカラーアイコンが出る
- 検索バー右に mode-switcher ボタンが 3 つ（drun/filebrowser/window）
- 配色が壁紙由来（matugen）になっている
- もう一度 `~/.config/rofi/launch.sh` を実行すると閉じる（toggle）

- [ ] **Step 12: コミット**

```bash
cd ~/ghq/github.com/mkiin/dotfiles
git add home-manager/desktop/rofi/ \
        home-manager/desktop/packages.nix \
        home-manager/desktop/default.nix
git commit -m "feat(rofi): HynDuf 風 rofi ランチャー(matugen 連動・壁紙プレビュー)を追加"
```

---

## Task 3: トリガー配線と quickshell ランチャー撤去

waybar の nix アイコンと Super+A を rofi の `launch.sh` に差し替え、死んだ quickshell ランチャーを削除する。

**Files:**

- Modify: `home-manager/desktop/waybar/modules.nix:6`
- Modify: `home-manager/desktop/hyprland/lua/keybinds.lua:21`
- Modify: `home-manager/desktop/quickshell/shell/shell.qml`
- Delete: `home-manager/desktop/quickshell/shell/modules/launcher/LauncherWindow.qml`

**Interfaces:**

- Consumes: Task 2 の `~/.config/rofi/launch.sh`。

- [ ] **Step 1: 他に launcher 参照が無いか確認**

Run: `cd ~/ghq/github.com/mkiin/dotfiles && grep -rn "launcher\|Launcher" home-manager/desktop/quickshell/`
Expected: `shell.qml` の import/インスタンス/IpcHandler と `modules/launcher/LauncherWindow.qml` のみ。他モジュール（audio/bluetooth 等）からの参照が無いことを確認する。

- [ ] **Step 2: waybar nix アイコンの on-click を差し替え**

Modify `home-manager/desktop/waybar/modules.nix` の 6 行目:

- 変更前: `    on-click = "qs -c shell ipc call launcher toggle";`
- 変更後: `    on-click = "$HOME/.config/rofi/launch.sh";`

modules.nix のシグネチャは `{ username }:` で `config` を受け取らないため Nix 変数は使わない。waybar の `on-click` はシェル経由で実行されるため `$HOME` が展開される（既存の他モジュールも同様にシェルコマンド文字列を渡している）。

- [ ] **Step 3: Super+A キーバインドを差し替え**

Modify `home-manager/desktop/hyprland/lua/keybinds.lua` の 21 行目:

- 変更前: `hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("qs -c shell ipc call launcher toggle"))`
- 変更後: `hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("~/.config/rofi/launch.sh"))`

（既存の screenshot.sh 等と同じく `~/.config/...` 直叩き。）

- [ ] **Step 4: shell.qml から launcher を撤去**

Modify `home-manager/desktop/quickshell/shell/shell.qml`。3 箇所を削除する。

削除 1（import、12 行目）:

```qml
import "modules/launcher"
```

削除 2（LauncherWindow インスタンス、50〜54 行目のコメント含む）:

```qml
    // アプリランチャー（archlinuxアイコン / Super+A から起動）
    LauncherWindow {
        id: launcher
        shouldShow: false
    }
```

削除 3（IpcHandler、56〜62 行目のコメント含む）:

```qml
    // waybar / Super+A からのトグル
    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.shouldShow ? launcher.closeLauncher() : launcher.openLauncher() }
        function open(): void { launcher.openLauncher() }
        function close(): void { launcher.closeLauncher() }
    }
```

（`cc` / `theme` / `idle` の IpcHandler と ControlCenterWindow は残す。）

- [ ] **Step 5: LauncherWindow.qml を削除**

Run:

```bash
cd ~/ghq/github.com/mkiin/dotfiles
git rm home-manager/desktop/quickshell/shell/modules/launcher/LauncherWindow.qml
rmdir home-manager/desktop/quickshell/shell/modules/launcher 2>/dev/null || true
```

Expected: ファイルが削除され、空になった launcher ディレクトリも消える。

- [ ] **Step 6: ビルドと整形を検証**

Run: `cd ~/ghq/github.com/mkiin/dotfiles && nix run .#build && nix run .#fmt -- --fail-on-change`
Expected: 両方成功。

- [ ] **Step 7: 反映してトリガーと quickshell を確認**

Run: `nix run .#switch`
Expected（手動確認）:

- Super+A で rofi ランチャーが開閉する
- waybar の nix アイコンクリックで rofi ランチャーが開く
- quickshell が正常起動し続ける（`qs-restart` で再起動してもエラーなし）。Super+N の通知センターは従来通り動く
- 旧 quickshell ランチャーは起動しない

- [ ] **Step 8: コミット**

```bash
cd ~/ghq/github.com/mkiin/dotfiles
git add home-manager/desktop/waybar/modules.nix \
        home-manager/desktop/hyprland/lua/keybinds.lua \
        home-manager/desktop/quickshell/shell/shell.qml \
        home-manager/desktop/quickshell/shell/modules/launcher/
git commit -m "feat(rofi): 起動トリガーを rofi へ差し替え quickshell ランチャーを撤去"
```

- [ ] **Step 9: todo.md を更新**

`todo.md` の「アプリランチャーをrofiに変更」節（99 行目付近）に完了マークを付ける。

- 変更前:

```markdown
## アプリランチャーをrofiに変更

現在はquickshellで構築してるが、rofiのUIが優れておりデフォルトのデザインがすでに良いため変更する

- HynDufのdotfilesにあるrofiデザインををインスパイア
```

- 変更後:

```markdown
## アプリランチャーをrofiに変更 ✅ 完了

HynDuf 風 rofi ランチャー(3モード drun/filebrowser/window)に置換。配色は matugen 連動
(surface 階層で凹み/浮きを表現)、検索バー上部は launch.sh が last_wallpaper を読み
-theme-str で現壁紙をプレビュー注入。quickshell ランチャーは撤去。
設計 `docs/superpowers/specs/2026-07-11-rofi-app-launcher-design.md` /
計画 `docs/superpowers/plans/2026-07-11-rofi-app-launcher.md`。
```

- [ ] **Step 10: コミット**

```bash
cd ~/ghq/github.com/mkiin/dotfiles
git add todo.md
git commit -m "docs: todo の rofi 移行を完了に更新"
```

---

## Self-Review メモ

- **Spec coverage**: 3 モード（Task 2 の app-launcher.rasi configuration）・matugen 連動配色（Task 1）・凹ませ selected（Task 1 の `surface_container_lowest`）・壁紙プレビュー動的注入（Task 2 launch.sh）・rofi-wayland + xdg.configFile 実ファイル（Task 2）・quickshell 撤去（Task 3）・アイコン/フォント既存流用（Task 2 config.rasi）を各々カバー。
- **フォールバック**: Task 1 で `themes/colors.rasi` シードを置くため、Task 2 の rofi は matugen 未実行でも起動可能。
- **glyph 保全**: Task 2 は HynDuf ファイルを `cp` で取り込み、色ブロック・壁紙行のみ編集（グリフ埋め込み行は触らない）。
- **依存順序**: Task1（colors.rasi 生成）→ Task2（launch.sh 生成・@import 消費）→ Task3（launch.sh をトリガーに配線）。

```

```
