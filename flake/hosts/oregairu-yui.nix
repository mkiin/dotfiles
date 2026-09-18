{ inputs, myvars, ... }:
{
  flake.nixosConfigurations.oregairu-yui = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = {
      inherit inputs myvars;
    };

    modules = [
      ../../hosts/oregairu-yui
    ];
  };
}
