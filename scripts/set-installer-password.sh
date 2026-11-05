#!/usr/bin/env bash
set -euo pipefail
set +x
umask 077
repo=$(git rev-parse --show-toplevel)
cd "$repo"
[[ $# == 0 || ($# == 1 && $1 == --generate) ]] || {
  echo "Usage: $0 [--generate]" >&2
  exit 2
}
if [[ ${1:-} == --generate ]]; then
  [[ ! -e installer/initial-password-hash ]] || {
    echo 'Installer password already configured; refusing to replace it.' >&2
    exit 1
  }
  state=$(realpath -m "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-installer")
  case "$state/" in
  "$repo/"*)
    echo 'Password storage must be outside Git.' >&2
    exit 1
    ;;
  esac
  install -d -m 700 "$state"
  if [[ ! -e "$state/initial-password" ]]; then
    (
      set -C
      head -c 24 /dev/urandom | base64 >"$state/initial-password"
    )
  fi
  [[ -f "$state/initial-password" && ! -L "$state/initial-password" ]] || exit 1
  chmod 600 "$state/initial-password"
fi
revision=$(nix eval --impure --raw --expr \
  'let l = builtins.fromJSON (builtins.readFile ./flake.lock); in l.nodes.nixpkgs.locked.rev')
hash=$(mktemp "$repo/installer/.password-hash.XXXXXX")
trap 'rm -f "$hash"' EXIT
# Only the hash reaches the worktree. The password never becomes an argument.
if [[ ${1:-} == --generate ]]; then
  nix --option access-tokens '' shell "github:NixOS/nixpkgs/$revision#mkpasswd" \
    -c mkpasswd --stdin --method=yescrypt <"$state/initial-password" >"$hash"
else
  nix --option access-tokens '' shell "github:NixOS/nixpkgs/$revision#mkpasswd" \
    -c mkpasswd --method=yescrypt >"$hash"
fi
grep -q '^[$]y[$]' "$hash" || {
  echo 'Password hashing failed.' >&2
  exit 1
}
mv "$hash" installer/initial-password-hash
git add -- installer/initial-password-hash
echo 'Installer password hash created and staged.'
if [[ ${1:-} == --generate ]]; then
  printf 'Password saved outside Git: %s/initial-password\n' "$state"
fi
