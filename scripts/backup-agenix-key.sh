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

# rbw edit は notes を編集し password に入らないため必ず add を使う(add は 1 行目=password)。
# 既存は先に削除して重複を防ぐ。rbw は VISUAL を EDITOR より優先し、空白入りコマンドを
# sh -c "<cmd> <tmpfile>" で実行するので、cp を editor に見せかけ一時ファイルを流し込める。
rbw remove agenix-age-key >/dev/null 2>&1 || true
VISUAL="cp $tmp" EDITOR="cp $tmp" rbw add agenix-age-key
# EDITOR トリックが将来の rbw で壊れても黙って空を保管しないよう、結果を読み戻して検証。
rbw get agenix-age-key | grep -q '^AGE-SECRET-KEY-' || {
  echo "stored value verification failed" >&2
  exit 1
}
echo "Stored age key to Bitwarden entry 'agenix-age-key'."
