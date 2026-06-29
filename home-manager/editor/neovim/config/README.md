# Neovim 設定

個人用の Neovim 設定ファイルです。[LazyVim](https://www.lazyvim.org/) をベースにしています。

## プラグイン一覧

### AI

| プラグイン                                                    | 説明                                                                                                                                   |
| ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| [folke/sidekick.nvim](https://github.com/folke/sidekick.nvim) | Neovim 内から Claude Code を起動・操作できる AI アシスタント連携。通常モード (`<leader>aa`) と危険モード (`<leader>aA`) を切り替え可能 |

### コーディング支援

| プラグイン                                                                          | 説明                                                   |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------ |
| [saghen/blink.cmp](https://github.com/saghen/blink.cmp)                             | 高速な補完エンジン。LSP とスニペットをソースとして使用 |
| [nvim-mini/mini.surround](https://github.com/echasnovski/mini.surround)             | 括弧やクォートなどの囲み文字を追加・削除・置換         |
| [umutondersu/smart-newline.nvim](https://github.com/umutondersu/smart-newline.nvim) | 括弧や HTML タグ内でのスマートな改行挿入               |
| [neogen](https://github.com/danymat/neogen)                                         | ドキュメントコメントの自動生成 (LazyVim extra)         |
| [yanky.nvim](https://github.com/gbprod/yanky.nvim)                                  | ヤンク履歴の管理・再利用 (LazyVim extra)               |

### カラースキーム

| プラグイン                                                                                  | 説明                                                               |
| ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| [rebelot/kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim)                           | メインテーマ。Dragon テーマを使用                                  |
| [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim)                           | Tokyo Night カラースキーム                                         |
| [catppuccin/nvim](https://github.com/catppuccin/nvim)                                       | Catppuccin カラースキーム                                          |
| [rose-pine/neovim](https://github.com/rose-pine/neovim)                                     | Rosé Pine カラースキーム                                           |
| [zaldih/themery.nvim](https://github.com/zaldih/themery.nvim)                               | テーマ切り替え UI。`<leader>ut` でライブプレビュー付きのテーマ選択 |
| [brenoprata10/nvim-highlight-colors](https://github.com/brenoprata10/nvim-highlight-colors) | カラーコード (#ff0000 など) をインラインでプレビュー表示           |

### エディタ

| プラグイン                                                                        | 説明                                                                      |
| --------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| [folke/snacks.nvim](https://github.com/folke/snacks.nvim)                         | ダッシュボード、ターミナル、ファイルピッカーなどの統合ユーティリティ      |
| [nvim-neo-tree/neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)     | ファイルツリー。隠しファイルや gitignored ファイルも表示                  |
| [folke/flash.nvim](https://github.com/folke/flash.nvim)                           | 高速ジャンプ・移動。`R` で Flash ジャンプ、`S` で Treesitter ベースの選択 |
| [nvim-mini/mini.files](https://github.com/echasnovski/mini.files)                 | カラム型のファイルエクスプローラ                                          |
| [brianhuster/live-preview.nvim](https://github.com/brianhuster/live-preview.nvim) | HTML/Markdown のブラウザライブプレビュー (`<leader>lp`)                   |
| [inc-rename.nvim](https://github.com/smjonas/inc-rename.nvim)                     | インラインでのリネームプレビュー (LazyVim extra)                          |
| [mini.diff](https://github.com/echasnovski/mini.diff)                             | インラインの Git 差分表示 (LazyVim extra)                                 |

### LSP / リント

| プラグイン                                                          | 説明                                                           |
| ------------------------------------------------------------------- | -------------------------------------------------------------- |
| [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)   | LSP クライアント設定。oxlint, emmet, HTML サーバーなどを有効化 |
| [mfussenegger/nvim-lint](https://github.com/mfussenegger/nvim-lint) | 非同期リンター統合 (Markdown のリントは無効化)                 |

### UI

| プラグイン                                                    | 説明                                                          |
| ------------------------------------------------------------- | ------------------------------------------------------------- |
| [b0o/incline.nvim](https://github.com/b0o/incline.nvim)       | ウィンドウ上部にファイル名・診断情報をフローティング表示      |
| [nvim-mini/mini.map](https://github.com/echasnovski/mini.map) | ミニマップ。検索・差分・診断のインジケータ付き (`<leader>um`) |

### 言語サポート (LazyVim extras)

TypeScript, Python, Tailwind CSS, Markdown, TOML, YAML, C/C++ (clangd)

## 必要なもの

- [Neovim](https://neovim.io/) v0.9 以上
- [Git](https://git-scm.com/)
- [Node.js](https://nodejs.org/) (LSP 用)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (検索用)
