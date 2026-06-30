{
  description = "NixOS & home-manager configuration of mkiin";

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    hyprland.url = "github:hyprwm/Hyprland";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    mcp-servers-nix.inputs.nixpkgs.follows = "nixpkgs";

    xremap.url = "github:xremap/nix-flake";
    xremap.inputs.nixpkgs.follows = "nixpkgs";

    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    agent-skills.inputs.nixpkgs.follows = "nixpkgs";
    agent-skills.inputs.home-manager.follows = "home-manager";

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

  outputs =
    { self, ... }@inputs:
    let
      mylib = import ./lib inputs;
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs { inherit system; };
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./lib/treefmt;
      nom = pkgs.lib.getExe pkgs.nix-output-monitor;
    in
    {
      nixosConfigurations.nixos = mylib.makeNixosConfig {
        system = "x86_64-linux";
        hostname = "nixos";
        username = "mkiin";
        modules = [ ./hosts/nixos ];
      };

      homeConfigurations."mkiin@wsl" = mylib.makeHomeManagerConfig {
        system = "x86_64-linux";
        username = "mkiin";
        modules = [ ./hosts/wsl/home-manager.nix ];
      };

      formatter.${system} = treefmtEval.config.build.wrapper;
      packages.${system}.fmt = treefmtEval.config.build.wrapper;

      # ローカル用カスタムコマンド: nix run .#<name>
      apps.${system} = {
        # flake.lock を更新する
        update = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "update" ''
              set -e
              echo "Updating flake.lock..."
              nix flake update
              echo "Done! Run 'nix run .#switch' to apply changes."
            ''
          );
        };

        # nixos 構成をビルドだけする（反映はしない）
        build = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "build" ''
              set -e
              echo "Building nixos configuration..."
              ${nom} build .#nixosConfigurations.nixos.config.system.build.toplevel "$@"
              echo "Build successful! Run 'nix run .#switch' to apply."
            ''
          );
        };

        # nixos 構成をビルドして反映する
        switch = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "switch" ''
              set -eo pipefail
              echo "Building and switching nixos configuration..."
              sudo nixos-rebuild switch --flake .#nixos "$@" |& ${nom}
              echo "Done!"
            ''
          );
        };
      };
    };
}
