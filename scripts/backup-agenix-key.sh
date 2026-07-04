key="$HOME/.config/agenix/key.txt"

# 非対話だと rbw が $EDITOR を使わず stdin を読み、空値を保管しうるため端末必須。
[ -t 0 ] || {
  echo "run interactively (needs a tty for rbw)" >&2
  exit 1
}
[ -e "$key" ] || {
  echo "no key at $key" >&2
  exit 1
}
rbw unlocked || {
  echo "rbw is locked. run: rbw unlock" >&2
  exit 1
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
# grep が 0 件だと set -e で即死し下の親切なエラーが出ないため || true。-m1 で 1 行に限定。
grep -m1 '^AGE-SECRET-KEY-' "$key" >"$tmp" || true
[ -s "$tmp" ] || {
  echo "no AGE-SECRET-KEY line in $key" >&2
  exit 1
}

# rbw は $EDITOR に一時ファイルを渡す。空白入り EDITOR を sh -c 経由で実行する挙動を使い
# cp を editor に見せかけ内容を流し込む。既存エントリは重複防止で edit にする。
if rbw get agenix-age-key >/dev/null 2>&1; then
  EDITOR="cp $tmp" rbw edit agenix-age-key
else
  EDITOR="cp $tmp" rbw add agenix-age-key
fi
echo "Stored age key to Bitwarden entry 'agenix-age-key'."
