# git clone 遮断 hook の正規化マッチ強化

## 背景と課題

`git clone` を遮断し `ghq get` へ誘導する PreToolUse hook（`claude/hooks/block-git-clone.sh`）は、判定が**生コマンド文字列に対する正規表現マッチ 1 本**だけで構成されている。

```
(^|[^[:alnum:]_])git[[:space:]]+clone([^[:alnum:]_]|$)
```

これは「`git` の直後に空白、その直後に `clone`」という**字面の隣接**しか見ていないため、シェルが同義に解釈しつつ字面が崩れる書き方ですり抜ける。実際の調査で以下の字句難読化がすべて hook を通過することを確認した。

- `git cl\one <url>` — バックスラッシュ（`\o` は `o` に畳まれて `git clone` が実行される）
- `git "clone" <url>` / `git c'l'one <url>` — クォート分割
- `git" "clone <url>` — クォートで囲った空白

なお、これらの難読化は実環境では Claude Code の auto-mode classifier が意図ベースで別途遮断したが、**classifier への依存は設計前提に含めない**。hook 単体で字句難読化まで堅牢に塞ぐ。

## 脅威モデル

この hook は **「協力的な AI が反射的に `git clone` と打つ」のを `ghq get` へ誘導するガードレール**であり、敵対者に対するセキュリティ境界ではない。したがって防御範囲は**字句レベルの難読化まで**とする。

実行しない限り値が確定しない**意味レベルの回避**は、静的な PreToolUse hook では原理的に捕捉できないため、本設計のスコープ外として明記する。

- 変数展開: `s=clone; git $s <url>`
- コマンド置換: `git $(echo clone) <url>`
- 行継続をまたぐ分割: `git cl\`〔改行〕`one <url>`
- git 以外の取得経路: `gh repo clone` / `pip install git+...` / `go install` / `curl ...|sh`

これらは「諦める」。完全防御を静的解析で目指さない。

## 解決方針

判定の**前に**コマンド文字列から字句難読化に使われる文字 `\ " '` を除去（正規化）し、正規化後の文字列に対して既存の正規表現をかける。

空白・タブ・改行は既存正規表現の `[[:space:]]+` がすでに吸収するため、追加の空白処理は不要。変更は実質「正規化 1 行の追加」と「マッチ対象の差し替え」に閉じる。

## 変更コンポーネント

### `claude/hooks/block-git-clone.sh` — 正規化ステップを追加

```bash
input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# 字句難読化（バックスラッシュ・クォート）を剥がす
stripped="${command//[\\\"\']/}"

if [[ "$stripped" =~ (^|[^[:alnum:]_])git[[:space:]]+clone([^[:alnum:]_]|$) ]]; then
  ...
fi
```

- `command` の取得・deny JSON の出力・ルールテキストは現状のまま。
- マッチ対象を `command` から `stripped` に差し替える。正規表現自体は変更しない。
- `stripped` 後はいずれの字句難読化も `git clone` へ正規化されるため、既存正規表現でそのまま捕捉できる。

## データフロー

1. AI が難読化した `git clone`（例 `git "clone" <url>`）を発行。
2. PreToolUse hook が `tool_input.command` を取得。
3. `\ " '` を除去 → `git clone <url>` に正規化。
4. 既存正規表現がマッチ → `deny` + ルールテキスト注入。
5. AI は `ghq get <url>` に切り替える。

## 誤検出（false positive）の検討

クォート除去は隣接トークンを融合させうる（例 `echo "git" "clone"` → `echo git clone` 化）。ただし `git` の直前に非英数字境界を要求する既存正規表現が効くため、実害のある誤検出は出ない。

- `legit clone foo` → `git` の直前が `e`（英数字）なので非マッチ。回帰ガードとして既存テストで担保する。
- `echo git clone` のような人為的ケースのみ理論上ヒットするが、実運用では無視できる範囲とする。

## テスト

既存の一時テストハーネス（`block-git-clone.test.sh`、実装時に作成し最後に削除）に難読化ケースを追加する。

- `assert_deny` 追加: `git cl\one https://...` / `git "clone" https://...` / `git c'l'one https://...`
- `assert_deny` 維持: `git clone https://...`（素の形）/ `git clone git@...`（ssh）
- `assert_pass` 維持: `ghq get https://...` / `git status` / `legit clone foo`（誤検出回帰ガード）

## 設計上の判断

- **正規化は `\ " '` の除去に限定**: 空白系は既存正規表現が吸収済みのため触らない。最小差分に保つ。
- **classifier 非依存**: hook 単体で字句難読化を塞ぐ。多層防御の存在は前提にしない。
- **意味レベル回避はスコープ外**: 静的解析の原理的限界として明記し、追わない。

## 検証

1. `bash claude/hooks/block-git-clone.test.sh` が全 `ok`・終了コード 0。
2. `home-manager build --flake .#cachyos` がエラーなく完走。
3. Claude Code セッションで `git "clone" <url>` 等の難読化を試行すると deny + ルール表示、`git status` / `ghq get` は通過する。

## スコープ外

- 意味レベルの回避（変数展開・コマンド置換・行継続分割・git 以外の取得経路）への対応。
- 別ツール経由のソース取得（`gh repo clone` 等）の遮断。必要なら別タスク。
