{
  inputs,
  myvars,
  mylib,
  ...
}:
{
  flake.nixosConfigurations.oregairu-iroha = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = {
      inherit inputs myvars mylib;
    };

    modules = [
      inputs.disko.nixosModules.disko
      ../../hosts/oregairu-iroha/disko.nix
      ../../secrets
      ../../hosts/oregairu-iroha
      ../../modules/nixos/server

      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = {
          inherit inputs myvars mylib;
        };
        home-manager.users.${myvars.username}.imports = [
          ../../home/hosts/oregairu-iroha
        ];
      }
    ];
  };
}
