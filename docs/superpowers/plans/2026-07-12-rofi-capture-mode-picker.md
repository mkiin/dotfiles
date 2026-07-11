# rofi キャプチャモードピッカー（BlackNode 風 島 UI）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** スクリーンショット／画面録画のモード選択を、キーバインドの使い分けから rofi 製の島型モードピッカー UI へ置き換える。

**Architecture:** 撮影・録画の本体（`screenshot.sh` / `record.sh`）はロジックを温存し、その手前に BlackNode 風の `rofi -dmenu` 島 UI を 1 枚かぶせる。島テーマは既存 `app-launcher.rasi` と同じく matugen 生成の `themes/colors.rasi` を `@import` して配色連動する。keybind は `Super+P` / `Super+R` をピッカー起動に集約し、region/window/output の個別キーは削除する。録画には範囲(region)モードを新設する。

**Tech Stack:** Nix / home-manager, rofi-wayland, matugen, bash, Hyprland(Wayland), gpu-screen-recorder, slurp/grim

## Global Constraints

- パッケージ本体の宣言は集約 `packages.nix` のみ（機能ディレクトリの `default.nix` に `home.packages` 直書き禁止）。設定は `xdg.configFile` 等の設定機構で行う。
- `../` で親ディレクトリへ遡る相対パス参照を書かない。Nix の同階層参照は `lnk ./file`。rasi 内の `@import` は rofi 標準の同ディレクトリ相対（`themes/` 配下に置くことで `colors.rasi` を遡らず参照する）。
- コメントは「なぜ」だけを 1〜2 行。逐条コメント禁止。設定項目を日本語で言い換えるだけのコメントは書かない。
- 検証は `nix run .#build`（NixOS 構成ビルド）と `nix run .#fmt -- --fail-on-change`（treefmt/deadnix）を必ず両方通す。実機反映は `nix run .#switch`。
- この計画は WSL 上（home-manager）で編集・ビルド検証する。rofi の rasi 構文妥当性・gpu-screen-recorder の実挙動は WSL では確認できないため、実機での動作確認は最終 Task（Task 6）にまとめる。
- 参照元デザイン: `~/ghq/github.com/zhaleff/BlackNode/Configs/.config/rofi/hyprshot/`（`script.sh` / `style.rasi`）。ただし BlackNode の rasi は `@surface`/`@primary` を使うためそのままコピー不可。
- matugen 生成の rofi 色変数（`~/.config/rofi/themes/colors.rasi`）: `background` / `background-alt` / `foreground` / `selected` / `active` / `urgent` / `border-color`。島テーマはこの変数名だけを使う。
- 島 UI のグリフ（既存実績を踏襲）: スクショ camera=`󰹑`、録画 video=`󰻃`、停止=`󰛿`。モード別は本計画で region=`󰩭`・window=`󰖯`・output/monitor=`󰍹` を採用（Nerd Font MDI。実機で欠字なら差し替え可）。
- 島 UI 外で存続させる特殊系 keybind（変更しない）: `Super+Alt+P`→`screenshot.sh output DP-3`、`Super+Ctrl+R`→`record.sh ~/personal/tools/facefusion/media/target`。

## ファイル構成

- Create: `home-manager/desktop/rofi/capture.rasi` … 島テーマ（スクショ／録画で共用。`dynamic:true` で行数可変）
- Create: `home-manager/desktop/rofi/screenshot-menu.sh` … スクショのモードピッカー
- Create: `home-manager/desktop/rofi/record-menu.sh` … 録画のモードピッカー（状態出し分け）
- Modify: `home-manager/desktop/rofi/default.nix` … 上記 3 ファイルを `xdg.configFile` 配線
- Modify: `home-manager/desktop/hyprland/scripts/record.sh` … 範囲録画モードを追加
- Modify: `home-manager/desktop/hyprland/lua/keybinds.lua` … `Super+P`/`Super+R` をピッカー起動へ、個別キー削除
- Modify: `home-manager/desktop/packages.nix` … `gpu-screen-recorder` を集約宣言（是正）

**配置の決定（設計からの具体化）:** 設計では「rofi/ 配下」とだけ決めた。rasi の `@import "colors.rasi"` は同ディレクトリ相対のため、島テーマは既存 `app-launcher.rasi` と同じ `~/.config/rofi/themes/` に置く（`themes/colors.rasi` を遡らず読める）。menu スクリプトは既存 `launch.sh` と同じ `~/.config/rofi/` 直下に置く。サブディレクトリは作らず既存 rofi 構造に合わせる。

---

## Task 1: gpu-screen-recorder を集約 packages.nix へ宣言（是正）

`record.sh` が参照している `gpu-screen-recorder` が集約 `packages.nix` に未宣言（コメント「script dependencies」から漏れている）。CLAUDE.md の集約ルールに従い宣言を追加する。範囲録画（Task 2）の前提でもある。

**Files:**

- Modify: `home-manager/desktop/packages.nix:31-35`

**Interfaces:**

- Produces: `gpu-screen-recorder` を PATH に載せる（`record.sh` / `record-menu.sh` が参照）。

- [ ] **Step 1: packages.nix に gpu-screen-recorder を追加**

`home-manager/desktop/packages.nix` の「script dependencies」ブロックを次に変更する:

```nix
    # script dependencies (screenshot.sh, record.sh)
    grim
    slurp
    jq
    libnotify
    gpu-screen-recorder
```

- [ ] **Step 2: ビルド検証**

Run: `nix run .#build`
Expected: エラーなく完了（`gpu-screen-recorder` が nixpkgs から解決される）。

- [ ] **Step 3: フォーマット検証**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なし（PASS）。

- [ ] **Step 4: コミット**

```bash
git add home-manager/desktop/packages.nix
git commit -m "fix(packages): gpu-screen-recorder を集約 packages.nix に宣言"
```

---

## Task 2: record.sh に範囲録画モードを追加

現状の `record.sh` は全体録画トグルのみ。第 1 引数 `region` で範囲録画を新設する。範囲＝録画開始時の固定矩形（ウィンドウ非追従）。gsr が範囲非対応なら開始せず通知して終了（wf-recorder フォールバックはしない）。既存の全体録画・停止・facefusion 用ディレクトリ指定は互換維持する。

**Files:**

- Modify: `home-manager/desktop/hyprland/scripts/record.sh`

**Interfaces:**

- Consumes: `gpu-screen-recorder`（Task 1）、`slurp`。
- Produces: 呼び出し規約 —
  - `record.sh`（引数なし）→ フォーカスモニタ全体録画トグル（既存互換）
  - `record.sh region` → 範囲録画開始
  - `record.sh <dir>` → 指定ディレクトリへ全体録画（既存 facefusion 互換）
  - 録画中はいずれの呼び出しでも `pid_file` を検出して停止する（既存互換）。

- [ ] **Step 1: record.sh を範囲対応版に書き換える**

`home-manager/desktop/hyprland/scripts/record.sh` を全置換する:

```bash
#!/usr/bin/env bash
set -euo pipefail

pid_file="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder.pid"

# 録画中ならモードに関わらず停止（SIGINT で moov atom を確定させる）
if [[ -f $pid_file ]] && pid=$(<"$pid_file") && kill -0 "$pid" 2>/dev/null; then
  kill -SIGINT "$pid"
  for _ in {1..50}; do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1
  done
  rm -f "$pid_file"
  notify-send -a "record" "画面録画を停止" "保存しました"
  exit 0
fi

# 第 1 引数: region=範囲録画 / 空=全体録画 / それ以外=保存先ディレクトリ指定の全体録画
mode="full"
out_dir="${HOME}/Videos"
case "${1:-}" in
region) mode="region" ;;
"") ;;
*) out_dir="$1" ;;
esac

mkdir -p "$out_dir"
file="$out_dir/rec_$(date +%Y%m%d_%H%M%S).mp4"

if [[ $mode == region ]]; then
  # gsr が region キャプチャに対応していなければ開始せず通知（フォールバックしない）
  if ! gpu-screen-recorder --list-capture-options 2>/dev/null | grep -qw region; then
    notify-send -a "record" "画面録画" "このバージョンの gpu-screen-recorder は範囲録画に対応していません"
    exit 0
  fi
  selection=$(slurp) || exit 0
  # slurp 出力 "X,Y WxH" → gsr の "WxH+X+Y"。マルチモニタで X/Y は負になり得る
  if [[ $selection =~ ^(-?[0-9]+),(-?[0-9]+)[[:space:]]+([0-9]+)x([0-9]+)$ ]]; then
    x=${BASH_REMATCH[1]}
    y=${BASH_REMATCH[2]}
    width=${BASH_REMATCH[3]}
    height=${BASH_REMATCH[4]}
    region="${width}x${height}+${x}+${y}"
  else
    notify-send -a "record" "画面録画" "選択範囲を解釈できませんでした"
    exit 0
  fi
  # 【実機で要確定】-w region / 領域引数名は gpu-screen-recorder --help を正とする（Task 6）
  gpu-screen-recorder -w region -region "$region" -f 60 -k h264 -a default_output -o "$file" >/dev/null 2>&1 &
  echo $! >"$pid_file"
  notify-send -a "record" "範囲録画を開始" "$(basename "$file")"
  exit 0
fi

monitor=$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')
gpu-screen-recorder -w "$monitor" -f 60 -k h264 -a default_output -o "$file" >/dev/null 2>&1 &
echo $! >"$pid_file"
notify-send -a "record" "画面録画を開始" "$monitor → $(basename "$file")"
```

- [ ] **Step 2: bash 構文チェック**

Run: `bash -n home-manager/desktop/hyprland/scripts/record.sh`
Expected: 出力なし（構文 OK）。

- [ ] **Step 3: ビルド・フォーマット検証**

Run: `nix run .#build && nix run .#fmt -- --fail-on-change`
Expected: 両方 PASS（シェルスクリプトは source 配置なので配線が壊れていないことの確認）。

- [ ] **Step 4: コミット**

```bash
git add home-manager/desktop/hyprland/scripts/record.sh
git commit -m "feat(record): 範囲録画モードを追加（gsr 一本・非対応時は通知して終了）"
```

---

## Task 3: 島テーマ capture.rasi を作成・配線

BlackNode の `style.rasi` を土台に、この dotfiles の色変数名へ置換した島テーマを作る。スクショ／録画で共用し、`dynamic:true` で行数可変にする。

**Files:**

- Create: `home-manager/desktop/rofi/capture.rasi`
- Modify: `home-manager/desktop/rofi/default.nix`

**Interfaces:**

- Consumes: `~/.config/rofi/themes/colors.rasi`（matugen 生成、既存）。
- Produces: `~/.config/rofi/themes/capture.rasi`（Task 4/5 の menu が `-theme` で参照）。

- [ ] **Step 1: capture.rasi を作成**

Create `home-manager/desktop/rofi/capture.rasi`:

```rasi
@import "colors.rasi"

configuration {
    font:            "JetBrains Mono Nerd Font 12";
    disable-history: true;
    hide-scrollbar:  true;
}

* {
    background-color: @background;
    text-color:       @foreground;
}

window {
    transparency:     "real";
    location:         east;
    anchor:           east;
    width:            100px;
    x-offset:         -15px;
    y-offset:         0px;
    border-radius:    12px;
    background-color: @background;
}

mainbox {
    children:         [ "listview" ];
    margin:           8px;
    background-color: transparent;
}

listview {
    columns:          1;
    layout:           vertical;
    spacing:          0px;
    cycle:            true;
    dynamic:          true;
    scrollbar:        false;
    background-color: transparent;
}

element {
    orientation:      vertical;
    padding:          14px 0px;
    border-radius:    8px;
    background-color: transparent;
    text-color:       @foreground;
}

element-text {
    font:             "JetBrains Mono Nerd Font 20";
    horizontal-align: 0.5;
    vertical-align:   0.5;
    background-color: transparent;
    text-color:       inherit;
}

element selected {
    text-color:    @active;
    border:        1px;
    border-color:  @active;
    border-radius: 8px;
}
```

- [ ] **Step 2: default.nix に配線を追加**

`home-manager/desktop/rofi/default.nix` の `xdg.configFile` に 1 行追加する:

```nix
    "rofi/themes/capture.rasi".source = lnk ./capture.rasi;
```

追加後の該当ブロックは次のようになる:

```nix
  xdg.configFile = {
    "rofi/config.rasi".source = lnk ./config.rasi;
    "rofi/themes/app-launcher.rasi".source = lnk ./app-launcher.rasi;
    "rofi/themes/capture.rasi".source = lnk ./capture.rasi;
    "rofi/launch.sh".source = lnk ./launch.sh;
  };
```

- [ ] **Step 3: ビルド・フォーマット検証**

Run: `nix run .#build && nix run .#fmt -- --fail-on-change`
Expected: 両方 PASS（`capture.rasi` が `~/.config/rofi/themes/` に配線される）。

- [ ] **Step 4: コミット**

```bash
git add home-manager/desktop/rofi/capture.rasi home-manager/desktop/rofi/default.nix
git commit -m "feat(rofi): キャプチャピッカー用の島テーマ capture.rasi を追加"
```

---

## Task 4: スクリーンショットピッカーと keybind 一本化

スクショのモードピッカー `screenshot-menu.sh` を作り、`Super+P` を差し替え、window/output の個別キーを削除する。

**Files:**

- Create: `home-manager/desktop/rofi/screenshot-menu.sh`
- Modify: `home-manager/desktop/rofi/default.nix`
- Modify: `home-manager/desktop/hyprland/lua/keybinds.lua:27-30`

**Interfaces:**

- Consumes: `~/.config/rofi/themes/capture.rasi`（Task 3）、`~/.config/hypr/scripts/screenshot.sh region|window|output`（既存・無改修）。
- Produces: `~/.config/rofi/screenshot-menu.sh`。

- [ ] **Step 1: screenshot-menu.sh を作成**

Create `home-manager/desktop/rofi/screenshot-menu.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/themes/capture.rasi"
scripts="$HOME/.config/hypr/scripts"

# 󰩭 region / 󰖯 window / 󰍹 output
sel=$(printf '%s\n' "󰩭" "󰖯" "󰍹" | rofi -dmenu -theme "$theme") || exit 0

case "$sel" in
"󰩭") "$scripts/screenshot.sh" region ;;
"󰖯") "$scripts/screenshot.sh" window ;;
"󰍹") "$scripts/screenshot.sh" output ;;
esac
```

- [ ] **Step 2: bash 構文チェック**

Run: `bash -n home-manager/desktop/rofi/screenshot-menu.sh`
Expected: 出力なし。

- [ ] **Step 3: default.nix に配線を追加**

`home-manager/desktop/rofi/default.nix` の `xdg.configFile` に追加:

```nix
    "rofi/screenshot-menu.sh".source = lnk ./screenshot-menu.sh;
```

- [ ] **Step 4: keybinds.lua を一本化**

`home-manager/desktop/hyprland/lua/keybinds.lua` の 27-30 行「スクリーンショット」ブロックを次に置換する（`Super+Alt+P` の DP-3 は残す）:

```lua
-- スクリーンショット (Super+P で島 UI。DP-3 直撮りは特殊系として存続)
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/.config/rofi/screenshot-menu.sh"))
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh output DP-3"))
```

- [ ] **Step 5: ビルド・フォーマット検証**

Run: `nix run .#build && nix run .#fmt -- --fail-on-change`
Expected: 両方 PASS。

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/rofi/screenshot-menu.sh home-manager/desktop/rofi/default.nix home-manager/desktop/hyprland/lua/keybinds.lua
git commit -m "feat(rofi): スクショのモードピッカーを追加し Super+P を島 UI に一本化"
```

---

## Task 5: 録画ピッカーと keybind 一本化

録画のモードピッカー `record-menu.sh` を作る。録画状態を `pid_file`/`kill -0` で判定し、非録画中は「全体／範囲」、録画中は「停止」だけを出す。`Super+R` を差し替える（facefusion 用 `Super+Ctrl+R` は残す）。

**Files:**

- Create: `home-manager/desktop/rofi/record-menu.sh`
- Modify: `home-manager/desktop/rofi/default.nix`
- Modify: `home-manager/desktop/hyprland/lua/keybinds.lua:33-37`

**Interfaces:**

- Consumes: `~/.config/rofi/themes/capture.rasi`（Task 3）、`~/.config/hypr/scripts/record.sh`（Task 2 で region 対応済み。`record.sh` / `record.sh region` を呼ぶ。停止は `record.sh` 再呼びで pid_file 検出）。
- Produces: `~/.config/rofi/record-menu.sh`。

- [ ] **Step 1: record-menu.sh を作成**

Create `home-manager/desktop/rofi/record-menu.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

theme="$HOME/.config/rofi/themes/capture.rasi"
record="$HOME/.config/hypr/scripts/record.sh"
pid_file="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder.pid"

if [[ -f $pid_file ]] && pid=$(<"$pid_file") && kill -0 "$pid" 2>/dev/null; then
  # 録画中: 󰛿 停止のみ
  sel=$(printf '%s\n' "󰛿" | rofi -dmenu -theme "$theme") || exit 0
  [[ -n $sel ]] && "$record"
  exit 0
fi

# 非録画中: 󰻃 全体 / 󰩭 範囲
sel=$(printf '%s\n' "󰻃" "󰩭" | rofi -dmenu -theme "$theme") || exit 0
case "$sel" in
"󰻃") "$record" ;;
"󰩭") "$record" region ;;
esac
```

- [ ] **Step 2: bash 構文チェック**

Run: `bash -n home-manager/desktop/rofi/record-menu.sh`
Expected: 出力なし。

- [ ] **Step 3: default.nix に配線を追加**

`home-manager/desktop/rofi/default.nix` の `xdg.configFile` に追加。追加後のブロック全体は次のようになる:

```nix
  xdg.configFile = {
    "rofi/config.rasi".source = lnk ./config.rasi;
    "rofi/themes/app-launcher.rasi".source = lnk ./app-launcher.rasi;
    "rofi/themes/capture.rasi".source = lnk ./capture.rasi;
    "rofi/launch.sh".source = lnk ./launch.sh;
    "rofi/screenshot-menu.sh".source = lnk ./screenshot-menu.sh;
    "rofi/record-menu.sh".source = lnk ./record-menu.sh;
  };
```

- [ ] **Step 4: keybinds.lua を差し替え**

`home-manager/desktop/hyprland/lua/keybinds.lua` の 32-37 行「画面録画」ブロックを次に置換する（facefusion 用は残す）:

```lua
-- 画面録画 (Super+R で島 UI。facefusion ターゲット録画は特殊系として存続)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/rofi/record-menu.sh"))
hl.bind(
	mainMod .. " + CTRL + R",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/record.sh ~/personal/tools/facefusion/media/target")
)
```

- [ ] **Step 5: ビルド・フォーマット検証**

Run: `nix run .#build && nix run .#fmt -- --fail-on-change`
Expected: 両方 PASS。

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/rofi/record-menu.sh home-manager/desktop/rofi/default.nix home-manager/desktop/hyprland/lua/keybinds.lua
git commit -m "feat(rofi): 録画のモードピッカーを追加し Super+R を島 UI に一本化"
```

---

## Task 6: 実機反映と受け入れ確認

WSL では確認できない rofi rasi の描画・gpu-screen-recorder の範囲録画を実機で確定・検証する。

**Files:**

- 必要に応じて Modify: `home-manager/desktop/hyprland/scripts/record.sh`（gsr の領域引数名を実機の `--help` に合わせて確定）

- [ ] **Step 1: 実機で pull & switch**

実機 NixOS 側で:
Run: `git pull && nix run .#switch`
Expected: 反映完了。

- [ ] **Step 2: gpu-screen-recorder の領域引数を確定**

実機で:
Run: `gpu-screen-recorder --version && gpu-screen-recorder --help && gpu-screen-recorder --list-capture-options`
確認: (1) `region` がキャプチャ対象一覧にあるか、(2) 領域座標の引数名と形式（`-region WxH+X+Y` とは限らない）、(3) 負座標を受理するか、(4) Wayland で使えるか。
`record.sh` の `gpu-screen-recorder -w region -region "$region" ...` の引数名・形式が `--help` と食い違う場合は `record.sh` を修正し、`bash -n` → `git commit` → `nix run .#switch` で反映する。

- [ ] **Step 3: スクショの受け入れ確認**

`Super+P` を押す。
Expected: 右端に縦型の島が出て region/window/output のグリフが並ぶ。配色が現壁紙の matugen テーマに連動。region を選ぶと slurp で範囲選択でき、従来どおり保存先分け・クリップボードコピー・日本語通知が動く。window/output も同様。グリフが欠字（□表示）なら `capture.rasi` 参照元のグリフを差し替える。

- [ ] **Step 4: 録画の受け入れ確認**

`Super+R` を押す。
Expected: 非録画中は「全体／範囲」の 2 グリフ、録画中は「停止」1 グリフが出る。範囲を選ぶと slurp で領域選択して録画が始まり、`Super+R`→停止で正常な mp4 が保存される。gsr が範囲非対応の場合は範囲選択で「対応していません」と通知され録画は始まらない。

- [ ] **Step 5: 特殊系 keybind の回帰確認**

`Super+Alt+P`（DP-3 直撮り）と `Super+Ctrl+R`（facefusion ディレクトリへ録画）が従来どおり動くことを確認する。

- [ ] **Step 6: （必要時）record.sh 修正をコミット**

Step 2 で `record.sh` を修正した場合:

```bash
git add home-manager/desktop/hyprland/scripts/record.sh
git commit -m "fix(record): gpu-screen-recorder の領域指定引数を実機仕様に合わせて確定"
```

---

## Self-Review

**Spec coverage:**

- BlackNode 調査（rofi 島=モードピッカー）→ 全 Task の前提として反映。
- 撮影本体は無改修 → Task 4 は `screenshot.sh` を呼ぶだけ。
- 録画 region 追加・gsr 一本・非対応時失敗・負座標変換・実機4点 → Task 2 + Task 6 Step 2。
- theme.rasi の色変数名注意（@surface で壊れる）→ Task 3 で dotfiles 変数名を使用。
- keybind 一本化・個別キー削除・特殊系存続 → Task 4/5。
- gpu-screen-recorder 集約是正 → Task 1。
- quickshell 重複はスコープ外 → 触れていない。

**Placeholder scan:** 「実機で要確定」は Task 6 Step 2 に具体手順化済み（プレースホルダではなく検証タスク）。他に TBD/曖昧記述なし。

**Type/呼び出し規約consistency:** `record.sh` の呼び出し規約（`record.sh` / `record.sh region` / `record.sh <dir>`）を Task 2 で定義し、Task 5 の `record-menu.sh` と Task 6 の facefusion keybind が同じ規約で呼ぶ。pid_file パスは全箇所 `${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder.pid` で一致。theme パスは全 menu で `~/.config/rofi/themes/capture.rasi` で一致。
