{
  description = "Home Manager configuration of mkiin";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations = {
        cachyos = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./nix/home.nix ./nix/home/cachyos.nix ];
        };

        wsl = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./nix/home.nix ./nix/home/wsl.nix ];
        };
      };

      checks.${system}.flake-evaluation =
        let
          cachyos = self.homeConfigurations.cachyos.activationPackage;
          wsl = self.homeConfigurations.wsl.activationPackage;
        in
        pkgs.runCommand "flake-evaluation" { inherit cachyos wsl; } "touch $out";
    };
}
