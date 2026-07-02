# ファイラー neo-tree → oil.nvim 移行 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** LazyVim のメインファイラーを neo-tree.nvim から oil.nvim（バッファ編集型）へ完全移行する。

**Architecture:** neo-tree は LazyVim の `editor.neo-tree` extra 由来なので、`lazyvim.json` から extra を外し、`editor.lua` の neo-tree カスタム spec を削除して撤去する。代わりに `lua/plugins/oil.lua` を新規追加し、旧 neo-tree のファイラーキーマップ（`<leader>e` / `<leader>fe` 系）を oil に張り替える。アイコンは既存の mini.icons をそのまま流用する。

**Tech Stack:** Neovim / LazyVim（main, install_version 8） / lazy.nvim / stevearc/oil.nvim / nvim-mini/mini.icons。設定は home-manager で `xdg.configFile."nvim".source = lnk ./config`（out-of-store symlink）としてデプロイされ、**repo の編集が nvim に即反映**される。

## Global Constraints

- **編集対象は `home-manager/editor/neovim/config/` 配下のみ**。`.nix` ファイルは変更しない（この移行に nix 変更は不要。したがって switch/rebuild も不要で、symlink 経由でライブ反映される）。
- **Lua の整形は treefmt（stylua, インデントはタブ）**。既存 lua ファイルはタブインデント。`nix run .#fmt -- --fail-on-change` が緑であること。
- **コメントは「なぜ」だけ 1〜2 行**（プロジェクト CLAUDE.md 規約）。`enable = true; -- 有効化` のような逐条コメント禁止。
- **アイコン供給は mini.icons を維持**。oil の `dependencies` は `nvim-mini/mini.icons` と書く（このリポジトリの表記統一）。nvim-web-devicons は書かない。
- **mini.diff は残す**（gutter の変更マーカー `▎` は維持）。**mini.files も残す**（`editor.mini-files` extra はそのまま）。
- **oil の隠しファイル方針**: `view_options.show_hidden = false`（dotfiles はデフォルト非表示、`g.` でトグル）。**gitignore フィルタは実装しない**（oil に native 機能が無く、`g.` トグルで出てしまうため今回は見送り。todo.md に記録済み）。
- **削除は trash 送り**: `delete_to_trash = true`（Linux は oil 内蔵の FreeDesktop trash 実装で外部依存なし）。
- **oil 表示は通常バッファ**（vinegar 流儀。float は使わない）。
- **キーマップ衝突なし**の確認: `<leader>e` / `<leader>E` / `<leader>fe` / `<leader>fE` は現状 neo-tree extra 由来のみ（`snacks_explorer` extra は未有効）。neo-tree extra 撤去後はこれらが未バインドになるため、oil の keys spec が唯一のバインドになる。

---

## File Structure

- `home-manager/editor/neovim/config/lazyvim.json` — 有効 extra リスト。`editor.neo-tree` を除去。
- `home-manager/editor/neovim/config/lua/plugins/editor.lua` — neo-tree のカスタム spec ブロック（`<leader>o` / `<leader>fe` キーマップ + filesystem opts）を削除。flash.nvim の exclude から `"neo-tree"` を除去。snacks / flash の他ブロックは温存。
- `home-manager/editor/neovim/config/lua/plugins/oil.lua` — **新規作成**。oil.nvim の spec（keys + opts）。
- `home-manager/editor/neovim/config/lazy-lock.json` — lazy が自動更新（oil.nvim 追加 / neo-tree.nvim 削除）。手編集しない。install/clean 後にコミットする。

---

## Task 1: neo-tree を完全撤去する

**Files:**

- Modify: `home-manager/editor/neovim/config/lazyvim.json:8-9`
- Modify: `home-manager/editor/neovim/config/lua/plugins/editor.lua:23-51`（neo-tree ブロック削除）, `:58`（flash exclude から neo-tree 削除）

**Interfaces:**

- Consumes: なし
- Produces: neo-tree extra とカスタム spec が消え、`<leader>e` / `<leader>E` / `<leader>fe` / `<leader>fE` / `<leader>o` が未バインドになる。Task 2 の oil がこれらを引き継ぐ。

- [ ] **Step 1: `lazyvim.json` から neo-tree extra を除去**

`home-manager/editor/neovim/config/lazyvim.json` を次のように変更（`mini-files` の後ろのカンマを消し、`neo-tree` 行を削除する）:

```json
{
  "extras": [
    "lazyvim.plugins.extras.coding.mini-surround",
    "lazyvim.plugins.extras.coding.neogen",
    "lazyvim.plugins.extras.coding.yanky",
    "lazyvim.plugins.extras.editor.inc-rename",
    "lazyvim.plugins.extras.editor.mini-diff",
    "lazyvim.plugins.extras.editor.mini-files"
  ],
  "install_version": 8,
  "news": {
    "NEWS.md": "11866"
  },
  "version": 8
}
```

- [ ] **Step 2: `editor.lua` の neo-tree spec ブロックを削除**

`home-manager/editor/neovim/config/lua/plugins/editor.lua` から、次のブロック（現状 23〜51 行目、`{ "nvim-neo-tree/neo-tree.nvim", ... }` 全体）を丸ごと削除する:

```lua
	{
		"nvim-neo-tree/neo-tree.nvim",
		keys = {
			{
				"<leader>o",
				function()
					require("neo-tree.command").execute({ focus = true })
				end,
				desc = "Focus NeoTree",
			},
			{
				"<leader>fe",
				function()
					require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
				end,
				desc = "Explorer NeoTree (cwd)",
			},
		},
		opts = {
			filesystem = {
				filtered_items = {
					visible = true,
					hide_dotfiles = false,
					hide_gitignored = false,
				},
				use_libuv_file_watcher = true,
			},
		},
	},
```

削除後、`editor.lua` は snacks ブロック + flash ブロックの 2 つだけを含む `return { ... }` になる。

- [ ] **Step 3: flash.nvim の exclude から `"neo-tree"` を削除**

同ファイルの flash.nvim `opts.search.exclude` から `"neo-tree",` の行（現状 58 行目）を削除する。削除後の exclude:

```lua
				exclude = {
					"notify",
					"cmp_menu",
					"noice",
					"flash_prompt",
					function(win)
						return not vim.api.nvim_win_get_config(win).focusable
					end,
				},
```

- [ ] **Step 4: 整形を確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なしで PASS（終了コード 0）。差分が出たら stylua が整形したので、その結果を採用してコミットに含める。

- [ ] **Step 5: nvim を起動して neo-tree が消えたことを確認**

Run: `nvim` を起動し、以下を確認する（config は symlink なので即反映される）:

- 起動時に lua エラーが出ない。
- `:Lazy` を開き、neo-tree.nvim が「未使用/クリーン対象」になっているか、一覧から消えている。`:Lazy clean` で neo-tree.nvim を削除する（プロンプトが出たら承認）。
- `<leader>e` を押しても何も起きない（未バインド。この時点では正常）。

Expected: エラーなし、neo-tree がクリーンされる、`<leader>e` は未バインド。

- [ ] **Step 6: コミット**

```bash
git add home-manager/editor/neovim/config/lazyvim.json \
        home-manager/editor/neovim/config/lua/plugins/editor.lua \
        home-manager/editor/neovim/config/lazy-lock.json
git commit -m "refactor(nvim): neo-tree を撤去（oil.nvim 移行の準備）"
```

---

## Task 2: oil.nvim を追加する

**Files:**

- Create: `home-manager/editor/neovim/config/lua/plugins/oil.lua`
- Modify: `home-manager/editor/neovim/config/lazy-lock.json`（lazy が自動追加）

**Interfaces:**

- Consumes: Task 1 で未バインドになった `<leader>e` / `<leader>E` / `<leader>fe` / `<leader>fE`。
- Produces: oil.nvim がメインファイラーになる。`<leader>e`（バッファのディレクトリ）/ `<leader>E`（cwd）/ `-`（親ディレクトリ）で開く。

- [ ] **Step 1: `oil.lua` を新規作成**

`home-manager/editor/neovim/config/lua/plugins/oil.lua` を次の内容で作成する:

```lua
return {
	{
		"stevearc/oil.nvim",
		-- ディレクトリ引数や netrw 乗っ取りで即使うため遅延ロードしない
		lazy = false,
		dependencies = { "nvim-mini/mini.icons" },
		keys = {
			{ "<leader>e", "<cmd>Oil<cr>", desc = "Explorer Oil (buffer dir)" },
			{ "<leader>fe", "<cmd>Oil<cr>", desc = "Explorer Oil (buffer dir)" },
			{
				"<leader>E",
				function()
					require("oil").open(vim.uv.cwd())
				end,
				desc = "Explorer Oil (cwd)",
			},
			{
				"<leader>fE",
				function()
					require("oil").open(vim.uv.cwd())
				end,
				desc = "Explorer Oil (cwd)",
			},
			{ "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
		},
		opts = {
			default_file_explorer = true,
			delete_to_trash = true,
			skip_confirm_for_simple_edits = true,
			columns = { "icon" },
			view_options = {
				show_hidden = false,
			},
			keymaps = {
				-- <C-h>/<C-l> はウィンドウ移動に使うため oil 側では無効化
				["<C-h>"] = false,
				["<C-l>"] = false,
			},
		},
	},
}
```

- [ ] **Step 2: 整形を確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なしで PASS。差分が出たら stylua 整形結果を採用する。

- [ ] **Step 3: nvim を起動して oil を自動インストールさせる**

Run: `nvim` を起動する。
Expected: LazyVim が oil.nvim（と依存）を自動インストールし、`:Lazy` に oil.nvim が installed で並ぶ。エラーなし。

- [ ] **Step 4: oil の基本動作を手動確認**

nvim 上で以下を確認する:

- `<leader>e` → カレントバッファのディレクトリが oil バッファで開く（サイドバーではなくカレントウィンドウが置き換わる）。
- ファイル/ディレクトリ名の左に **アイコンが表示**される（mini.icons 経由。JetBrainsMono Nerd Font で描画）。
- `-` → 親ディレクトリへ移動。`<CR>` → ディレクトリに入る / ファイルを開く。
- `g.` → dotfiles（`.` 始まり）の表示/非表示がトグルされる。デフォルトは非表示。
- `<leader>E` → cwd を oil で開く。

Expected: 上記すべてが期待どおり。特にアイコンが豆腐（□）にならず正しいグリフで出ること。

- [ ] **Step 5: trash 削除を確認**

nvim の oil バッファ上で、テスト用ファイルを 1 つ作って削除→確定する:

- `<leader>E` で cwd を開き、`o` などで一時ファイル行を追加 → `:w` で作成確定。
- その行を `dd` で削除 → `:w` で確定（確認ダイアログが出たら承認）。

Run（削除後、シェルで trash を確認）:

```bash
gio list trash:/// 2>/dev/null | tail || ls -la ~/.local/share/Trash/files/ 2>/dev/null | tail
```

Expected: 削除したファイルが（完全削除ではなく）trash に入っている。

- [ ] **Step 6: lazy-lock.json をコミット**

lazy が oil.nvim を追加し lazy-lock.json（symlink 経由で repo 実体）が更新されている。

```bash
git add home-manager/editor/neovim/config/lua/plugins/oil.lua \
        home-manager/editor/neovim/config/lazy-lock.json
git commit -m "feat(nvim): ファイラーを oil.nvim に移行"
```

---

## Task 3: 最終ビルド確認

**Files:** なし（検証のみ）

**Interfaces:**

- Consumes: Task 1・2 の全変更。
- Produces: なし。

- [ ] **Step 1: nix ビルドが壊れていないことを確認**

Run: `nix run .#build`
Expected: ビルド成功。（今回 `.nix` は未変更のため本来影響しないが、リポジトリ運用ルール「push 前にローカル build」に従い確認する。WSL 環境の場合は `nix run nixpkgs#home-manager -- build --flake .#mkiin@wsl` で代替。）

- [ ] **Step 2: 整形の最終確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なしで PASS。

---

## Self-Review

- **Spec coverage:**
  - neo-tree 完全撤去 → Task 1（lazyvim.json extra 除去 + editor.lua spec 削除）。
  - 通常バッファ表示 → Task 2 の oil spec（float 未使用）。
  - mini.files 残す → `editor.mini-files` extra を lazyvim.json に温存（Global Constraints）。
  - 隠しファイルトグル → `show_hidden = false` + `g.`（Task 2 Step 4）。
  - gitignore 非表示は見送り → 実装せず todo.md に記録済み（Global Constraints に明記）。
  - trash 削除 → `delete_to_trash = true`（Task 2 Step 1 / Step 5 で検証）。
  - アイコン流用（mini.icons）→ `dependencies = { "nvim-mini/mini.icons" }`（Task 2 Step 4 で検証）。
  - mini.diff 残す（gutter `▎` 維持）→ 触らない（Global Constraints）。
- **Placeholder scan:** TODO/TBD/曖昧指示なし。各コード step に実コードあり。
- **Type consistency:** キーマップ名（`<leader>e/E/fe/fE`）は Task 1 で解放、Task 2 で再バインドで一貫。`vim.uv.cwd()` は既存 editor.lua と同一 API。
