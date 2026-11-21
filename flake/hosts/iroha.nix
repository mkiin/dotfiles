{
  inputs,
  myvars,
  mylib,
  ...
}:
{
  flake.nixosConfigurations.iroha = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = {
      inherit inputs myvars mylib;
    };

    modules = [
      inputs.disko.nixosModules.disko
      ../../hosts/iroha/disko.nix
      ../../secrets
      ../../hosts/iroha
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
          ../../home/hosts/iroha
        ];
      }
    ];
  };
}
