{ inputs, myvars, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      writeNu,
      ...
    }:
    {
      apps.install = {
        type = "app";
        program = toString (
          writeNu "install-nixos" ''
            def main [host: string, disk: string, --dry-run] {
              if $host !~ '^[a-zA-Z0-9_-]+$' {
                error make {msg: "Invalid host name."}
              }
              if $disk !~ '^/dev/disk/by-id/[a-zA-Z0-9_.:+-]+$' {
                error make {msg: "Specify the SSD using /dev/disk/by-id/<SSD-ID>."}
              }
              let source = $env.PWD
              let file = $source | path join hosts $host disko.nix
              let layout = open --raw $file
              let pattern = '(?m)^[ \t]*device = "[^"]*";'
              if ($layout | lines | where {|line| $line =~ $pattern } | length) != 1 {
                error make {msg: "Expected one device declaration in disko.nix."}
              }
              $layout | str replace --regex $pattern $'    device = "($disk)";' | save --force $file
              let flags = if $dry_run { [--dry-run] } else { [] }
              exec ${
                lib.getExe' inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install "disko-install"
              } --flake $"path:($source)#installer-($host)" --disk system $disk --extra-files $source "${myvars.linuxhomedir}/${myvars.dotfilesdir}" --write-efi-boot-entries ...$flags
            }
          ''
        );
      };
    };
}
