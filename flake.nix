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

      checks.${system} = {
        flake-evaluation =
          let
            cachyos = self.homeConfigurations.cachyos.activationPackage;
            wsl = self.homeConfigurations.wsl.activationPackage;
          in
          pkgs.runCommand "flake-evaluation" { inherit cachyos wsl; } "touch $out";

        common-config-paths =
          let
            config = self.homeConfigurations.cachyos.config;
            requiredPaths = [
              ".zshrc"
              ".zshenv"
              ".gitconfig"
              "mise/config.toml"
            ];
            missingPaths = builtins.filter (
              path:
              !(builtins.hasAttr path config.home.file)
              && !(builtins.hasAttr path config.xdg.configFile)
            ) requiredPaths;
          in
          pkgs.runCommand "common-config-paths" { } ''
            if [ -n "${builtins.concatStringsSep " " missingPaths}" ]; then
              echo "Missing managed configuration paths: ${builtins.concatStringsSep " " missingPaths}" >&2
              exit 1
            fi
            touch $out
          '';
      };
    };
}
