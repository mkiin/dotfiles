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

      {
        programs.hyprland.enable = true;
        modules.desktop.fonts.enable = true;
        modules.desktop.gaming.enable = true;
      }

      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        home-manager.extraSpecialArgs = {
          inherit inputs vars mylib;
        };

        home-manager.users.${vars.username}.imports = [
          ../../home/hosts/oregairu-yukino
        ];
      }
    ];
  };
}
