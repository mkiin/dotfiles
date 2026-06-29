# クローン遮断 hook の正規化マッチ強化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `git clone` 遮断 hook の判定前にコマンド文字列から字句難読化文字（`\ " '`）を除去する正規化を入れ、`git cl\one` / `git "clone"` / `git c'l'one` 等のすり抜けを塞ぐ。

**Architecture:** `claude/hooks/block-git-clone.sh` の判定対象を生コマンドから「`\ " '` を除去した正規化文字列」に差し替える。正規表現自体は変えない。空白・タブ・改行は既存の `[[:space:]]+` が吸収するため追加処理は不要。hook は flake ソースとして `${inputs.self}/claude/hooks/block-git-clone.sh` で参照されるため、適用には `home-manager switch` が要る。

**Tech Stack:** bash（パラメータ展開によるパターン置換）, jq, Nix flake / home-manager, Claude Code settings hooks。

## Global Constraints

- Nix ソース（`claude/hooks/` 配下の実体ファイルも含む）のみ編集し、`~` の live ファイルを手編集しない。検証は `home-manager build/switch --flake .#cachyos`（このホストは cachyos）。
- hook スクリプトは grep / find を使わず bash の `[[ =~ ]]` と jq のみで実装する（リポジトリのシェルルール準拠）。
- 正規化は `\ " '` の除去に限定する。空白系は触らない。
- 既存の遮断方式（JSON 出力 `hookSpecificOutput.permissionDecision = "deny"`）とルールテキストは変更しない。
- 意味レベルの回避（変数展開・コマンド置換・行継続分割・git 以外の取得経路）はスコープ外。塞がない。
- 既存スタイルに合わせ、無関係な箇所は変更しない。

---

### Task 1: 正規化マッチを hook に追加

**Files:**

- Modify: `claude/hooks/block-git-clone.sh`
- Test: `claude/hooks/block-git-clone.test.sh`（一時テスト。Step 5 で削除）

**Interfaces:**

- Consumes: stdin に Claude Code PreToolUse の JSON（`.tool_input.command` にコマンド文字列）。
- Produces: 字句難読化を含む `git clone` 検出時に deny JSON を stdout へ出力。非該当時は無出力で `exit 0`。配線（`claude-code.nix` の `bash ${inputs.self}/claude/hooks/block-git-clone.sh`）は既存のまま変更しない。

- [ ] **Step 1: 失敗するテストを書く**

`claude/hooks/block-git-clone.test.sh` を新規作成する。難読化ケースの deny 期待と、誤検出回帰ガードの pass 期待を含める。

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

# 素の形（既存の遮断。回帰ガード）
assert_deny "git clone https"  "git clone https://github.com/x/y"
assert_deny "git clone ssh"    "git clone git@github.com:x/y.git"

# 字句難読化（今回ふさぐ対象）
assert_deny "backslash"        'git cl\one https://github.com/x/y'
assert_deny "double-quote"     'git "clone" https://github.com/x/y'
assert_deny "single-quote"     "git c'l'one https://github.com/x/y"
assert_deny "quoted-space"     'git" "clone https://github.com/x/y'

# 通過すべきコマンド（誤検出回帰ガード）
assert_pass "ghq get"          "ghq get https://github.com/x/y"
assert_pass "git status"       "git status"
assert_pass "legit clone 誤検出なし" "legit clone foo"

exit $fail
```

- [ ] **Step 2: テストを実行して失敗を確認**

Run: `bash claude/hooks/block-git-clone.test.sh`
Expected: 素の形 2 ケースと pass 3 ケースは `ok`。難読化 4 ケース（backslash / double-quote / single-quote / quoted-space）が `FAIL (expected deny)` になる（現状 hook は生文字列マッチのため難読化を素通しし無出力）。終了コード 1。

- [ ] **Step 3: 正規化ステップを実装**

`claude/hooks/block-git-clone.sh` の `command=...` 取得行の直後に正規化を追加し、`if` の判定対象を `command` から `stripped` へ差し替える。差分は次の 2 点のみ。

```bash
input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# 字句難読化（バックスラッシュ・クォート）を剥がす
stripped=${command//[\\\"\']/}

if [[ "$stripped" =~ (^|[^[:alnum:]_])git[[:space:]]+clone([^[:alnum:]_]|$) ]]; then
```

スクリプト全体は以下になる。

```bash
#!/usr/bin/env bash
# Claude Code PreToolUse hook: `git clone` を遮断し ghq get へ誘導する
set -u

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# 字句難読化（バックスラッシュ・クォート）を剥がす
stripped=${command//[\\\"\']/}

if [[ "$stripped" =~ (^|[^[:alnum:]_])git[[:space:]]+clone([^[:alnum:]_]|$) ]]; then
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
Expected: 全 9 行 `ok`、終了コード 0。特に backslash / double-quote / single-quote / quoted-space が `ok (deny)`、`legit clone foo` が `ok (pass)` であること。

- [ ] **Step 5: 一時テストを削除してコミット**

```bash
rm claude/hooks/block-git-clone.test.sh
git add claude/hooks/block-git-clone.sh
git commit -m "feat: クローン遮断 hook に字句難読化を剥がす正規化マッチを追加"
```

---

### Task 2: switch して実機検証

**Files:**

- なし（適用と検証のみ）

**Interfaces:**

- Consumes: Task 1 の `claude/hooks/block-git-clone.sh`。flake は `bash ${inputs.self}/claude/hooks/block-git-clone.sh` で参照する。

- [ ] **Step 1: flake が評価・ビルドできることを確認**

Run: `home-manager build --flake .#cachyos`
Expected: エラーなくビルド成功（`result` シンボリックリンク生成）。

- [ ] **Step 2: switch を適用**

Run: `home-manager switch --flake .#cachyos`
Expected: エラーなく `Activating ...` まで完走。`~/.claude/settings.json` の hook command が新しい store パスへ張り替わる。

- [ ] **Step 3: live の hook を難読化入力で検証**

`~/.claude/settings.json` が指す store パスの hook を直接叩き、難読化が deny されることを確認する。

```bash
hookcmd=$(jq -r '.hooks.PreToolUse[0].hooks[0].command' ~/.claude/settings.json)
printf '%s' '{"tool_input":{"command":"git c'\''l'\''one https://github.com/x/y"}}' | bash ${hookcmd#bash }
```

Expected: `permissionDecision: "deny"` を含む JSON が出力される。

- [ ] **Step 4: 通過すべきコマンドが素通りすることを確認**

```bash
hookcmd=$(jq -r '.hooks.PreToolUse[0].hooks[0].command' ~/.claude/settings.json)
printf '%s' '{"tool_input":{"command":"git status"}}' | bash ${hookcmd#bash }
```

Expected: 出力なし（無出力で `exit 0`）。

- [ ] **Step 5: 最終コミット（差分があれば）**

```bash
git status
# flake.lock 等に差分があれば:
# git add -A && git commit -m "chore: クローン遮断 hook 強化を適用"
```

注: 起動中の Claude Code セッションは旧 hook をロード済みのため、live 挙動（セッション内で難読化 `git clone` が deny される）の確認には新規セッションが要る。Step 3/4 の直接実行で hook 単体の正しさは担保される。

---

## Self-Review

**Spec coverage:**

- 正規化マッチ（`\ " '` 除去）→ Task 1 Step 3 ✓
- 難読化ケースの deny（backslash / double-quote / single-quote / quoted-space）→ Task 1 Step 1・4 ✓
- 誤検出回帰ガード（`legit clone foo` は pass）→ Task 1 Step 1・4 ✓
- classifier 非依存（hook 単体で検証）→ Task 1 のテスト・Task 2 の直接実行 ✓
- 意味レベル回避はスコープ外 → テストケースに含めない（spec 通り）✓
- switch 適用と実機検証 → Task 2 ✓

**Placeholder scan:** プレースホルダなし。全 step に実コード・実コマンドと期待値を記載済み。

**Type consistency:** スクリプト名 `block-git-clone.sh`、テスト名 `block-git-clone.test.sh`、変数名 `command` / `stripped`、設定キー `hooks.PreToolUse` をタスク間で統一。正規化式は Task 1 Step 3 の `stripped=${command//[\\\"\']/}` で一貫。
