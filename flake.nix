{
  description = "NixOS & home-manager configuration of mkiin";

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://ezkea.cachix.org"
      "https://mkiin-dotfiles.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
      "mkiin-dotfiles.cachix.org-1:LJ6X3uYDglOyphSEDcaz/wrwGDmetitbmrUDkwvUzjM="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    flake-parts.url = "github:hercules-ci/flake-parts";
    hyprland.url = "github:hyprwm/Hyprland";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      # inputs.home-manager.follows = "home-manager";
    };

    mysecrets = {
      url = "git+ssh://git@github.com/mkiin/nix-secrets.git?shallow=1";
      flake = false;
    };

    wallpaper-namer = {
      url = "github:mkiin/wallpaper-namer/v0.2.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprcap = {
      url = "github:alonso-herreros/hyprcap";
      inputs.nixpkgs.follows = "nixpkgs";
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
    archify-skill = {
      url = "github:tt-a1i/archify";
      flake = false;
    };

  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./flake ];
    };
}
