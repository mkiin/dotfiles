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
