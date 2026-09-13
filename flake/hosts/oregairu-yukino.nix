{ inputs, vars, ... }:
let
  inherit (vars) linuxhomedir;
  dotfilesdir = "${linuxhomedir}/ghq/github.com/mkiin/dotfiles";
in
{
  flake.nixosConfigurations.oregairu-yukino = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = {
      inherit inputs vars dotfilesdir;
    };

    modules = [
      ../../hosts/oregairu-yukino
    ];
  };
}
