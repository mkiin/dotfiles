#!/usr/bin/env bash
set -euo pipefail

DWP_FILE="${DWP_FILE:-home-manager/desktop/nikke/dwproton.nix}"
DWP_REPO="${DWP_REPO:-dawn-winery/dwproton-mirror}"

tag=$(gh api "repos/$DWP_REPO/releases/latest" --jq '.tag_name')
case "$tag" in
dwproton-*) version=${tag#dwproton-} ;;
*)
	printf 'Unexpected dwproton release tag: %s\n' "$tag" >&2
	exit 1
	;;
esac

current=$(sed -n 's/^[[:space:]]*version = "\([^"]*\)";.*/\1/p' "$DWP_FILE")
[ -n "$current" ] || {
	printf 'Could not read the current dwproton version from %s\n' "$DWP_FILE" >&2
	exit 1
}
if [ "$current" = "$version" ]; then
	printf 'dwproton is already up to date: %s\n' "$version"
	exit 0
fi

url="https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-${version}/dwproton-${version}-x86_64.tar.xz"
hash=$(nix store prefetch-file --json "$url" | jq -r '.hash')
case "$hash" in
sha256-*) ;;
*)
	printf 'Unexpected Nix hash: %s\n' "$hash" >&2
	exit 1
	;;
esac

tmp=$(mktemp "${DWP_FILE}.XXXXXX")
trap 'rm -f "$tmp"' EXIT
awk -v version="$version" -v hash="$hash" '
  /^[[:space:]]*version = "[^"]*";/ {
    sub(/"[^"]*"/, "\"" version "\"")
  }
  /^[[:space:]]*hash = "sha256-[^"]*";/ {
    sub(/"sha256-[^"]*"/, "\"" hash "\"")
  }
  { print }
' "$DWP_FILE" >"$tmp"
updated_version=$(sed -n 's/^[[:space:]]*version = "\([^"]*\)";.*/\1/p' "$tmp")
updated_hash=$(sed -n 's/^[[:space:]]*hash = "\([^"]*\)";.*/\1/p' "$tmp")
[ "$updated_version" = "$version" ] && [ "$updated_hash" = "$hash" ]
mv "$tmp" "$DWP_FILE"
trap - EXIT

printf 'Updated dwproton: %s -> %s\n' "$current" "$version"
