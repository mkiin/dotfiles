# ghq 集約 + hook 強制によるクローンリポジトリ管理体制

## 背景と課題

AI にライブラリ・OSS のソースを読ませるために手元へクローンする運用が無秩序で、以下の問題がある。

- クローン先がバラバラで重複クローンが発生する。
- ワークスペース内にクローンすると `.gitignore` への追加が必要になるが、AI が使う `fd` / `rg` は gitignore を尊重するため検索ヒットしなくなる（このうち「gitignore 無視」はグローバル `CLAUDE.md` の `rg -uu` / `fd -HI` ルールで既に半分対処済み）。

## 解決方針

ソフトな指示に頼らず、**hook で `git clone` を機械的に遮断し、遮断時にルールテキストを AI へ強制注入して `ghq get` に誘導する**決定論的な仕組みを敷く。

- クローンは `~/ghq` に集約。`ghq get` は冪等（既存なら再クローンしない）のため重複が原理的に発生しない。
- Claude Code の `additionalDirectories` で毎セッション `~/ghq` をワークスペースに含め、AI が即座に探索・`cd` できる。
- 人間は `ghq list -p | fzf` のキーバインドで素早く移動する。

前提ツール（`ghq` / `fzf` / `zoxide`）は `nix/modules/home/packages.nix` に導入済み。本設計は設定・導線・強制機構のみを追加する。

## 変更コンポーネント

### 1. `nix/modules/home/programs/git.nix` — ghq.root を明示

```nix
programs.git.settings.ghq.root = "${config.home.homeDirectory}/ghq";
```

- 値はデフォルトの `~/ghq` と同じだが、nix で宣言して source-of-truth 化する。
- モジュールシグネチャを `{ ... }:` から `{ config, ... }:` へ変更する。

### 2. `nix/modules/home/programs/claude-code.nix` — additionalDirectories + hook

```nix
permissions.additionalDirectories = [ "${config.home.homeDirectory}/ghq" ];

hooks.PreToolUse = [{
  matcher = "Bash";
  hooks = [{
    type = "command";
    command = "bash ${inputs.self}/claude/hooks/block-git-clone.sh";
  }];
}];
```

- 毎セッション `~/ghq` がワークスペースに加わる（add workspace の永続化）。
- モジュールシグネチャを `{ inputs, ... }:` から `{ inputs, config, ... }:` へ変更する。

### 3. `claude/hooks/block-git-clone.sh`（新規）— 遮断 + ルール注入

- stdin の JSON から `tool_input.command` を `jq` で取得する。
- コマンドが `git clone` にマッチした場合、以下を stdout に出力して遮断する。

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": "<ルールテキスト>"
    }
  }
  ```

- マッチしなければ何も出力せず `exit 0`（通常コマンドは素通り）。
- 注入するルールテキストの内容:
  - OSS・ライブラリを読むための `git clone` は禁止。代わりに `ghq get <url>` を使う（`~/ghq` へ冪等にクローンし、重複しない）。
  - 既存確認は `ghq list -p [query]`、ルートは `ghq root`。
  - 探索は `rg -uu` / `fd -HI`（gitignore 無視は既存ルール）。

### 4. `nix/modules/home/programs/zsh/functions.zsh` — ghq + fzf キーバインド

```zsh
ghq-fzf() {
  local dir=$(ghq list -p | fzf --prompt="repositories > " --query "$LBUFFER")
  [[ -n "$dir" ]] && { BUFFER="cd ${dir}"; zle accept-line; }
  zle clear-screen
}
zle -N ghq-fzf
bindkey '^]' ghq-fzf
```

- 記事の `peco` 王道パターンを、この環境の `fzf` 運用に合わせて再現する。

## データフロー

1. AI が `git clone <url>` を発行。
2. PreToolUse hook が Bash コマンドを検査し、`git clone` を検出して `deny` を返す。
3. 遮断理由としてルールテキストが AI のコンテキストに注入される。
4. AI は `ghq get <url>` に切り替え、`~/ghq/github.com/owner/repo` へクローン。
5. `additionalDirectories` により `~/ghq` はワークスペース内なので、AI は `rg -uu` / `fd -HI` でそのまま探索できる。
6. 人間は `^]` で `ghq list -p | fzf` を起動し、選択して `cd`。

## 設計上の判断

- **`git clone` を全面遮断し `ghq get` に寄せる**: 自分の作業リポジトリのクローンも `ghq get` 経由になるが、ghq は「整理されたクローン」を提供するだけで作業リポジトリにも問題なく使えるため許容する。
- **遮断方式は JSON 出力（`permissionDecision: deny`）**: exit code 2 方式より理由テキストの扱いが明確。
- **ghq の冪等性で重複対策**: 専用のデデュープ処理は不要。`ghq get` が既存検出を担う。

## 検証

1. `home-manager switch --flake .#cachyos` がエラーなく完走する。
2. `git config --get ghq.root` が `~/ghq` を返す。
3. Claude Code セッションで `git clone <url>` を試行すると deny + ルール表示、`ghq get <url>` は通過する。
4. `~/.claude/settings.json` の `permissions.additionalDirectories` に `~/ghq` が含まれる。
5. シェルで `^]` を押すと fzf にリポジトリ一覧が出て、選択で `cd` できる。

## スコープ外

- 既存の散在クローンの `~/ghq` への移行（必要なら別タスク）。
- `wsl` ホストへの適用差分（モジュールは共通なので両ホストに同時適用される想定）。
