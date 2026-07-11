# screenshot.sh 特定モニター固定スクショ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `screenshot.sh output` にモニター名引数を追加し、`mainMod+ALT+P` で DP-3 を常に全画面撮影できるようにする。

**Architecture:** 既存 `output` モードを拡張。第2引数があればそのモニターを `hyprctl monitors` で存在確認して撮影、無ければ通知して撮らずに終了。引数なしは現行のフォーカス中撮影を維持（後方互換）。モニター名リテラルは keybind 側に持たせる。

**Tech Stack:** bash / grim / slurp / hyprctl / jq / home-manager (Hyprland lua keybind)

## Global Constraints

- 機能ディレクトリの `default.nix` にパッケージ直書き禁止（今回はスクリプト・lua のみ変更、パッケージ追加なし）。
- `../` で遡る相対パス参照禁止。
- コメントは「なぜ」だけ 1〜2 行。逐条コメント禁止。
- 反映は home-manager 生成物のため `nix run .#build` で通してから `nix run .#switch`。手動配置しない。
- `nix run .#fmt -- --fail-on-change` を通す。

---

### Task 1: `output` モードにモニター名引数を追加

**Files:**

- Modify: `home-manager/desktop/hyprland/scripts/screenshot.sh:28-31`（`output)` ケース）

**Interfaces:**

- Consumes: なし（既存 `mode="$1"`、`base_dir`、`monitor`、`grim -o "$monitor"` を流用）
- Produces: 呼び出し規約 `screenshot.sh output [MONITOR_NAME]`。引数ありでその画面固定、無しでフォーカス中。

- [ ] **Step 1: `output)` ケースを差し替え**

`screenshot.sh` の現状:

```bash
output)
  monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name // "unknown"')
  out_dir="${base_dir}/output/${monitor}"
  ;;
```

を次に置き換える:

```bash
output)
  target="${2:-}"
  if [ -n "$target" ]; then
    # 指定モニターの存在確認。無ければ撮らずに通知して終了（誤った画面を撮らない）
    exists=$(hyprctl monitors -j | jq -r --arg n "$target" 'any(.[]; .name == $n)')
    if [ "$exists" != "true" ]; then
      notify-send -a "screenshot" "スクリーンショット" "モニター ${target} が見つかりません"
      exit 0
    fi
    monitor="$target"
  else
    monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name // "unknown"')
  fi
  out_dir="${base_dir}/output/${monitor}"
  ;;
```

- [ ] **Step 2: bash 構文チェック**

Run: `bash -n home-manager/desktop/hyprland/scripts/screenshot.sh`
Expected: 出力なし・終了コード 0（構文エラー無し）

- [ ] **Step 3: 存在確認ロジックを jq 単体で検証**

実機セッションで、存在するモニターと存在しない名前の両方を確認:

Run: `hyprctl monitors -j | jq -r --arg n "DP-3" 'any(.[]; .name == $n)'`
Expected: desk プロファイルなら `true`

Run: `hyprctl monitors -j | jq -r --arg n "NOPE-9" 'any(.[]; .name == $n)'`
Expected: `false`

- [ ] **Step 4: コミット**

```bash
git add home-manager/desktop/hyprland/scripts/screenshot.sh
git commit -m "feat(screenshot): output モードにモニター名指定を追加"
```

---

### Task 2: `mainMod+ALT+P` に DP-3 固定撮影を割り当て

**Files:**

- Modify: `home-manager/desktop/hyprland/lua/keybinds.lua:29`（スクリーンショット bind 群の末尾に追加）

**Interfaces:**

- Consumes: Task 1 の呼び出し規約 `screenshot.sh output DP-3`
- Produces: なし（最終利用者向け keybind）

- [ ] **Step 1: keybind を1行追加**

`keybinds.lua` の

```lua
hl.bind(mainMod .. " + CTRL + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh output"))
```

の直後に追加:

```lua
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh output DP-3"))
```

- [ ] **Step 2: コミット**

```bash
git add home-manager/desktop/hyprland/lua/keybinds.lua
git commit -m "feat(hyprland): mainMod+ALT+P で DP-3 固定スクショ"
```

---

### Task 3: ビルド・整形・反映して実機確認

**Files:**

- なし（検証のみ）

- [ ] **Step 1: 整形チェック**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なし・終了コード 0

- [ ] **Step 2: ビルド**

Run: `nix run .#build`
Expected: エラーなくビルド完了

- [ ] **Step 3: 反映**

Run: `nix run .#switch`
Expected: 成功。生成された `~/.config/hypr/scripts/screenshot.sh` に Task 1 の変更が反映されている

- [ ] **Step 4: 手動動作確認（desk プロファイル）**

`mainMod+ALT+P` を押す（またはターミナルで `~/.config/hypr/scripts/screenshot.sh output DP-3`）。
Expected:

- DP-3 が接続されていれば `~/Pictures/Screenshots/output/DP-3/<日時>.png` が生成され、通知「... に保存しました」が出る。フォーカスが別画面でも DP-3 が撮れている。
- 引数なし `screenshot.sh output` は従来どおりフォーカス中画面を撮る（後方互換確認）。

- [ ] **Step 5: 不在時の確認**

DP-3 が無い状況（bed プロファイル or DP-3 未接続）で `screenshot.sh output DP-3`。
Expected: 「モニター DP-3 が見つかりません」の通知が出て、ファイルは生成されない。

---

## Self-Review

- **Spec coverage:** output 引数拡張=Task1 / keybind mainMod+ALT+P=Task2 / 不在時通知して撮らない=Task1 Step1 & Task3 Step5 / 反映フロー=Task3。spec 全項目カバー。
- **Placeholder scan:** TODO/TBD なし。全ステップにコマンド・コード・期待値あり。
- **Type consistency:** 呼び出し規約 `screenshot.sh output DP-3` が Task1(Produces)→Task2(Consumes) で一致。変数名 `target`/`exists`/`monitor` 一貫。
