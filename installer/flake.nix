{
  description = "Public minimal NixOS installer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    disko.url = "github:nix-community/disko/v1.13.0";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        ../flake/writers.nix
        ./apps.nix
      ];

      flake.nixosConfigurations = inputs.nixpkgs.lib.genAttrs [ "oregairu-yukino" "oregairu-yui" ] (
        hostName:
        inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs.myvars = import ../vars;
          modules = [
            inputs.disko.nixosModules.disko
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
