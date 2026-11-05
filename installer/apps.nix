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
      targets = lib.mapAttrs (_: host: {
        device = host.config.disko.devices.disk.system.device;
        partition = toString host.config.system.build.diskoScript;
        system = toString host.config.system.build.toplevel;
      }) self.nixosConfigurations;
      core = command: lib.getExe' pkgs.coreutils command;
      util = command: lib.getExe' pkgs.util-linux command;
    in
    {
      apps.install = {
        type = "app";
        program = toString (
          writeNu "install-nixos-host" ''
            def --wrapped output [program: string, ...args: string] {
              let result = ^$program ...$args | complete
              if $result.exit_code != 0 { error make {msg: $"Command failed: ($program)\n($result.stderr)"} }
              $result.stdout | str trim
            }

            # Install the minimal OS. --resume keeps the filesystems already mounted at /mnt.
            def main [host: string, --dry-run, --resume] {
              let targets = '${builtins.toJSON targets}' | from json
              let target = $targets | get --optional $host
              if $target == null { error make {msg: $"Unknown host: ($host)"} }
              print $target
              if $dry_run { return }

              let disk = output ${core "readlink"} -f $target.device
              output ${core "test"} -b $disk | ignore
              let terminal = ^${core "test"} -t "0" | complete
              if $terminal.exit_code != 0 { error make {msg: "Run interactively from the NixOS ISO."} }

              if $resume {
                for mountpoint in [/mnt /mnt/boot] {
                  let device = output ${util "findmnt"} --noheadings --raw --mountpoint $mountpoint --output SOURCE
                  let parent = output ${util "lsblk"} --noheadings --output PKNAME $device
                  if $parent != ($disk | path basename) {
                    error make {msg: $"($mountpoint) is not mounted from ($disk)"}
                  }
                }
              } else {
                let mounted = output ${util "lsblk"} --noheadings --output MOUNTPOINTS $disk
                if ($mounted | is-not-empty) {
                  error make {msg: "Target disk is mounted or has active swap. Refusing to erase it."}
                }
              }

              if (output ${core "id"} -u) != "0" {
                let flags = if $resume { [--resume] } else { [] }
                exec /run/wrappers/bin/sudo (path self) $host ...$flags
              }
              if not $resume {
                ^${util "lsblk"} --output NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS $disk
                let confirmation = input $"ALL DATA WILL BE ERASED. Type ($target.device): "
                if $confirmation != $target.device { error make {msg: "Cancelled"} }
                let partition = $target.partition
                ^$partition
                if $env.LAST_EXIT_CODE != 0 { exit $env.LAST_EXIT_CODE }
              }

              exec ${lib.getExe' pkgs.nixos-install-tools "nixos-install"} --root /mnt --system $target.system --no-root-passwd
            }
          ''
        );
      };
    };
}
