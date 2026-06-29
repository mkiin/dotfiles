# ghq 集約 + hook 強制によるクローン管理体制 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** AI のクローン運用を `~/ghq` に集約し、PreToolUse hook で `git clone` を遮断して `ghq get` へ強制誘導するクローン管理体制を nix で宣言的に整える。

**Architecture:** hook スクリプト（`claude/hooks/block-git-clone.sh`）が Bash コマンドを検査し `git clone` を deny + ルール注入する。`ghq.root` を git 設定で明示し、Claude Code の `additionalDirectories` で毎セッション `~/ghq` をワークスペースに含める。人間用に `ghq list -p | fzf` のキーバインドを追加する。

**Tech Stack:** Nix flake / home-manager, zsh (zle widget), bash, jq, ghq, fzf, Claude Code settings hooks。

## Global Constraints

- Nix ソースのみ編集し、live ファイルを手編集しない。検証は `home-manager build/switch --flake .#cachyos`（このホストは cachyos）。
- `ghq.root` は `${config.home.homeDirectory}/ghq`（= `~/ghq`、デフォルトと同値だが明示宣言）。
- hook スクリプトは grep / find を使わず bash の `[[ =~ ]]` と jq のみで実装する（リポジトリのシェルルール準拠）。
- hook の遮断は JSON 出力方式（`hookSpecificOutput.permissionDecision = "deny"`）。
- `git clone` は OSS 閲覧用途・作業リポジトリを問わず全面遮断し `ghq get` に寄せる。
- 既存モジュールのスタイル（インデント・属性記法）に合わせ、無関係な箇所は変更しない。

---

### Task 1: git clone 遮断 hook スクリプト

**Files:**

- Create: `claude/hooks/block-git-clone.sh`
- Test: `claude/hooks/block-git-clone.test.sh`（一時テスト。Step 5 で削除）

**Interfaces:**

- Consumes: stdin に Claude Code PreToolUse の JSON（`.tool_input.command` にコマンド文字列）。
- Produces: `git clone` 検出時に deny JSON を stdout へ出力。非該当時は無出力で `exit 0`。後続タスク（Task 3）が `bash <path>/claude/hooks/block-git-clone.sh` として参照する。

- [ ] **Step 1: 失敗するテストを書く**

`claude/hooks/block-git-clone.test.sh`:

```bash
#!/usr/bin/env bash
# block-git-clone.sh の挙動を検証する一時テストハーネス
set -u
script="$(dirname "$0")/block-git-clone.sh"
fail=0

assert_deny() {
  local desc="$1" cmd="$2"
  local out
  out=$(printf '{"tool_input":{"command":%s}}' "$(jq -Rn --arg c "$cmd" '$c')" | bash "$script")
  if printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
    echo "ok   (deny): $desc"
  else
    echo "FAIL (expected deny): $desc -> $out"; fail=1
  fi
}

assert_pass() {
  local desc="$1" cmd="$2"
  local out
  out=$(printf '{"tool_input":{"command":%s}}' "$(jq -Rn --arg c "$cmd" '$c')" | bash "$script")
  if [[ -z "$out" ]]; then
    echo "ok   (pass): $desc"
  else
    echo "FAIL (expected empty): $desc -> $out"; fail=1
  fi
}

assert_deny "git clone https" "git clone https://github.com/x/y"
assert_deny "git clone ssh"   "git clone git@github.com:x/y.git"
assert_pass "ghq get"         "ghq get https://github.com/x/y"
assert_pass "git status"      "git status"
assert_pass "legit clone 誤検出なし" "legit clone foo"

exit $fail
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `bash claude/hooks/block-git-clone.test.sh`
Expected: スクリプト未作成のため全 deny ケースが FAIL（`bash: block-git-clone.sh: No such file or directory` 由来で deny 判定できず）。

- [ ] **Step 3: hook スクリプトを実装**

`claude/hooks/block-git-clone.sh`:

```bash
#!/usr/bin/env bash
# Claude Code PreToolUse hook: `git clone` を遮断し ghq get へ誘導する
set -u

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

if [[ "$command" =~ (^|[^[:alnum:]_])git[[:space:]]+clone([^[:alnum:]_]|$) ]]; then
  reason=$(cat <<'EOF'
`git clone` は禁止です。OSS・ライブラリのソースは `ghq get <url>` で取得してください。

- `ghq get <url>` は `~/ghq/<host>/<owner>/<repo>` へ冪等にクローンします（既存なら再取得しないため重複しません）。更新は `ghq get -u <url>`。
- 既存クローンの確認: `ghq list -p [query]` / ルートは `ghq root`。
- `~/ghq` はワークスペースに含まれているので `rg -uu` / `fd -HI` でそのまま探索できます。
EOF
)
  jq -n --arg r "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
fi

exit 0
```

- [ ] **Step 4: テストを実行して成功を確認**

Run: `bash claude/hooks/block-git-clone.test.sh`
Expected: 全行 `ok`、終了コード 0。

- [ ] **Step 5: 一時テストを削除してコミット**

```bash
rm claude/hooks/block-git-clone.test.sh
git add claude/hooks/block-git-clone.sh
git commit -m "feat: git clone を遮断し ghq get へ誘導する hook を追加"
```

---

### Task 2: git 設定に ghq.root を明示

**Files:**

- Modify: `nix/modules/home/programs/git.nix`

**Interfaces:**

- Consumes: home-manager の `config.home.homeDirectory`。
- Produces: 生成 gitconfig に `[ghq] root = <home>/ghq`。`ghq` / Task 4 のキーバインドがこの root を参照する。

- [ ] **Step 1: モジュールシグネチャに config を追加**

`nix/modules/home/programs/git.nix` の 1 行目:

```nix
{ config, ... }:
```

（変更前: `{ ... }:`）

- [ ] **Step 2: settings に ghq.root を追加**

`programs.git.settings` 内、`init.defaultBranch = "main";` の直後に追加:

```nix
      ghq.root = "${config.home.homeDirectory}/ghq";
```

- [ ] **Step 3: flake が評価できることを確認**

Run: `home-manager build --flake .#cachyos`
Expected: エラーなくビルド成功（`result` シンボリックリンク生成）。

- [ ] **Step 4: コミット**

```bash
git add nix/modules/home/programs/git.nix
git commit -m "feat: git 設定に ghq.root を明示"
```

---

### Task 3: claude-code に additionalDirectories と hook を配線

**Files:**

- Modify: `nix/modules/home/programs/claude-code.nix`

**Interfaces:**

- Consumes: `config.home.homeDirectory`、`inputs.self`、Task 1 の `claude/hooks/block-git-clone.sh`。
- Produces: 生成 `~/.claude/settings.json` の `permissions.additionalDirectories` に `~/ghq`、`hooks.PreToolUse` に hook 配線。

- [ ] **Step 1: モジュールシグネチャに config を追加**

`nix/modules/home/programs/claude-code.nix` の 1 行目:

```nix
{ inputs, config, ... }:
```

（変更前: `{ inputs, ... }:`）

- [ ] **Step 2: permissions に additionalDirectories を追加**

`permissions` ブロック内、`defaultMode = "auto";` の直後に追加:

```nix
        additionalDirectories = [ "${config.home.homeDirectory}/ghq" ];
```

- [ ] **Step 3: settings に hooks を追加**

`settings` 属性内、`permissions = { ... };` ブロックの直後に追加:

```nix
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "bash ${inputs.self}/claude/hooks/block-git-clone.sh";
            }
          ];
        }
      ];
```

- [ ] **Step 4: flake が評価できることを確認**

Run: `home-manager build --flake .#cachyos`
Expected: エラーなくビルド成功。

- [ ] **Step 5: 生成 settings.json に反映されることを確認**

Run: `jq '.permissions.additionalDirectories, .hooks.PreToolUse' ./result/home-files/.claude/settings.json`
Expected: `additionalDirectories` に `~/ghq`（絶対パス）、`PreToolUse` に matcher `Bash` の command エントリが出力される。

- [ ] **Step 6: コミット**

```bash
git add nix/modules/home/programs/claude-code.nix
git commit -m "feat: claude-code に ghq ワークスペースと git clone 遮断 hook を配線"
```

---

### Task 4: ghq + fzf キーバインドを追加

**Files:**

- Modify: `nix/modules/home/programs/zsh/functions.zsh`

**Interfaces:**

- Consumes: `ghq`, `fzf`（導入済み）、`ghq.root`（Task 2）。
- Produces: zle widget `ghq-fzf` を `^]` にバインド。

- [ ] **Step 1: ghq-fzf 関数とバインドを追記**

`nix/modules/home/programs/zsh/functions.zsh` の末尾（「起動時バックグラウンド処理」セクションの `(vscode_cleanup &>/dev/null &)` の前）に追加:

```zsh
# --------------------------------------------
# ghq + fzf: リポジトリ一覧から選んで cd
# --------------------------------------------
ghq-fzf() {
    local dir
    dir=$(ghq list -p | fzf --prompt="repositories > " --query "$LBUFFER")
    if [[ -n "$dir" ]]; then
        BUFFER="cd ${dir}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N ghq-fzf
bindkey '^]' ghq-fzf
```

- [ ] **Step 2: zsh 構文チェック**

Run: `zsh -n nix/modules/home/programs/zsh/functions.zsh`
Expected: 出力なし・終了コード 0（構文エラーなし）。

- [ ] **Step 3: コミット**

```bash
git add nix/modules/home/programs/zsh/functions.zsh
git commit -m "feat: ghq + fzf でリポジトリへ cd するキーバインドを追加"
```

---

### Task 5: switch して実機統合検証

**Files:**

- なし（適用と検証のみ）

**Interfaces:**

- Consumes: Task 1〜4 の全変更。

- [ ] **Step 1: home-manager switch を適用**

Run: `home-manager switch --flake .#cachyos`
Expected: エラーなく `Activating ...` まで完走。

- [ ] **Step 2: ghq.root を検証**

Run: `git config --get ghq.root`
Expected: `/home/mkiin/ghq`（= `~/ghq`）。

- [ ] **Step 3: settings.json の additionalDirectories と hook を検証**

Run: `jq '.permissions.additionalDirectories, .hooks.PreToolUse' ~/.claude/settings.json`
Expected: `~/ghq`（絶対パス）と `Bash` matcher の hook command が出力される。

- [ ] **Step 4: hook を実コマンドで検証**

Run:

```bash
printf '{"tool_input":{"command":"git clone https://github.com/x/y"}}' | bash ~/.claude/hooks/block-git-clone.sh
```

（注: hook は flake store 経由で参照されるため、`~/.claude/hooks/` に無い場合は `bash "$(jq -r '.hooks.PreToolUse[0].hooks[0].command' ~/.claude/settings.json | sed "s/^bash //")"` の store パスで実行する）
Expected: `permissionDecision: "deny"` を含む JSON が出力される。

- [ ] **Step 5: 新規シェルでキーバインドを確認**

Run: 新しい zsh を起動し `bindkey '^]'` を実行。
Expected: `"^]" ghq-fzf` が表示される。

- [ ] **Step 6: 動作確認の最終コミット（変更があれば）**

```bash
git status
# 追加変更が無ければコミット不要。flake.lock 等に差分があれば:
# git add -A && git commit -m "chore: ghq クローン管理体制を適用"
```

---

## Self-Review

**Spec coverage:**

- ghq.root 明示 → Task 2 ✓
- additionalDirectories → Task 3 ✓
- hook で git clone 遮断 + ルール注入 → Task 1（スクリプト）+ Task 3（配線）✓
- ghq + fzf キーバインド → Task 4 ✓
- 検証項目（switch / ghq.root / settings.json / hook deny / fzf bind）→ Task 5 ✓
- スコープ外（既存クローン移行・wsl 差分）はプラン対象外として spec 通り除外 ✓

**Placeholder scan:** プレースホルダなし。全 step に実コードと実コマンドを記載済み。

**Type consistency:** hook 関数名 `block-git-clone.sh`、zle widget `ghq-fzf`、設定キー `additionalDirectories` / `hooks.PreToolUse` をタスク間で統一。`ghq.root` パスは全タスクで `${config.home.homeDirectory}/ghq`（= `~/ghq` = `/home/mkiin/ghq`）で一致。
