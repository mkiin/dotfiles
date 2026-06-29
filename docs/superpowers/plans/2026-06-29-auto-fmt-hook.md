# 自動フォーマット/lint hook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude Code がファイルを編集するたびに、編集ファイルだけを treefmt で自動整形/lint する仕組みを dotfiles リポジトリに導入する。

**Architecture:** inputs にある `treefmt-nix` を `flake.nix` の outputs に組み込み `nix run .#fmt` / `nix fmt` を有効化する。treefmt の定義は `lib/treefmt/default.nix` に置く。`.claude/settings.json` の PostToolUse hook が編集ファイルのパスを jq で取り出して `nix run .#fmt -- <file>` を呼ぶ。

**Tech Stack:** Nix flake（標準 flake、flake-parts 未使用）, treefmt-nix, nixfmt-rfc-style, statix, shfmt, prettier, taplo, stylua, Claude Code hooks, jq

## Global Constraints

- 対象 system は `x86_64-linux` のみ（single system 前提で手書きする。flake-parts は導入しない）。
- treefmt に含める lint は自動修正できるもののみ（treefmt はファイルを書き換える前提）。
- 採用フォーマッタ: nixfmt-rfc-style, statix, shfmt, prettier, taplo, stylua。
- 除外: qml(qmlformat 非標準), py, deadnix（自動削除の誤爆回避）。
- treefmt 定義のファイルパスは `lib/treefmt/default.nix`。flake からは `./lib/treefmt`（ディレクトリ）で参照する。
- `.claude/settings.json` の既存キー（permissions, env, attribution 等）は変更しない。`hooks` キーを追加するのみ。
- hook の matcher は `Edit|Write`。NotebookEdit は除外。
- コミットメッセージは Conventional Commits 形式。`includeCoAuthoredBy` は無効化済みなので Co-Authored-By 行は付けない。

---

### Task 1: treefmt 定義ファイルの作成

**Files:**

- Create: `lib/treefmt/default.nix`

**Interfaces:**

- Consumes: なし
- Produces: treefmt モジュール定義（attrset を返す関数）。Task 2 が `treefmt-nix.lib.evalModule pkgs ./lib/treefmt` で読み込む。`programs.<name>.enable` で各フォーマッタを有効化し、`projectRootFile = "flake.nix"` でツリールートを決定する。

- [ ] **Step 1: lib/treefmt/default.nix を作成する**

ファイル `lib/treefmt/default.nix` を以下の内容で作成する。

```nix
{ ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true; # nixfmt-rfc-style (Nix 整形)
    statix.enable = true; # Nix lint (statix fix)
    shfmt.enable = true; # sh / zsh
    prettier.enable = true; # json / md / css
    taplo.enable = true; # toml
    stylua.enable = true; # lua
  };
}
```

- [ ] **Step 2: 構文が正しいことを確認する**

Run: `nix-instantiate --parse lib/treefmt/default.nix > /dev/null && echo OK`
Expected: `OK`（パースエラーが出ないこと）

- [ ] **Step 3: コミット**

```bash
git add lib/treefmt/default.nix
git commit -m "feat(treefmt): add treefmt formatter/lint definition"
```

---

### Task 2: flake.nix への treefmt 統合

**Files:**

- Modify: `flake.nix`（`outputs` の `let` ブロックと返り値の attrset）

**Interfaces:**

- Consumes: `lib/treefmt/default.nix`（Task 1）、inputs の `treefmt-nix`, `nixpkgs`。
- Produces: flake 出力 `formatter.x86_64-linux` と `packages.x86_64-linux.fmt`（どちらも `treefmtEval.config.build.wrapper`）。Task 3 の hook が `nix run .#fmt` でこれを呼ぶ。

現状の `flake.nix` の `outputs`（51-69 行）は以下。

```nix
  outputs =
    { self, ... }@inputs:
    let
      mylib = import ./lib inputs;
    in
    {
      nixosConfigurations.nixos = mylib.makeNixosConfig {
        system = "x86_64-linux";
        hostname = "nixos";
        username = "mkiin";
        modules = [ ./hosts/nixos ];
      };

      homeConfigurations."mkiin@wsl" = mylib.makeHomeManagerConfig {
        system = "x86_64-linux";
        username = "mkiin";
        modules = [ ./hosts/wsl/home-manager.nix ];
      };
    };
```

- [ ] **Step 1: `let` ブロックに treefmt 評価を追加する**

`let mylib = import ./lib inputs;` の行を以下に置き換える。

```nix
    let
      mylib = import ./lib inputs;
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs { inherit system; };
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./lib/treefmt;
    in
```

- [ ] **Step 2: outputs の attrset に formatter と packages を追加する**

`homeConfigurations."mkiin@wsl" = ...;` ブロックの直後（attrset を閉じる `};` の前）に以下を追加する。

```nix
      formatter.${system} = treefmtEval.config.build.wrapper;
      packages.${system}.fmt = treefmtEval.config.build.wrapper;
```

追加後、outputs の返り値 attrset は `nixosConfigurations` / `homeConfigurations` / `formatter` / `packages` の 4 キーを持つ。

- [ ] **Step 3: flake が評価でき fmt 出力が存在することを確認する**

Run: `nix eval --raw .#packages.x86_64-linux.fmt.name 2>&1 | head -1`
Expected: treefmt ラッパーの derivation 名（例: `treefmt` を含む文字列）が表示され、評価エラーが出ないこと。

- [ ] **Step 4: 実際にフォーマッタが起動することを確認する**

Run: `nix run .#fmt -- --version 2>&1 | head -3`
Expected: treefmt のバージョン情報が表示される（フォーマッタの取得で初回は時間がかかる場合がある）。

- [ ] **Step 5: コミット**

```bash
git add flake.nix flake.lock
git commit -m "feat(flake): wire treefmt into formatter and packages outputs"
```

---

### Task 3: .claude/settings.json への PostToolUse hook 追加

**Files:**

- Modify: `.claude/settings.json`

**Interfaces:**

- Consumes: `nix run .#fmt`（Task 2 の `packages.x86_64-linux.fmt`）、`jq`（`/etc/profiles/per-user/mkiin/bin/jq` に存在）。
- Produces: なし（最終成果物）。

現状の `.claude/settings.json` は `$schema` / `autoMemoryEnabled` / `language` / `attribution` / `env` / `permissions` の 6 キーを持つ（末尾の `permissions` ブロックは 14-41 行）。

- [ ] **Step 1: hooks キーを追加する**

`permissions` ブロックを閉じる `}` の直後（ファイル末尾の `}` の前）にカンマを足し、`hooks` キーを追加する。追加後の末尾は以下の形になる。

```json
  "permissions": {
    "allow": [
      "Bash(git status*)",
      "Bash(git log*)",
      "Bash(git diff*)",
      "Bash(git add*)",
      "Bash(git commit*)",
      "Bash(pnpm *)",
      "Bash(ls*)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(wc *)",
      "Bash(which *)",
      "Bash(pwd)",
      "Bash(whoami)",
      "Bash(date)",
      "Bash(uname *)",
      "Read",
      "Glob",
      "Grep"
    ],
    "deny": [
      "Bash(pnpm install*)",
      "Bash(pnpm i)",
      "Bash(pnpm i *)",
      "Bash(pnpm add*)"
    ]
  },
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
}
```

- [ ] **Step 2: JSON が妥当であることを確認する**

Run: `jq empty .claude/settings.json && echo OK`
Expected: `OK`（パースエラーが出ないこと）

- [ ] **Step 3: hook コマンドのロジックを単体で検証する**

整形が乱れた Nix ファイルを作り、hook と同じコマンドを手動実行して整形されることを確認する。

```bash
printf '{foo=1;bar=2;}\n' > /tmp/claude-fmt-test.nix
file=/tmp/claude-fmt-test.nix; nix run .#fmt -- "$file"
cat /tmp/claude-fmt-test.nix
```

Expected: `cat` の出力が nixfmt-rfc-style によって複数行に整形されている（`{` の後で改行され、`foo = 1;` のようにスペースが入る）。確認後 `rm /tmp/claude-fmt-test.nix` で削除する。

- [ ] **Step 4: file_path 抽出ロジックを検証する**

hook に渡される JSON を模して、jq がパスを正しく取り出すことを確認する。

```bash
echo '{"tool_input":{"file_path":"/tmp/x.nix"}}' | jq -r '.tool_input.file_path // empty'
```

Expected: `/tmp/x.nix`

- [ ] **Step 5: コミット**

```bash
git add .claude/settings.json
git commit -m "feat(claude): auto-format edited files via PostToolUse hook"
```

---

## 完了後の動作確認（全タスク後）

実リポジトリ内で Claude が Nix ファイルを Edit すると、PostToolUse hook が
`nix run .#fmt -- <file>` を実行し、該当ファイルだけが整形/statix fix される。
別プロジェクトでの作業では `.claude/settings.json`（プロジェクトスコープ）が効かない
ため hook は発火しない。
