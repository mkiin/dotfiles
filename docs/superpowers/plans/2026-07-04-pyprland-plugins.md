# pyprland プラグイン群導入 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** pyprland に `workspaces_follow_focus` / `scratchpads` / `toggle_special` / `lost_windows` / `fcitx5_switcher` の5プラグインを導入し、WS↔モニター固定を解いて scratchpad・窓退避・迷子窓救出・IME自動切替を実現する。

**Architecture:** 既存 `home-manager/desktop/pyprland/default.nix` が生成する単一 `~/.config/pypr/config.toml` を拡張する（pyprland は単一 toml しか読まない）。keybind は `home-manager/desktop/hyprland/lua/keybinds.lua`、WS固定解除は `monitors/desk.lua`・`bed.lua` を編集。常駐中の `pyprland.service` が全プラグインを動かすため systemd の追加は不要。

**Tech Stack:** Nix (home-manager), pyprland (TOML config), hyprlua (Lua による Hyprland 設定), wezterm, btop, fcitx5, vesktop。

## Global Constraints

- 検証は必ず `nix run .#build`（NixOS `.#nixos` 構成をビルド）と `nix run .#fmt -- --fail-on-change`（treefmt / deadnix）の両方を通す。
- ランタイム反映（実機 NixOS）は `nix run .#switch`。ビルドが通ってから実施する。
- コメントは「なぜ」だけを 1〜2 行。設定項目を日本語で言い換えるだけの逐条コメントは書かない（プロジェクト規約）。
- 未使用の Nix let 束縛・関数引数は deadnix が検出するため残さない。
- pyprland のトグルコマンドは `pypr toggle <scratchpad名>`、特殊退避は `pypr toggle_special <name>`、相対WS移動は `pypr change_workspace <±N>`、迷子窓は `pypr lost_windows`。
- scratchpad の match key は `class`。wezterm は `wezterm start --class <name>` で window class を上書きする。

## 確定済みの外部仕様（ローカルソース `~/ghq/github.com/hyprland-community/pyprland` で確認済み）

- `[workspaces_follow_focus]`: オプションは `max_workspaces`（既定10, 巡回上限）のみ。`default_workspaces` は存在しない。コマンド `pypr change_workspace ±N`。
- `[toggle_special]`: `name`（既定 `minimized`）を持つが、`run_toggle_special(special_workspace="minimized")` は**引数を優先し config `name` を読まない**。よって keybind で `pypr toggle_special stash` と明示する（config の `name = "stash"` はドキュメント目的で残す）。
- `[fcitx5_switcher]`: `active_classes` / `inactive_classes` / `active_titles` / `inactive_titles` の4リスト（`schema.py` / plugin 確認）。
- `[scratchpads.<名>]`: `command`(必須) / `class`(recommended) / `match_by`(既定 `pid`) / `size`(既定 `80% 80%`) / `position` / `lazy`(既定 true) / `margin`(既定60) 他。`match_by="pid"` は launch した PID で追跡するが、wezterm は mux サーバ接続で PID が外れうるため、`class` を与える3つは `match_by = "class"` を明示する。

## 現状の事実（調査済み）

- `pyprland/default.nix` は `wallpapers` のみを `plugins` に持ち、`xdg.configFile."pypr/config.toml".text` を生成している。関数引数は `{ config, pkgs, dotfilesDir, ... }`。
- `btop` は未インストール（scratchpad btop 用に追加が必要）。
- vesktop は `vesktop` コマンドで起動、window class は `vesktop`。現状 `SUPER+D` が `exec_cmd("vesktop")`。
- keybinds.lua の該当行: `SUPER+I`=`focus({workspace="e-1"})` / `SUPER+O`=`focus({workspace="e+1"})` / `SUPER+S`=`workspace.toggle_special("magic")` / `SUPER+SHIFT+S`=`window.move({workspace="special:magic"})` / `SUPER+D`=`exec_cmd("vesktop")`。
- `monitors/desk.lua` は monitor 定義4行 + `workspace_rule` 3行。`monitors/bed.lua` は monitor 定義4行 + `for i=1,10` の `workspace_rule` ループ。
- `mode.sh` は `workspace_rule` を参照していない（`hyprctl activeworkspace` で PREV_WS を取り、reload 後に復元するのみ）。よって WS固定撤去による mode.sh のコード変更は不要。ただしモード切替の `hyprctl reload` でモニターが enable/disable され、pyprland がそのイベントに反応する可能性があるため実機確認する。

---

## Task 1: pyprland config.toml に5プラグインを追加 + btop パッケージ追加

**Files:**

- Modify: `home-manager/desktop/pyprland/default.nix`（`plugins` 配列と各プラグインセクション、`home.packages`）

**Interfaces:**

- Consumes: 既存の `config` / `dotfilesDir` 関数引数、既存 `[wallpapers]` セクション。
- Produces: `~/.config/pypr/config.toml` に `workspaces_follow_focus` / `scratchpads.{term,btop,vesktop}` / `toggle_special`(name=stash) / `lost_windows` / `fcitx5_switcher` を定義。scratchpad 名 `term` / `btop` / `vesktop`、特殊WS名 `stash`、scratch class `scratch-term` / `scratch-btop`。keybinds.lua（Task 3）がこれらの名前を参照する。

- [ ] **Step 1: config.toml のテキストブロックを差し替える**

`home-manager/desktop/pyprland/default.nix` の `xdg.configFile."pypr/config.toml".text = ''...''` を以下に置き換える（既存 `[wallpapers]` は温存）:

```nix
  xdg.configFile."pypr/config.toml".text = ''
    [pyprland]
    plugins = [
      "wallpapers",
      "workspaces_follow_focus",
      "scratchpads",
      "toggle_special",
      "lost_windows",
      "fcitx5_switcher",
    ]

    [wallpapers]
    path = "${dotfilesDir}/images/wallpaper"
    interval = 30
    extensions = ["jpg", "jpeg", "png", "webp"]
    command = "${config.home.homeDirectory}/.config/hypr/scripts/wallpaper/set.sh [file]"
    post_command = "${config.home.homeDirectory}/.config/hypr/scripts/wallpaper/post.sh [file]"

    # change_workspace の巡回上限。他のオプションは無い。
    [workspaces_follow_focus]
    max_workspaces = 10

    # native special:magic と衝突しない退避先。
    [toggle_special]
    name = "stash"

    # match_by="class": wezterm は mux 接続で PID 追跡が外れうるため class 一致で追う。
    [scratchpads.term]
    command = "wezterm start --class scratch-term"
    class = "scratch-term"
    match_by = "class"
    size = "60% 60%"
    position = "20% 5%"
    lazy = true

    [scratchpads.btop]
    command = "wezterm start --class scratch-btop -- btop"
    class = "scratch-btop"
    match_by = "class"
    size = "70% 70%"
    position = "15% 5%"
    lazy = true

    [scratchpads.vesktop]
    command = "vesktop"
    class = "vesktop"
    match_by = "class"
    size = "60% 70%"
    position = "20% 5%"
    lazy = true

    # 端末・ゲームでは IME を自動 OFF。ゲーム class は switch 後に採取して追加(Task 4)。
    [fcitx5_switcher]
    active_classes = []
    inactive_classes = ["scratch-term", "scratch-btop", "org.wezfurlong.wezterm"]
    active_titles = []
    inactive_titles = []
  '';
```

- [ ] **Step 2: btop を home.packages に追加**

同ファイルの `home.packages = [ pkgs.pyprland ];` を以下に変更（btop は scratchpad で使う）:

```nix
  home.packages = [
    pkgs.pyprland
    pkgs.btop
  ];
```

- [ ] **Step 3: ビルドで Nix 評価と toml 生成を検証**

Run: `nix run .#build`
Expected: エラーなくビルド完了（`nom` のログ末尾が失敗を出さない）。

- [ ] **Step 4: フォーマット確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 差分なし・deadnix 指摘なしで終了（exit 0）。

- [ ] **Step 5: Commit**

```bash
git add home-manager/desktop/pyprland/default.nix
git commit -m "feat(pyprland): 5プラグイン(follow_focus/scratchpads/toggle_special/lost_windows/fcitx5)を追加"
```

---

## Task 2: monitors/desk.lua・bed.lua の workspace_rule を撤去

**Files:**

- Modify: `home-manager/desktop/hyprland/monitors/desk.lua`（`workspace_rule` 3行を削除）
- Modify: `home-manager/desktop/hyprland/monitors/bed.lua`（`workspace_rule` ループを削除）

**Interfaces:**

- Consumes: なし（monitor 定義行はそのまま）。
- Produces: WS↔モニター固定が消え、follow_focus が前提とする「どのWSもフォーカス中モニターへ来る」状態の下地。

- [ ] **Step 1: desk.lua から workspace_rule を削除**

`home-manager/desktop/hyprland/monitors/desk.lua` を以下の内容にする（monitor 定義4行のみ残す）:

```lua
hl.monitor({ output = "DP-3", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "2560x1440@180", position = "1920x0", scale = 1 })
hl.monitor({ output = "DP-1", mode = "1920x1080@100", position = "4480x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", disabled = true })
```

- [ ] **Step 2: bed.lua から workspace_rule ループを削除**

`home-manager/desktop/hyprland/monitors/bed.lua` を以下の内容にする（monitor 定義4行のみ残す）:

```lua
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-3", disabled = true })
hl.monitor({ output = "DP-2", disabled = true })
hl.monitor({ output = "DP-1", disabled = true })
```

- [ ] **Step 3: ビルド検証**

Run: `nix run .#build`
Expected: エラーなくビルド完了。

- [ ] **Step 4: フォーマット確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: exit 0（差分なし）。

- [ ] **Step 5: Commit**

```bash
git add home-manager/desktop/hyprland/monitors/desk.lua home-manager/desktop/hyprland/monitors/bed.lua
git commit -m "refactor(hyprland): WS↔モニター固定を撤去(follow_focus前提)"
```

---

## Task 3: keybinds.lua を pyprland 連携に更新

**Files:**

- Modify: `home-manager/desktop/hyprland/lua/keybinds.lua`（アプリ起動節・ワークスペース前後移動節・スペシャルワークスペース節）

**Interfaces:**

- Consumes: Task 1 が定義した scratchpad 名 `term`/`btop`/`vesktop`、特殊WS名 `stash`（`pypr toggle_special stash` と明示）、`pypr change_workspace` / `pypr lost_windows`。
- Produces: ユーザー操作キーの最終形。

- [ ] **Step 1: 相対WS移動を change_workspace に変更**

`home-manager/desktop/hyprland/lua/keybinds.lua` の以下2行:

```lua
hl.bind(mainMod .. " + I", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + O", hl.dsp.focus({ workspace = "e+1" }))
```

を次に置き換える（follow_focus を尊重した隣接WS移動）:

```lua
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("pypr change_workspace -1"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("pypr change_workspace +1"))
```

> `SUPER+SHIFT+I/O`（窓を隣WSへ move）は native のまま変更しない。

- [ ] **Step 2: SUPER+D を vesktop scratchpad トグルに変更**

以下の行:

```lua
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("vesktop"))
```

を次に置き換える:

```lua
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("pypr toggle vesktop"))
```

- [ ] **Step 3: scratchpad term / btop のキーを追加**

Step 2 で変更した `SUPER+D` の行の直後に以下2行を追加する:

```lua
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("pypr toggle term"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("pypr toggle btop"))
```

- [ ] **Step 4: スペシャルワークスペース節を toggle_special に置換**

以下の2行:

```lua
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
```

を次に置き換える（`SUPER+SHIFT+S` は削除し、退避/復帰を `SUPER+S` の toggle_special に一本化。`SUPER+SHIFT+M` に lost_windows を追加）:

```lua
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("pypr toggle_special stash"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("pypr lost_windows"))
```

> `pypr toggle_special` は引数なしだと既定 `minimized` を使い config の `name` を読まないため、`stash` を明示する。

- [ ] **Step 5: ビルド検証**

Run: `nix run .#build`
Expected: エラーなくビルド完了。

- [ ] **Step 6: フォーマット確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: exit 0。

- [ ] **Step 7: Commit**

```bash
git add home-manager/desktop/hyprland/lua/keybinds.lua
git commit -m "feat(hyprland): keybind を pyprland 連携に更新(scratchpad/toggle_special/change_workspace/lost_windows)"
```

---

## Task 4: 実機反映・ランタイム検証・class 実値差し替え

**Files:**

- Modify: `home-manager/desktop/pyprland/default.nix`（`[fcitx5_switcher].inactive_classes` にゲーム class を追記、wezterm class の実値確定）

**Interfaces:**

- Consumes: Task 1〜3 の全変更。
- Produces: 実機で全プラグインが動作する最終状態。

- [ ] **Step 1: 実機に反映**

Run: `nix run .#switch`
Expected: `nixos-rebuild switch` が成功。

- [ ] **Step 2: pyprland がプラグインをエラーなく読み込んでいるか確認**

Run: `systemctl --user status pyprland` と `journalctl --user -u pyprland -n 50 --no-pager`
Expected: `active (running)`。ログに `plugin ... not found` / traceback が無い。

- [ ] **Step 3: follow_focus と scratchpad と toggle_special を手動確認**

- 中央モニターにフォーカスし `SUPER+2` → WS2 が中央へ来る。`SUPER+I` / `SUPER+O` で隣接WSへ移動。
- `SUPER+Z`（wezterm term）/ `SUPER+X`（btop）/ `SUPER+D`（vesktop）でそれぞれトグル表示・再押下で隠れる。
- `SUPER+S` でフォーカス窓が退避 → 再押下で復帰。
- `SUPER+SHIFT+M` がエラーを出さない。

Expected: 上記が想定通り。scratchpad が出ない場合は Step 4（class 確認）へ。

- [ ] **Step 4: 実 window class を採取**

Run: 各アプリ（wezterm 通常窓、scratch-term、scratch-btop、nikke ゲーム起動後）にフォーカスした状態で
`hyprctl clients -j | jq -r '.[] | "\(.class)\t\(.title)"'`
Expected: `scratch-term` / `scratch-btop` が scratchpad 窓に出ていること、wezterm 通常窓の class（暫定 `org.wezfurlong.wezterm`）の実値、nikke の class を得る。

> `wezterm start --class <name>` が class に反映されない場合は、pyprland 側 `[scratchpads.*]` の `class` を実 class に合わせるか、`match_by = "initialClass"` 等へ調整する（実測値に従う）。

- [ ] **Step 5: fcitx5_switcher の class を実値へ差し替え**

`home-manager/desktop/pyprland/default.nix` の `[fcitx5_switcher].inactive_classes` を Step 4 の実測値に更新（wezterm 実 class を確定し、nikke の class を追加）。例:

```
    inactive_classes = ["scratch-term", "scratch-btop", "<wezterm実class>", "<nikke実class>"]
```

- [ ] **Step 6: 再ビルド・整形・反映**

Run: `nix run .#build && nix run .#fmt -- --fail-on-change && nix run .#switch`
Expected: すべて成功。wezterm / ゲームにフォーカスで fcitx5 が自動 OFF、他アプリで手動切替可。

- [ ] **Step 7: bed/desk モード切替の回帰確認**

Run: `SUPER+SHIFT+B`（bed）→ `SUPER+SHIFT+D`（desk）
Expected: モニター構成が切り替わり、壁紙(awww)・waybar が従来通り再生成される。切替直後のアクティブWSが極端に壊れない（follow_focus と reload の相互作用チェック）。異常があれば `mode.sh` の PREV_WS 復元まわりを調整する。

- [ ] **Step 8: Commit**

```bash
git add home-manager/desktop/pyprland/default.nix
git commit -m "fix(pyprland): fcitx5_switcher の inactive_classes を実測 class に確定"
```

- [ ] **Step 9: todo.md を更新**

`todo.md` の「pyprland の導入」節を消化済みにし、`monitors` は「hotplug 反応型で bed/desk プロファイルトグルに不適のため見送り」と記す。

```bash
git add todo.md
git commit -m "docs(todo): pyprland プラグイン導入を消化・monitorsは見送りを明記"
```

---

## Self-Review（spec 突合）

- workspaces_follow_focus … Task 1(config max_workspaces) + Task 2(WS固定撤去) + Task 3(change_workspace) → カバー。
- scratchpads(term/btop/vesktop) … Task 1(config + btop pkg) + Task 3(keybind Z/X/D) → カバー。
- toggle_special(native置換, SHIFT+S削除) … Task 1(config name=stash) + Task 3(Step 4) → カバー。
- lost_windows … Task 3(SUPER+SHIFT+M) → カバー。
- fcitx5_switcher … Task 1(config) + Task 4(実class差し替え) → カバー。
- monitors 見送り・mode.sh 維持 … Task 4 Step 7 で回帰確認、コード変更は不要（mode.sh は workspace_rule 非依存）。todo 反映は Task 4 Step 9。
- Global Constraints の build/fmt は各タスクに配置済み。プレースホルダは Task 4 で採取する class 実値のみで、採取手順(Step 4)を明示済み。
  </content>
