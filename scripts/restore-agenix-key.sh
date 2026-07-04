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

mkdir -p "$(dirname "$key")"
rbw get agenix-age-key >"$key"
chmod 600 "$key"
echo "Restored age key to $key."
