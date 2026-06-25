{
  description = "Home Manager configuration of mkiin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      username = "mkiin";
      homedir  = "/home/${username}";
      dotfilesDir = "${homedir}/dotfiles";
      nixRoot = ./nix;

      mkHome = { system, hostModule, extraArgs ? {} }: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit username homedir dotfilesDir nixRoot system; } // extraArgs;
        modules = [
          {
            home.username     = username;
            home.homeDirectory = homedir;
          }
          hostModule
        ];
      };
    in
    {
      homeConfigurations = {
        cachyos = mkHome {
          system    = "x86_64-linux";
          hostModule = ./nix/hosts/cachyos;
        };
        wsl = mkHome { system = "x86_64-linux"; hostModule = ./nix/hosts/wsl; };
      };
    };
}
