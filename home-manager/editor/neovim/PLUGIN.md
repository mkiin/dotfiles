# Neovim プラグイン構成

LazyVim をベースにした Neovim 環境のプラグイン一覧である。

`lazy-lock.json` に記録されているプラグインは、ファイラー移行後の最終状態で合計 **48 個**になる。

内訳は次のとおり。

- **LazyVim コア由来**：31 個。LazyVim 本体が既定で導入する土台部分（補完、Treesitter、UI、ライブラリなど）。
- **extra 由来**：6 個。`lazyvim.json` で有効化した LazyVim extra が持ち込むプラグイン。
- **ユーザー独自追加**：11 個。独自の spec ファイル（`lua/plugins/*.lua`）で足したもの。

ファイラーは `nvim-neo-tree/neo-tree.nvim` から `stevearc/oil.nvim` へ移行済みで、neo-tree は使用しない。
oil.nvim をメインファイラーとし、LazyVim extra 由来の `mini.files` を補助ファイラーとして併用する。

なお `lazy-lock.json` には無効化しているプラグイン（`nvim-lint`、`mason.nvim`、`mason-lspconfig.nvim`、`gitsigns.nvim`）も記録として残るため、合計 48 個の中にはこれらも含まれる。

## カテゴリ別プラグイン一覧

各行は「プラグイン名 — 役割 — 由来」の順に記す。

### UI・ステータス

- snacks.nvim — ピッカー、通知、ダッシュボード等を束ねる統合 UI — コア
- noice.nvim — コマンドライン、メッセージ、ポップアップの再構成 — コア
- nui.nvim — noice などが使う UI コンポーネントライブラリ — コア
- bufferline.nvim — バッファをタブ風に並べる上部ライン — コア
- lualine.nvim — ステータスライン — コア
- which-key.nvim — キーマップのポップアップガイド — コア
- trouble.nvim — 診断、参照、quickfix の一覧表示 — コア
- incline.nvim — ウィンドウ右上に出すファイル名 winbar — 独自
- nvim-highlight-colors — カラーコードのインライン表示 — 独自
- image.nvim — sixel バックエンドによる画像表示 — 独自

### カラースキーム・テーマ

- tokyonight.nvim — 既定のカラースキーム — コア
- kanagawa.nvim — dragon テーマを既定に設定 — 独自
- catppuccin — カラースキーム — 独自
- rose-pine — カラースキーム — 独自
- themery.nvim — 上記テーマを切り替えるスイッチャー — 独自

### エディタ・編集

- flash.nvim — ラベルジャンプによる移動 — コア
- mini.ai — 拡張テキストオブジェクト — コア
- mini.pairs — 括弧などの自動ペア入力 — コア
- mini.surround — 囲み記号の追加、削除、変更（マッピングを独自調整） — extra（coding.mini-surround）
- yanky.nvim — ヤンク履歴の管理 — extra（coding.yanky）
- grug-far.nvim — プロジェクト横断の検索置換 — コア
- todo-comments.nvim — TODO 等コメントの強調と一覧 — コア
- ts-comments.nvim — Treesitter ベースのコメントアウト — コア
- smart-newline.nvim — 括弧、HTML タグ内での改行整形 — 独自
- persistence.nvim — セッションの保存と復元 — コア

### ファイラー

- oil.nvim — バッファとしてディレクトリを編集するメインファイラー — 独自
- mini.files — 二列表示の補助ファイラー — extra（editor.mini-files）

### Treesitter

- nvim-treesitter — シンタックスハイライトとパース基盤 — コア
- nvim-treesitter-textobjects — 構文単位のテキストオブジェクト — コア
- nvim-ts-autotag — HTML/JSX タグの自動開閉 — コア

### LSP・補完

- nvim-lspconfig — LSP クライアント設定（tsgo、lua_ls、nixd、bashls 等を構成） — コア
- blink.cmp — 補完エンジン（ソースを lsp と snippets に限定） — コア
- friendly-snippets — スニペット集 — コア
- lazydev.nvim — Neovim Lua 開発向けの型補完 — コア
- inc-rename.nvim — インクリメンタルな LSP リネーム — extra（editor.inc-rename）

### フォーマッタ

- conform.nvim — フォーマッタ統合（oxfmt、deno_fmt、shfmt を言語別に割当） — コア

### Git

- diffview.nvim — 差分とファイル履歴のビューア — 独自
- mini.diff — バッファ内の差分表示（gitsigns を置き換える） — extra（editor.mini-diff）

### コーディング支援

- claudecode.nvim — Claude Code 連携（wezterm ペインで外部起動） — 独自
- neogen — ドキュメンテーションコメントの生成 — extra（coding.neogen）

### アイコン・ライブラリ・基盤

- mini.icons — アイコン供給 — コア
- lazy.nvim — プラグインマネージャ — コア
- LazyVim — 設定フレームワーク本体 — コア
- plenary.nvim — 各種プラグインが使う Lua ユーティリティ — コア

## 有効化している LazyVim extras

`lazyvim.json` で有効化している extra は次のとおり（ファイラー移行に伴い `editor.neo-tree` は除外している）。

- `lazyvim.plugins.extras.coding.mini-surround`
- `lazyvim.plugins.extras.coding.neogen`
- `lazyvim.plugins.extras.coding.yanky`
- `lazyvim.plugins.extras.editor.inc-rename`
- `lazyvim.plugins.extras.editor.mini-diff`
- `lazyvim.plugins.extras.editor.mini-files`

`editor.mini-diff` を有効にしているため、既定の gitsigns は無効化され、差分表示は mini.diff が担う。

## ユーザー独自追加プラグイン

独自の spec で追加したプラグインは 11 個ある。

- oil.nvim — メインファイラー（依存として mini.icons を利用） — `lua/plugins/`（移行で追加）
- image.nvim — 画像表示 — `image.lua`
- claudecode.nvim — Claude Code 連携 — `claudecode.lua`
- diffview.nvim — 差分ビューア — `diffview.lua`
- themery.nvim — テーマスイッチャー — `colorscheme.lua`
- kanagawa.nvim — カラースキーム — `colorscheme.lua`
- catppuccin — カラースキーム — `colorscheme.lua`
- rose-pine — カラースキーム — `colorscheme.lua`
- nvim-highlight-colors — カラーコード表示 — `colorscheme.lua`
- incline.nvim — winbar 表示 — `ui.lua`
- smart-newline.nvim — 改行整形 — `coding.lua`

## 無効化しているプラグイン

LazyVim が既定で導入するが、明示的に無効化しているプラグインがある。

- nvim-lint — `lsp.lua` で `enabled = false`。診断は LSP に任せる方針。
- mason.nvim — `lsp.lua` で `enabled = false`。LSP サーバーやフォーマッタは Nix 側で供給するため、Mason による自動導入を使わない。
- mason-lspconfig.nvim — 上記に同じく `enabled = false`。
- gitsigns.nvim — `editor.mini-diff` extra を有効化したことにより LazyVim 側で無効化される。差分表示は mini.diff が引き継ぐ。

いずれも `lazy-lock.json` にはロック情報が残るため、合計 48 個に含めて数えている。

## アイコン・フォント

アイコンの供給は mini.icons が担い、`nvim-web-devicons` 互換の API を通じて incline などのプラグインへアイコンと色を提供する。
表示に使うフォントは JetBrainsMono Nerd Font で、`nixos/core/fonts/default.nix` にて `nerd-fonts.jetbrains-mono` を導入し、fontconfig の monospace 既定にも `JetBrainsMono Nerd Font` を指定して全端末で統一している。
Nerd Font のグリフと mini.icons の組み合わせにより、ファイラーやステータスラインのアイコンが欠けずに表示される。
