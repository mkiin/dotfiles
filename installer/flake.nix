{
  description = "Public minimal NixOS installer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/1559d3daa3ecc813a650b79375ea61b6741b8746";
    disko.url = "github:nix-community/disko/v1.13.0";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, disko, ... }: {
    nixosConfigurations.oregairu-yui = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ../hosts/oregairu-yui/disko.nix
        ./configuration.nix
        { networking.hostName = "oregairu-yui"; }
      ];
    };
  };
}
