{
  description = "Home Manager configuration of mkiin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, nixgl, ... }:
    let
      username = "mkiin";
      homedir  = "/home/${username}";
      dotfilesDir = "${homedir}/dotfiles";

      mkHome = { system, envModule, extraArgs ? {} }: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit username homedir dotfilesDir; } // extraArgs;
        modules = [
          {
            home.username     = username;
            home.homeDirectory = homedir;
          }
          ./nix/home
          envModule
        ];
      };
    in
    {
      homeConfigurations = {
        cachyos = mkHome {
          system    = "x86_64-linux";
          envModule = ./nix/home/cachyos.nix;
          extraArgs = { nixgl = nixgl.packages."x86_64-linux"; };
        };
        wsl = mkHome { system = "x86_64-linux"; envModule = ./nix/home/wsl.nix; };
      };
    };
}
