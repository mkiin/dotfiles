#!/usr/bin/env bash
set -euo pipefail
set +x
umask 077
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/repo/installer"
cp "$repo/flake.lock" "$work/repo/flake.lock"
git init -q "$work/repo"
cd "$work/repo"
export XDG_STATE_HOME="$work/state"
bash "$repo/scripts/set-installer-password.sh" --generate
password="$work/state/dotfiles-installer/initial-password"
[[ $(stat -c %a "$password") == 600 ]]
[[ $(stat -c %a "$(dirname "$password")") == 700 ]]
mkpasswd --method=yescrypt --salt "$(<installer/initial-password-hash)" \
  --stdin <"$password" | cmp -s - installer/initial-password-hash
[[ $(git ls-files) == installer/initial-password-hash ]]
if git grep --cached -F -q -f "$password"; then
  echo 'Plaintext password entered Git.' >&2
  exit 1
fi
before=$(sha256sum installer/initial-password-hash "$password")
if bash "$repo/scripts/set-installer-password.sh" --generate; then
  echo 'Existing password was replaced.' >&2
  exit 1
else
  [[ $? == 1 ]]
fi
[[ $(sha256sum installer/initial-password-hash "$password") == "$before" ]]
echo 'Installer password tests passed.'
