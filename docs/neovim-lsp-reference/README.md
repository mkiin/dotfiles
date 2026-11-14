# Neovim LSP 設定の選別資料

出典: ryoppippi/dotfiles の `565a7f2bd17afb06d42fe712e06061e339187666`。
LSP 統合を削除した `8436e09` の直前の状態。
[出典ツリー](https://github.com/ryoppippi/dotfiles/tree/565a7f2bd17afb06d42fe712e06061e339187666/nvim)

このディレクトリの Lua 15ファイルは、出典の `nvim/` 以下のパスを維持してコピーした原文。
Neovim の設定ルート外にあり、自動読込・プラグイン導入・lock 更新の対象ではない。
`require("plugin.…")` なども出典のまま残しているため、ここから直接有効化する設定ではない。
一度移植した追加 UI・自動処理は撤去し、必要時に追加する方針へ変更した。原文は比較用に保持し、以下の表は当時の判断材料として残す。現在の構成は [実行用 README](../../home/base/cli/neovim/README.md) を参照。

## oxfmt / jsonls

| 参照ファイル | 元設定の内容 | 判断 |
| --- | --- | --- |
| [oxfmt.lua](after/lsp/oxfmt.lua) | JS / TS / JSON / CSS / HTML / Markdown / YAML 等へ対象を広げ、設定ファイル・package.json・.git を root marker に指定 | **oxfmt で Neovim の整形も行いたいなら LSP 有効化を推奨**。元の上書きファイルが必要かは別判断 |
| [jsonls.lua](after/lsp/jsonls.lua) | json / jsonc / json5 を対象に、SchemaStore のスキーマ、検証、整形を有効化 | **JSON の設定キー補完・スキーマ検証を使いたいなら推奨**。整形だけが目的なら oxfmt で足りる |

oxfmt は dev-tools.nix に既に宣言されている。現在固定中の nvim-lspconfig は、
`oxfmt --lsp` を起動し、プロジェクトの node_modules/.bin にある実行ファイルを優先する。
標準 filetypes も既に広く、元の上書きを追加すると TOML など標準側の対象を減らす可能性がある。
まず `vim.lsp.enable` に oxfmt を加え、必要な差分だけ after/lsp/oxfmt.lua に置く案を推奨する。
[Oxfmt のエディター統合](https://oxc.rs/docs/guide/usage/formatter/editors.html)

現在固定中の oxfmt 定義は独自の root_dir 関数を持つ。
元設定の root_markers を書くだけでは、その関数の探索条件を置き換えられない。
「.git さえあれば整形したい」のか「oxfmt の設定があるプロジェクトだけにしたい」のかで
root_dir を調整するかを決める。

jsonls を使う場合は `vscode-json-language-server` が必要で、Nix の
`vscode-langservers-extracted` から用意できる。元設定のスキーマ連携には
`b0o/schemastore.nvim` も必要。いずれも今回は新規導入していない。
[サーバーパッケージ](https://github.com/hrsh7th/vscode-langservers-extracted)

併用時の推奨は「jsonls が補完・検証、oxfmt が整形」。
元の jsonls 設定は `format.enable=true` なので、そのままでは整形機能が重複する。
jsonls の整形提供を無効化し、整形要求の client filter / lsp-format の除外設定でも担当を明示する。
JSON5 は元設定が追加した対象であり、必要なら実ファイルでサーバーの対応を確認する。

## nvim-lspconfig/ 以下の全8ファイル

| ファイル | 作られている機能 | 導入判断・接続上の注意 |
| --- | --- | --- |
| [init.lua](lua/plugin/nvim-lspconfig/init.lua) | 共通 capabilities、blink 接続、linked editing、全サーバー有効化、LspAttach、診断リセットコマンド | **構造は採用済み**。元のサーバー一覧には使わない言語も多いので、一覧の丸ごと移植はしない。SchemaStore に依存 |
| [utils.lua](lua/plugin/nvim-lspconfig/utils.lua) | TS の inlay hint 設定、整形能力の切替、プロジェクト内の Node 実行ファイルを優先するコマンド生成 | 複数サーバーで同じ処理が必要なら採用。TS hints は Svelte 用設定等から利用するもので、tsc に自動適用されるものではない |
| [on_attach/init.lua](lua/plugin/nvim-lspconfig/on_attach/init.lua) | キー・診断・inlay hints・参照ハイライトの共通呼び出し | **構造は採用済み**。選んだ機能だけここから呼び出す |
| [on_attach/keymaps.lua](lua/plugin/nvim-lspconfig/on_attach/keymaps.lua) | 空きキーだけ登録、定義・型定義・実装・参照、hover、signature、診断移動、rename、code action、workspace 操作 | 操作を揃えたいなら採用。gd 等は Glance → Snacks → 標準の順に選ぶ。cr は inc-rename、ga は actions-preview を優先。Insert Ctrl-k は現在の単語大文字化と意味が衝突するため選択が必要 |
| [on_attach/diagnostic.lua](lua/plugin/nvim-lspconfig/on_attach/diagnostic.lua) | 診断アイコン、下線、重要度順、入力中は更新抑止、virtual text を消して virtual lines 表示 | エラーをソース行の下に複数行表示したいなら推奨。画面の縦幅は使う。sign_define は旧 API なので採用時は現行の signs 設定を検討 |
| [on_attach/documenthighlight.lua](lua/plugin/nvim-lspconfig/on_attach/documenthighlight.lua) | カーソル移動後500msで同じシンボルの参照を強調。入力開始・バッファ離脱時は消す。複数 client の重複登録防止と timer 解放 | カーソル下の変数・関数の使用箇所を見たいなら推奨。外部の vim-illuminate は不要 |
| [on_attach/inlayhints.lua](lua/plugin/nvim-lspconfig/on_attach/inlayhints.lua) | 対応サーバーで hints 表示、入力中は非表示、入力終了で復帰、leader-l で hints と virtual lines を切替 | 型名・引数名をソース内に補足したいなら推奨。元コードの filter が `{ bufnr }` になっている点は、採用時に `{ bufnr = bufnr }` へ修正。virtual lines の切替は全体設定だが hints は対象バッファという範囲差もある |
| [on_attach/foldexpr.lua](lua/plugin/nvim-lspconfig/on_attach/foldexpr.lua) | foldingRange 対応時に LSP ベースの折り畳みを設定 | 関数・クラスを LSP の範囲で折り畳みたいなら推奨。**出典の on_attach/init.lua では呼ばれていないため、当時もこの経路では未使用** |

元の keymaps の gd は、Glance と Snacks が両方ない場合に type_definition を呼ぶ。
通常の「定義へ移動」の意図とは違うため、採用時は definition に補正する。
元コードは core.plugin の on_attach / has も前提としている。これらは現在の
LspAttach と lazy の管理情報で接続し直し、未定義のヘルパー呼び出しを残さない。

## 補完・整形・操作 UI

| ファイル | 元設定で作っている機能 | 今の構成との違い・判断 |
| --- | --- | --- |
| [blink-cmp.lua](lua/plugin/blink-cmp.lua) | LSP / パス / スニペット / バッファ補完に、emoji / spell / Git 補完を追加。Enter 確定、Ctrl-j/k で選択、Tab で候補・スニペット移動。候補を自動選択せず、説明を200ms後に表示。補完アイコンのカスタマイズ | **blink 本体は導入済み**。元設定は lazydev source を含まないため、置換時は現在の lazydev 連携を維持する。Insert Ctrl-k は単語大文字化と衝突する。Alt-j/k は mini.move とモードが違うため競合しない。追加 provider は必要なものだけ選ぶ |
| [lsp-format.lua](lua/plugin/lsp-format.lua) | 全 LspAttach に登録して保存時整形。wq / wqa では同期整形後に終了 | **保存時に LSP 整形したいなら推奨**。整形エンジン自体は提供しない。複数の整形 client を順番に実行するため、oxfmt / jsonls / tsc 等の担当を決める。現在は未導入 |
| [actions-preview.lua](lua/plugin/actions-preview.lua) | code action 適用前の差分をプレビュー。Snacks を backend にし、縦レイアウト・高さ0.4 | **修正内容を確認してから code action を適用したいなら推奨**。現在の leader-ca は標準 code_action なので呼び出しも変更する。Snacks 導入済みなので馴染みやすい |
| [glance.lua](lua/plugin/glance.lua) | 定義・型定義・実装・参照をソース脇の peek UI で表示・編集。左に一覧、枠あり、折り畳みなし。結果が1件なら UI を開かず直接移動 | **元の場所を見ながら参照先を調べたいなら推奨**。現在の Snacks picker と検索対象は重なる。gd / gr をどちらの UI にするか選ぶ。元の keymaps は Glance を優先 |
| [inc-rename.lua](lua/plugin/inc-rename.lua) | IncRename コマンドで新しいシンボル名を入力しながら変更箇所をプレビュー | **rename の影響を入力中に見たいなら推奨**。単なる文字列置換ではなく LSP rename。現在の leader-cr を接続し、Noice の inc_rename preset も有効にする案 |

blink の追加依存は moyiz/blink-emoji.nvim、ribru17/blink-cmp-spell、
Kaiser-Yang/blink-cmp-git とその plenary.nvim。色プレビュー部分は nvim-highlight-colors があれば使う条件分岐。
現在の preset=default は元の preset=none と違うため、部分的に移植してキーを選ぶ。

参照: [lsp-format](https://github.com/lukas-reineke/lsp-format.nvim)、
[actions-preview](https://github.com/aznhe21/actions-preview.nvim)、
[Glance](https://github.com/dnlhc/glance.nvim)、
[inc-rename](https://github.com/smjonas/inc-rename.nvim)

## 今回反映した変更

- Neovim の rust_analyzer 有効化と after/lsp/rust_analyzer.lua を削除。
- dev-tools.nix の rust-analyzer を cargo / rustc に置き換え。既存 rustfmt / clippy は維持。
- Zed の Rust 設定は変更していない。Zed は自身の Nix 設定で rust-analyzer の store path を直接参照する。
- この場所の15ファイルは参照コピーとして維持する。実行用の設定には移植済みで、衝突箇所の暫定動作は実行用 README に記載。
