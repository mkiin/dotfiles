# Invoked by the remote-install flake app under bash with errexit and pipefail.
set -euo pipefail
umask 077

die() { echo "$*" >&2; exit 1; }

action=$1
host=$2
[[ $host =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]] || die "Invalid flake hostname: $host"
[[ -f flake.nix && -f secrets/agenix-rules.nix ]] || die "Run from the root of the dotfiles checkout."
runtime=$(realpath -e "${XDG_RUNTIME_DIR:?No user runtime directory}")
case "$runtime/" in "$(pwd -P)/"*) die "Keep host private keys outside the flake checkout." ;; esac
state="$runtime/dotfiles-install-$host"
extra="$state/extra"
key="$extra/etc/ssh/ssh_host_ed25519_key"

if [[ $action == prepare ]]; then
  # mkdir is exclusive: a retry must not replace the key used to rekey secrets.
  mkdir -m 700 "$state" || die "An install is already prepared at $state."
  trap 'rm -rf -- "$state"' EXIT
  mkdir -p "$extra/etc/ssh"
  # nixos-anywhere preserves directory modes when extracting extra-files.
  chmod 755 "$extra" "$extra/etc" "$extra/etc/ssh"
  ssh-keygen -q -t ed25519 -N '' -C "$host" -f "$key"
  cat "$key.pub"
  echo "Replace this host's old entry in serverRecipients with this public key before apply." >&2
  trap - EXIT
  exit 0
fi

[[ $action == apply && $# == 5 ]] || die "Expected apply HOST LIVE DISK RECOVERY_KEY."
[[ -f $key && -f $key.pub ]] || die "Run remote-install prepare $host first."
exec 9<"$state"
flock -n 9 || die "Another installation is using $state."
live=$3
disk=$4
recovery=$5
[[ $live =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*$ ]] || die "Invalid Live SSH address: $live"
[[ $disk =~ ^/dev/disk/by-id/[a-zA-Z0-9_:+.-]+$ && ! $disk =~ -part[0-9]+$ ]] || die "Specify a whole SSD by ID."
[[ -r $recovery ]] || die "Cannot read recovery key: $recovery"

cfg=".#nixosConfigurations.$host.config"
check_layout() {
  local layout
  layout=$(nix eval --json "$1" --apply '
    c: {
      host = c.networking.hostName;
      disks = builtins.mapAttrs (_: d: d.device) c.disko.devices.disk;
      desktop = c.modules.secrets.desktop.enable;
    }')
  jq -e --arg host "$host" --arg disk "$disk" '
    .host == $host and .disks == {system: $disk} and (.desktop | not)
  ' <<<"$layout" >/dev/null || die "Expected $host with one disko system disk ($disk) and the desktop role disabled."
}
check_layout "$cfg"

# Verify that this is the installer, booted in UEFI mode, and that the
# explicitly named disk is connected to this machine, not the installer USB.
ssh_options=(-o BatchMode=yes -o StrictHostKeyChecking=yes -o ControlPath=none -o ForwardAgent=no)
# The disk argument is restricted to the by-id character set above.
# shellcheck disable=SC2029
ssh "${ssh_options[@]}" "root@$live" "sh -se -- '$disk'" <<'LIVE'
. /etc/os-release
[ "${VARIANT_ID:-}" = installer ] && [ -d /sys/firmware/efi ] || { echo "Expected a UEFI NixOS installer" >&2; exit 1; }
[ -b "$1" ] && [ "$(lsblk -dnro TYPE "$1")" = disk ] && [ "$(lsblk -dnro RM "$1")" = 0 ] && [ "$(lsblk -dnro TRAN "$1")" != usb ] || { echo "Not a non-removable, non-USB disk: $1" >&2; exit 1; }
lsblk -d -o NAME,SIZE,MODEL,SERIAL "$1"
LIVE

# Match key material, ignoring the optional OpenSSH comment.
pub=$(ssh-keygen -y -f "$key" | awk '{print $1, $2}')
rules=$(nix eval --json --file secrets/agenix-rules.nix)
jq -e --arg pub "$pub" '
  def haskey: any(.publicKeys[]; (split(" ")[:2] | join(" ")) == $pub);
  (.["user-password.age"] | haskey) and (.["rclone-r2.conf.age"] | haskey | not)
' <<<"$rules" >/dev/null || die "Register the new host key for user-password only."
jq -r '.["user-password.age"].publicKeys[]' <<<"$rules" > "$state/recipients"

# Re-encrypt just the password file. Never write its plaintext to disk.
# Serialize concurrent edits to this shared ciphertext across host installs.
exec 8<secrets
flock -n 8 || die "Another install is updating secrets."
cipher=secrets/user-password.age
if ! age --decrypt -i "$key" "$cipher" >/dev/null 2>/dev/null; then
  tmp=$(mktemp secrets/.user-password.age.XXXXXXXX)
  trap 'rm -f -- "$tmp"' EXIT
  age --decrypt -i "$recovery" "$cipher" | age --encrypt -R "$state/recipients" > "$tmp"
  age --decrypt -i "$key" "$tmp" >/dev/null
  mv -f -- "$tmp" "$cipher"
  trap - EXIT
fi

# Build exactly once and pass immutable store paths to the installer. Check
# the encrypted file in the evaluated flake, including Git's tracked files.
source_path=$(nix flake metadata --json . | jq -er .path)
cfg="$source_path#nixosConfigurations.$host.config"
check_layout "$cfg"
declared=$(nix eval --json "$cfg.age.secrets" --apply 'ss: builtins.mapAttrs (_: s: toString s.file) ss')
selected=$(jq -er '.["user-password"]' <<<"$declared")
cmp -s "$selected" "$cipher" || die "The flake does not contain the rekeyed user-password file."
while IFS= read -r file; do
  age --decrypt -i "$key" "$file" >/dev/null || die "New host key cannot decrypt $file"
done < <(jq -r '.[]' <<<"$declared")
system=$(nix build --no-link --print-out-paths "$cfg.system.build.toplevel")
disko=$(nix build --no-link --print-out-paths "$cfg.system.build.diskoScript")
flock -u 8

pins="$HOME/.ssh/dotfiles-hosts"
install -d -m 700 "$pins"
pin=$(mktemp "$pins/.$host.XXXXXXXX")
trap 'rm -f -- "$pin"' EXIT
printf '%s %s\n' "$host" "$pub" > "$pin"
export LIVE_HOST="$live"
echo "Installing $host on $live, erasing $disk" >&2
nixos-anywhere --store-paths "$disko" "$system" --build-on local \
  --target-host "root@$live" --phases disko,install,reboot \
  --ssh-option "ProxyCommand=$LIVE_SSH_PROXY" --ssh-option ControlPath=none \
  --ssh-option ForwardAgent=no --extra-files "$extra"

mv -f -- "$pin" "$pins/$host"
trap - EXIT
rm -rf -- "$state"
echo "Installed $host. Production SSH host key: $pins/$host"
