{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      writeNu,
      ...
    }:
    let
      core = command: lib.getExe' pkgs.coreutils command;
      util = command: lib.getExe' pkgs.util-linux command;
      username = (import ../../vars).username;
      hosts = builtins.attrNames self.nixosConfigurations;
    in
    {
      apps.install = {
        type = "app";
        program = toString (
          writeNu "install-nixos-host" ''
            def --wrapped checked [program: string, ...args: string] {
              do --capture-errors { ^$program ...$args }
            }

            def configure-host [source: path, host: string, device: string, public_key: string] {
              if $device !~ '^/dev/disk/by-id/[a-zA-Z0-9_.:+-]+$' { error make {msg: "Unsupported characters in disk ID."} }
              let disko_file = $source | path join hosts $host disko.nix
              let layout = open --raw $disko_file
              let device_line = '(?m)^    device = "[^"]*";'
              if $layout !~ $device_line { error make {msg: "No device assignment found in disko.nix."} }
              $layout | str replace --regex $device_line $'    device = "($device)";' | save --force $disko_file
              let recipients = '${builtins.toJSON (import ../../secrets/host-keys.nix)}' | from json | upsert $host $public_key
              let declarations = $recipients | transpose host key | each {|entry|
                if $entry.key !~ '^ssh-ed25519 [A-Za-z0-9+/=]+$' { error make {msg: "Invalid host public key."} }
                $'  ($entry.host | to json --raw) = "($entry.key)";'
              } | str join "\n"
              $"{\n($declarations)\n}\n" | save --force ($source | path join secrets host-keys.nix)
              $recipients | values | each {|key| [--recipient $key] } | flatten
            }

            def check-disk [disk: string, resume: bool] {
              checked ${core "test"} -b $disk
              if $resume {
                for mountpoint in [/mnt /mnt/boot] {
                  let device = checked ${util "findmnt"} --noheadings --raw --mountpoint $mountpoint --output SOURCE | str trim
                  let parent = checked ${util "lsblk"} --noheadings --output PKNAME $device | str trim
                  if $parent != ($disk | path basename) {
                    error make {msg: $"($mountpoint) is not mounted from ($disk)"}
                  }
                }
              } else {
                let mounted = checked ${util "lsblk"} --noheadings --output MOUNTPOINTS $disk | str trim
                if ($mounted | is-not-empty) {
                  error make {msg: "Disk is mounted or has active swap. Unmount it and disable swap first."}
                }
                for mountpoint in [/mnt /mnt/boot] {
                  let mounted = ^${util "findmnt"} --mountpoint $mountpoint | complete
                  if $mounted.exit_code != 1 { error make {msg: $"($mountpoint) is already mounted or could not be checked."} }
                }
              }
            }

            def main [host: string, --dry-run, --resume, --recovery: path] {
              let hosts = '${builtins.toJSON hosts}' | from json
              if $host not-in $hosts { error make {msg: $"Unknown host: ($host)"} }
              if $dry_run {
                print {host: $host, resume: $resume, recovery: ($recovery != null)}
                return
              }
              checked ${core "test"} -t 0
              if (checked ${core "id"} -u | str trim) != "0" {
                let flags = if $resume { [--resume] } else { [] }
                let recovery_flags = if $recovery == null { [] } else { [--recovery ($recovery | path expand)] }
                exec /run/wrappers/bin/sudo (path self) $host ...$flags ...$recovery_flags
              }

              let disks = checked ${util "lsblk"} --json --bytes --nodeps --output PATH,SIZE,MODEL,SERIAL,TYPE | from json | get blockdevices | where type == disk
              let choice = $disks | each {|disk| $"($disk.path)  ($disk.size | into filesize)  ($disk.model)  ($disk.serial)" } | input list --index "Select the installation disk"
              if $choice == null { error make {msg: "Cancelled"} }
              let disk = $disks | get $choice | get path
              check-disk $disk $resume
              let ids = glob /dev/disk/by-id/* | where {|id| (checked ${core "readlink"} -f $id | str trim) == $disk } | sort
              if ($ids | is-empty) { error make {msg: "The selected disk has no by-id path."} }
              let device = $ids | first
              let work = checked ${core "mktemp"} -d /run/dotfiles-install.XXXXXX | str trim

              try {
                let source = $work | path join source
                checked ${core "cp"} -R --reflink=auto ${../..} $source
                checked ${core "chmod"} -R u+w $source
                let key = $work | path join ssh_host_ed25519_key
                if $resume and ('/mnt/etc/ssh/ssh_host_ed25519_key' | path exists) {
                  checked ${core "cp"} /mnt/etc/ssh/ssh_host_ed25519_key $key
                  checked ${lib.getExe' pkgs.openssh "ssh-keygen"} -y -f $key | save ($key + '.pub')
                } else {
                  checked ${lib.getExe' pkgs.openssh "ssh-keygen"} -q -t ed25519 -N "" -f $key
                }
                let public_key = open --raw ($key + '.pub') | str trim | split row ' ' | first 2 | str join ' '
                let recipient_flags = configure-host $source $host $device $public_key

                let secrets = if $recovery != null {
                  open --raw $recovery | from json
                } else {
                  let password = input --suppress-output "Login password: "
                  print ""
                  let confirmation = input --suppress-output "Confirm password: "
                  print ""
                  if $password == "" or $password != $confirmation { error make {msg: "Password is empty or does not match."} }
                  let hash = $password | checked ${lib.getExe pkgs.mkpasswd} --method=yescrypt --stdin | str trim
                  let rclone = $work | path join rclone.conf
                  checked ${lib.getExe pkgs.rclone} --config $rclone config
                  {user-password: $hash, rclone-r2.conf: (open --raw $rclone)}
                }
                if ($secrets.user-password | describe) != string or $secrets.user-password !~ '^\$(y|6)\$' {
                  error make {msg: "Invalid password hash in recovery data."}
                }
                if ($secrets.'rclone-r2.conf' | describe) != string or ($secrets.'rclone-r2.conf' | str trim | is-empty) {
                  error make {msg: "Rclone configuration is empty or invalid."}
                }
                for name in [user-password rclone-r2.conf] {
                  let file = $source | path join secrets $"($name).age"
                  $secrets | get $name | checked ${lib.getExe pkgs.age} ...$recipient_flags --output $file
                  let restored = checked ${lib.getExe pkgs.age} --decrypt --identity $key $file
                  if $restored != ($secrets | get $name) { error make {msg: $"Encryption verification failed for ($name)."} }
                }

                print "Building the production system before erasing the disk."
                let system = checked ${lib.getExe pkgs.nix} --extra-experimental-features 'nix-command flakes' --accept-flake-config build $"path:($source)#nixosConfigurations.($host).config.system.build.toplevel" --no-link --print-out-paths | str trim
                let partition = if $resume { null } else {
                  checked ${lib.getExe pkgs.nix} --extra-experimental-features 'nix-command flakes' build $"path:($source)?dir=installer#nixosConfigurations.($host).config.system.build.diskoScript" --no-link --print-out-paths | str trim
                }
                if (checked ${core "readlink"} -f $device | str trim) != $disk { error make {msg: "Disk connection changed."} }
                check-disk $disk $resume
                if not $resume {
                  checked ${util "lsblk"} --output NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS $disk
                  if (input $"ALL DATA WILL BE ERASED. Type ($device) to confirm: ") != $device { error make {msg: "Cancelled"} }
                  checked $partition
                }
                checked ${core "install"} -D -m 600 $key /mnt/etc/ssh/ssh_host_ed25519_key
                checked ${core "install"} -D -m 644 ($key + '.pub') /mnt/etc/ssh/ssh_host_ed25519_key.pub
                checked ${lib.getExe' pkgs.nixos-install-tools "nixos-install"} --root /mnt --system $system --no-root-passwd

                let destination = '/mnt/home/${username}/ghq/github.com/mkiin/dotfiles'
                checked ${core "mkdir"} -p ($destination | path dirname)
                if ($destination | path exists) { checked ${core "cp"} -R ($source + '/.') $destination } else { checked ${core "cp"} -R $source $destination }
                checked ${lib.getExe pkgs.git} -C $destination init -b main
                let remotes = checked ${lib.getExe pkgs.git} -C $destination remote
                if origin not-in ($remotes | lines) { checked ${lib.getExe pkgs.git} -C $destination remote add origin https://github.com/mkiin/dotfiles.git }
                checked ${lib.getExe pkgs.git} -C $destination add .
                checked ${lib.getExe pkgs.git} -C $destination -c user.name=installer -c user.email=installer@localhost -c commit.gpgsign=false commit --allow-empty -m $"Install ($host)"
                checked ${core "chown"} -R --reference /mnt/home/${username} $destination
              } catch {|error|
                checked ${core "rm"} -rf $work
                error make {msg: $error.msg}
              }
              checked ${core "rm"} -rf $work
              print "Production system installation completed."
              if (input 'Remove the USB drive and reboot? [y/N]: ') == y { checked ${lib.getExe' pkgs.systemd "systemctl"} reboot }
            }
          ''
        );
      };
    };
}
