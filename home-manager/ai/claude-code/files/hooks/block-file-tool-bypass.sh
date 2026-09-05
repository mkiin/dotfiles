#!/usr/bin/env bash
# Claude Code PreToolUse hook: Read/Write/Edit の代わりに Bash でファイルを
# 読み書きする迂回を遮断する。プロンプト層の指示（CLAUDE.md・内部フラグ）は
# エージェントが無視しうるため、ハーネス側で機械的に落とす。
set -u

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[[ -z $command ]] && exit 0

deny() {
  jq -n --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

# 字句難読化（バックスラッシュ・クォート）を剥がす
stripped=${command//[\\\"\']/}

# scratchpad は一時ファイル置き場なので全面的に許可する
is_scratch() { [[ $1 == /tmp/claude-* ]]; }

readers="cat head tail less more bat nl od xxd hexdump"

# 値を取るフラグの直後トークンを除外して、ファイル操作対象の数を数える。
# $1 は値を取るフラグの一覧（コマンドごとに異なる。sed の -n は値を取らない）、
# $2 が pathlike なら「パス形らしいトークン」だけ数える（awk のスクリプト本体を除くため）
count_operands() {
  local value_flags=" $1 " mode=$2 prev="" tok n=0
  shift 2
  for tok in "$@"; do
    if [[ $prev == -* && $value_flags == *" $prev "* ]]; then
      prev=$tok
      continue
    fi
    prev=$tok
    [[ $tok == -* ]] && continue
    [[ $tok =~ ^[0-9]+$ ]] && continue
    is_scratch "$tok" && continue
    [[ $mode == pathlike && ! ($tok == */* || $tok =~ \.[A-Za-z0-9]+$) ]] && continue
    n=$((n + 1))
  done
  printf '%s' "$n"
}

# 複合コマンドを文単位 → パイプ段単位にほどく。段 0 だけが stdin にファイルを取る
norm=${stripped//&&/$'\x01'}
norm=${norm//||/$'\x01'}
norm=${norm//;/$'\x01'}
norm=${norm//$'\n'/$'\x01'}

IFS=$'\x01' read -ra statements <<<"$norm"

for statement in "${statements[@]}"; do
  [[ -z ${statement// /} ]] && continue

  # リダイレクト先が実ファイルかどうか（/dev/null・fd 複製・scratchpad は除く）
  writes_file=0
  while [[ $statement =~ (^|[^0-9\<\>\&])\>\>?[[:space:]]*([^[:space:]\&\|]+) ]]; do
    target=${BASH_REMATCH[2]}
    statement=${statement/"${BASH_REMATCH[0]}"/ }
    [[ $target == /dev/* ]] && continue
    is_scratch "$target" && continue
    writes_file=1
  done
  [[ $statement == *"<<"* ]] && heredoc=1 || heredoc=0

  IFS='|' read -ra stages <<<"$statement"

  for i in "${!stages[@]}"; do
    read -ra toks <<<"${stages[$i]}"

    # 環境変数代入とラッパを剥がして実コマンドまで進む
    while ((${#toks[@]})) && [[ ${toks[0]} == *=* || ${toks[0]} =~ ^(sudo|command|builtin|time|nohup|exec|env)$ ]]; do
      toks=("${toks[@]:1}")
    done
    ((${#toks[@]})) || continue

    cmd=${toks[0]##*/}
    args=("${toks[@]:1}")

    case $cmd in
    grep | egrep | fgrep)
      deny '`grep` は禁止です。検索は `rg -uu` を使ってください（CLAUDE.md の Shell Tooling Rules）。ファイル内容そのものが必要なら Read ツールで読んでください。'
      ;;
    find)
      deny '`find` は禁止です。ファイル探索は `fd -HI` を使ってください（CLAUDE.md の Shell Tooling Rules）。'
      ;;
    tee)
      if [[ $(count_operands "" any "${args[@]}") -gt 0 ]]; then
        deny '`tee` でのファイル書き込みは禁止です。ファイルを作る・書き換えるなら Write / Edit ツールを使ってください。'
      fi
      ;;
    truncate | dd)
      deny "\`$cmd\` でのファイル書き換えは禁止です。Write / Edit ツールを使ってください。"
      ;;
    sed | perl | awk | ed)
      if [[ " ${args[*]} " == *" -i"* || " ${args[*]} " == *" inplace"* || $cmd == ed ]]; then
        deny "\`$cmd\` によるファイルの in-place 編集は禁止です。編集は Edit ツールで行ってください（Edit は対象を Read 済みであることを強制するため、盲撃ちの書き換えを防げます）。"
      fi
      # sed/awk は「スクリプト + ファイル」の 2 オペランドで初めて読み取りになる
      if [[ $i -eq 0 && ($cmd == sed || $cmd == awk) && $(count_operands "-e -f" pathlike "${args[@]}") -ge 1 ]]; then
        deny "\`$cmd\` でファイルを読むのは禁止です。ファイルの内容は Read ツールで読んでください。"
      fi
      ;;
    *)
      if [[ $i -eq 0 && " $readers " == *" $cmd "* ]]; then
        # tail -f はログ追従であって読み取り迂回ではない
        [[ $cmd == tail && " ${args[*]} " =~ " -"[fF] ]] && continue
        if [[ $(count_operands "-n -c -N -j -s -A -t -w" any "${args[@]}") -gt 0 ]]; then
          deny "\`$cmd\` でファイルを読むのは禁止です。ファイルの内容は Read ツールで読んでください（行数指定が必要なら Read の offset / limit を使う）。"
        fi
      fi
      ;;
    esac

    # リテラル内容の書き出しだけを落とす。プログラム出力のログ捕捉は通す
    if [[ $i -eq 0 && $writes_file -eq 1 ]]; then
      if [[ $heredoc -eq 1 || $cmd =~ ^(echo|printf|cat|:)$ ]]; then
        deny "リダイレクトや heredoc でファイルの内容を書き出すのは禁止です。ファイルを作る・書き換えるなら Write / Edit ツールを使ってください。コマンドの実行結果をログに落とすリダイレクトは許可されています。"
      fi
    fi
  done
done

exit 0
