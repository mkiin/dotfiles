{
  description = "Home Manager configuration of mkiin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, ... }@inputs:
  let
    mylib = import ./nix/lib { inherit inputs; };
  in
  {
    homeConfigurations = {
      cachyos = mylib.mkHome {
        system   = "x86_64-linux";
        username = "mkiin";
        modules  = [ ./nix/hosts/cachyos.nix ];
      };
      wsl = mylib.mkHome {
        system   = "x86_64-linux";
        username = "mkiin";
        modules  = [ ./nix/hosts/wsl.nix ];
      };
    };
  };
}
