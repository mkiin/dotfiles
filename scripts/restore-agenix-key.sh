key="$HOME/.config/agenix/key.txt"

if [ -e "$key" ]; then
  echo "key already exists at $key (refusing to overwrite)" >&2
  exit 1
fi

rbw config set email blckcaties@gmail.com
rbw config set pinentry pinentry-curses

# 既に unlock 済みなら login/unlock を飛ばす。マスターパスワードの手入力が唯一の起点。
if ! rbw unlocked 2>/dev/null; then
  rbw login
  rbw unlock
fi

# rbw get 失敗時に空の key.txt を残すと overwrite ガードで詰むため一時ファイル経由。
# install -m400 で権限を最初から絞り world-readable な窓を作らない。
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
rbw get agenix-age-key >"$tmp"
grep -q '^AGE-SECRET-KEY-' "$tmp" || {
  echo "fetched value is not an age key" >&2
  exit 1
}
mkdir -p "$(dirname "$key")"
install -m400 "$tmp" "$key"
echo "Restored age key to $key."
