{
  description = "Public minimal NixOS installer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko/v1.13.0";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, disko, ... }: {
    nixosConfigurations = nixpkgs.lib.genAttrs [ "oregairu-yukino" "oregairu-yui" ] (
      hostName:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs.myvars = import ../vars;
        modules = [
          disko.nixosModules.disko
          ../hosts/${hostName}/disko.nix
          ./configuration.nix
          ../modules/nixos/base/user-group.nix
          ../modules/nixos/base/ssh.nix
          ../modules/nixos/base/i18n.nix
          { networking.hostName = hostName; }
        ];
      }
    );
  };
}
