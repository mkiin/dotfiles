# Hyprland 浮遊感ウィンドウ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hyprlandのタイルウィンドウに atif-1402 風の「影＋透過＋光る縁」を導入し、各ウィンドウが背景から浮いて見える状態にする。

**Architecture:** `appearance.lua` の `general` と `decoration` セクションのみを編集する。グラデーションボーダーは既に `color-scheme.lua` に定義済みのため `border_size` を 1 にして有効化するだけでよい。影は range/render_power を上げて色をデフォルト化、ブラーは質感調整キーを追加、透過を新規に有効化する。アニメーション・色定義・他ファイルは触らない。

**Tech Stack:** Hyprland (configType = "lua", `hl.config()` DSL), Nix home-manager.

## Global Constraints

- 編集対象は `home-manager/desktop/hyprland/lua/appearance.lua` の `general` / `decoration` のみ。`animations` 以降の行・他ファイルは変更しない。
- ベクトル値 `offset` は文字列 `"0 0"` として渡す。
- 反映は Nix のリビルド（`home-manager switch` 等の通常手順）経由。設定ファイルは `~/.config/hypr/appearance.lua` に symlink される。

---

### Task 1: appearance.lua の general / decoration を浮遊感仕様に書き換える

**Files:**

- Modify: `home-manager/desktop/hyprland/lua/appearance.lua:1-34`

**Interfaces:**

- Consumes: `color-scheme.lua` が定義する `col.active_border`（primary→tertiary 45deg グラデーション）。本タスクで `border_size = 1` にすることで初めて可視化される。
- Produces: なし（設定値のみ）。

- [ ] **Step 1: appearance.lua の `general` ブロックを編集する**

`home-manager/desktop/hyprland/lua/appearance.lua` の `general` テーブル（1〜9行目）で `border_size` のみ変更する。`gaps_in` / `gaps_out` / `layout` / `resize_on_border` / `allow_tearing` は据え置き。

変更前:

```lua
	general = {
		gaps_in = 3,
		gaps_out = 8,
		border_size = 0,
		layout = "dwindle",
		resize_on_border = true,
		allow_tearing = false,
	},
```

変更後:

```lua
	general = {
		gaps_in = 3,
		gaps_out = 8,
		border_size = 1,
		layout = "dwindle",
		resize_on_border = true,
		allow_tearing = false,
	},
```

- [ ] **Step 2: `decoration` ブロックを編集する**

同ファイルの `decoration` テーブル（10〜27行目）を以下に置き換える。`rounding` を 14 に、透過3キーを新規追加、`shadow` の range/render_power を引き上げ `offset` を追加し `color`/`color_inactive` を削除、`blur` に質感調整キーを追加する。

変更前:

```lua
	decoration = {
		rounding = 10,
		shadow = {
			enabled = true,
			range = 8,
			render_power = 3,
			color = "rgba(00000080)",
			color_inactive = "rgba(00000033)",
		},
		blur = {
			enabled = true,
			size = 3,
			passes = 2,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
		},
	},
```

変更後:

```lua
	decoration = {
		rounding = 14,
		active_opacity = 0.93,
		inactive_opacity = 0.92,
		fullscreen_opacity = 1.0,
		shadow = {
			enabled = true,
			range = 15,
			render_power = 5,
			offset = "0 0",
		},
		blur = {
			enabled = true,
			size = 1,
			passes = 4,
			contrast = 1.1,
			brightness = 1.1,
			vibrancy = 0.2,
			vibrancy_darkness = 0.2,
			noise = 0.03,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
		},
	},
```

- [ ] **Step 3: 構文と差分を確認する**

Run: `git -C /home/mkiin/ghq/github.com/mkiin/dotfiles diff home-manager/desktop/hyprland/lua/appearance.lua`
Expected: `general` の `border_size` が 0→1、`decoration` が上記の変更後の内容になっている。`animations` 以降（35行目以降）に差分が無いこと。

Run: `luac -p /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/hyprland/lua/appearance.lua 2>&1 || echo "luac unavailable - skip"`
Expected: エラー出力なし（`luac` が無ければ "luac unavailable - skip" でスキップ可。`hl` はランタイムグローバルなので構文チェックのみが目的）。

- [ ] **Step 4: リビルドして反映する**

Run: 通常の Nix リビルド手順（例 `home-manager switch` またはフレーク経由のリビルド）を実行し、Hyprland をリロードする。
Expected: ビルド成功。エラー時は `appearance.lua` のキー名・カンマ・`offset` の文字列化を確認する。

- [ ] **Step 5: 見た目を目視確認する**

Expected:

- ウィンドウがすりガラス状に透ける（背景がブラー越しに見える）
- 各タイルに大きく柔らかい影が付き、背景から浮いて見える
- アクティブウィンドウの縁に primary→tertiary のグラデーションが出る
- 角丸が以前より大きい（14）

強すぎる場合の微調整: 透過は `active_opacity`（0.93→0.95等）、影は `shadow.range`（15→12等）を調整する。

- [ ] **Step 6: コミットする**

```bash
git -C /home/mkiin/ghq/github.com/mkiin/dotfiles add home-manager/desktop/hyprland/lua/appearance.lua
git -C /home/mkiin/ghq/github.com/mkiin/dotfiles commit -m "feat(hyprland): add floating window look (shadow, opacity, gradient border)"
```

---

## Self-Review

- **Spec coverage:** spec の general（border_size=1, gaps据え置き）、decoration（rounding=14, 透過3キー）、shadow（range=15/power=5/offset/色削除）、blur（size=1/passes=4/質感4キー）をすべて Step 1-2 で網羅。対象外（animations・色定義・他ファイル）は Global Constraints で固定。
- **Placeholder scan:** TBD/TODO 等なし。全コードブロックに実値を記載。
- **Type consistency:** `offset` は文字列 `"0 0"`、`color`/`color_inactive` は削除で一貫。`border_size=1` と `color-scheme.lua` のグラデーション定義が整合。
