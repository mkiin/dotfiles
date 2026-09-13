{ inputs, vars, ... }:
{
  flake.nixosConfigurations.oregairu-yui = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = {
      inherit inputs vars;
    };

    modules = [
      ../../hosts/oregairu-yui
    ];
  };
}
