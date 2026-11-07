{
  inputs,
  lib,
  myvars,
  ...
}:
let
  hosts = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../hosts)
  );
in
{
  flake.nixosConfigurations = lib.genAttrs (map (host: "installer-${host}") hosts) (
    name:
    let
      host = lib.removePrefix "installer-" name;
    in
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs myvars; };
      modules = [
        inputs.disko.nixosModules.disko
        ../../hosts/${host}/disko.nix
        ../../installer/configuration.nix
        ../../modules/nixos/base/user-group.nix
        ../../modules/nixos/base/ssh.nix
        ../../modules/nixos/base/i18n.nix
        { networking.hostName = host; }
      ];
    }
  );
}
