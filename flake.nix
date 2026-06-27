{
  description = "Home Manager configuration of mkiin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    superpowers-skill = {
      url = "github:obra/superpowers";
      flake = false;
    };
    cloudflare-skills = {
      url = "github:cloudflare/skills";
      flake = false;
    };
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
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
