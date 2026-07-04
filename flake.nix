{
  description = "NixOS & home-manager configuration of mkiin";

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://ezkea.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "ezkea.cachix.org-1:/Hcp/kUFmp+2FLdzXlmDF9SHFsMzQoPZWH8fXOTdVBM="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    hyprland.url = "github:hyprwm/Hyprland";

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    aagl.url = "github:ezKEa/aagl-gtk-on-nix";
    aagl.inputs.nixpkgs.follows = "nixpkgs";

    anime-games-launcher = {
      url = "github:an-anime-team/anime-games-launcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    inputs:
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

      apps.${system} = {
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

        backup-agenix-key = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "backup-agenix-key" ''
              set -eo pipefail
              rbw="${pkgs.rbw}/bin/rbw"
              key="$HOME/.config/agenix/key.txt"

              # 非対話だと rbw が $EDITOR を使わず stdin を読み、空値を保管しうるため端末必須。
              [ -t 0 ] || { echo "run interactively (needs a tty for rbw)" >&2; exit 1; }
              [ -e "$key" ] || { echo "no key at $key" >&2; exit 1; }
              "$rbw" unlocked || { echo "rbw is locked. run: rbw unlock" >&2; exit 1; }

              tmp=$(mktemp)
              trap 'rm -f "$tmp"' EXIT
              # grep が 0 件だと set -e で即死し下の親切なエラーが出ないため || true。-m1 で 1 行に限定。
              grep -m1 '^AGE-SECRET-KEY-' "$key" > "$tmp" || true
              [ -s "$tmp" ] || { echo "no AGE-SECRET-KEY line in $key" >&2; exit 1; }

              # rbw は $EDITOR に一時ファイルを渡す。空白入り EDITOR を sh -c 経由で実行する挙動を使い
              # cp を editor に見せかけ内容を流し込む。既存エントリは重複防止で edit にする。
              if "$rbw" get agenix-age-key >/dev/null 2>&1; then
                EDITOR="cp $tmp" "$rbw" edit agenix-age-key
              else
                EDITOR="cp $tmp" "$rbw" add agenix-age-key
              fi
              echo "Stored age key to Bitwarden entry 'agenix-age-key'."
            ''
          );
        };

        restore-agenix-key = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "restore-agenix-key" ''
              set -eo pipefail
              # home-manager 適用前でも動くよう rbw と pinentry を nix から供給する。
              export PATH="${pkgs.pinentry-curses}/bin:$PATH"
              rbw="${pkgs.rbw}/bin/rbw"
              key="$HOME/.config/agenix/key.txt"

              if [ -e "$key" ]; then
                echo "key already exists at $key (refusing to overwrite)" >&2
                exit 1
              fi

              "$rbw" config set email blckcaties@gmail.com
              "$rbw" config set pinentry pinentry-curses

              # 既に unlock 済みなら login/unlock を飛ばす。マスターパスワードの手入力が唯一の起点。
              if ! "$rbw" unlocked 2>/dev/null; then
                "$rbw" login
                "$rbw" unlock
              fi

              mkdir -p "$(dirname "$key")"
              "$rbw" get agenix-age-key > "$key"
              chmod 600 "$key"
              echo "Restored age key to $key."
            ''
          );
        };
      };
    };
}
