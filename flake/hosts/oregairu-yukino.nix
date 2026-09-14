{
  inputs,
  vars,
  mylib,
  ...
}:
{
  flake.nixosConfigurations.oregairu-yukino = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = {
      inherit inputs vars mylib;
    };

    modules = [
      ../../hosts/oregairu-yukino
      ../../modules/nixos/desktop
    ];
  };
}
