# ファイル編集時の自動フォーマット/lint hook 設計

## 背景と目的

Claude Code がファイルを編集（Edit/Write）するたびに、Nix を中心としたフォーマット
と lint を自動適用したい。手動で `nix fmt` を走らせる運用をやめ、編集直後に該当ファ
イルだけを整形して差分ノイズを減らす。

参考にした実装は `ghq/github.com/ryoppippi/dotfiles`。ryoppippi は
`.claude/settings.json` の PostToolUse hook で `nix run .#fmt` を呼び、flake 側の
`fmt`（treefmt ラッパー）に整形を委譲している。本設計はこの構成を mkiin のリポジトリ
に合わせて取り込む。

## 現状

- `flake.nix` は標準 flake（flake-parts 未使用）。出力は `nixosConfigurations` と
  `homeConfigurations` のみ。対象 system は `x86_64-linux` のみ。
- `treefmt-nix` は inputs に存在するが、outputs では未使用。よって `nix fmt` も
  `nix run .#fmt` も**まだ存在しない**。hook を足すだけでは動かないため、フォーマッ
  タ基盤の用意が前提になる。
- `jq` は `/etc/profiles/per-user/mkiin/bin/jq` に存在し、hook から利用可能。

## 方針の決定事項

- フォーマッタ基盤: inputs の `treefmt-nix` を outputs に組み込み、`nix fmt` /
  `nix run .#fmt` を有効化する。
- hook の対象範囲: **編集したファイルのみ**。hook の stdin(JSON) から
  `tool_input.file_path` を取り出し、そのファイルだけ整形する。
- lint は**自動修正できるもののみ**採用（treefmt はファイルを書き換える前提のため）。
- ファイル配置: treefmt の定義は `lib/treefmt/default.nix` に置く。

## 構成

3 つの変更からなる。

### 1. `lib/treefmt/default.nix`（新規）

treefmt が適用するフォーマッタ/lint を定義する。

```nix
{ ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true;   # nixfmt-rfc-style (Nix 整形)
    statix.enable = true;   # Nix lint (statix fix)
    shfmt.enable = true;    # sh / zsh
    prettier.enable = true; # json / md / css
    taplo.enable = true;    # toml
    stylua.enable = true;   # lua
  };
}
```

対象範囲の決定:

- 採用: nix(整形 + statix), sh/zsh, json/md/css, toml, lua。
- 除外: qml(132 ファイル) は treefmt 標準モジュールが無く専用 formatter
  (qmlformat) の追加が必要なため今回は対象外。py(2 ファイル) も少量のため除外。
- いずれも後から `settings.formatter` で custom 追加が可能。
- deadnix は未使用束縛の自動削除が誤爆しうるため不採用。statix は `check` ではなく
  修正系（statix fix 相当）として動き、自動整形の用途に合致する。

### 2. `flake.nix` への統合

`outputs` の `let` で treefmt を評価し、出力を 2 つ生やす。single system 前提で
手書きする（flake-parts は導入しない）。

```nix
let
  mylib = import ./lib inputs;
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs { inherit system; };
  treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./lib/treefmt;
in
{
  # 既存の nixosConfigurations / homeConfigurations はそのまま
  formatter.${system} = treefmtEval.config.build.wrapper; # nix fmt
  packages.${system}.fmt = treefmtEval.config.build.wrapper; # nix run .#fmt
}
```

- `evalModule pkgs ./lib/treefmt` はディレクトリを渡すと `default.nix` を読む。
- `nix run .#fmt`（hook 用）と `nix fmt`（手動用）の両方が使えるようになる。

### 3. `.claude/settings.json` への hook 追加

既存 JSON に `hooks` キーを追加する。他の設定（permissions, env など）は変更しない。

```json
"hooks": {
  "PostToolUse": [
    {
      "matcher": "Edit|Write",
      "hooks": [
        {
          "type": "command",
          "command": "file=$(jq -r '.tool_input.file_path // empty'); [ -n \"$file\" ] && nix run .#fmt -- \"$file\""
        }
      ]
    }
  ]
}
```

- 編集ファイルのみを対象（`tool_input.file_path` を jq で抽出 → `nix run .#fmt -- <file>`）。
- matcher は `Edit|Write`。ipynb が無いため NotebookEdit は除外。
- hook はシェルコマンドとして常に自動実行されるため、permissions の変更は不要。
- hook の作業ディレクトリはプロジェクトルート（dotfiles）であり、`.#fmt` の `.` は
  そのルートの flake を指す。

## 動作フロー

1. Claude が Edit/Write でファイルを編集する。
2. PostToolUse hook が発火し、stdin の JSON から `file_path` を取得する。
3. `nix run .#fmt -- <file>` を実行する。
4. treefmt が該当ファイルだけを整形 / statix fix する。

## 想定される影響と留意点

- `nix run .#fmt` は flake 評価を伴うため初回起動にやや時間がかかる（ryoppippi も同様
  で許容範囲）。
- 整形対象外の拡張子（qml など）を編集した場合、treefmt は対象外として何もしない。
- 別プロジェクトでの作業中はこの `.claude/settings.json`（プロジェクトスコープ）が効
  かないため、dotfiles リポジトリ内の編集時のみ hook が動く。
