{ pkgs, ... }:

let
  gocopy = pkgs.buildGoModule {
    pname = "gocopy";
    version = "0.1.4";
    src = pkgs.fetchFromGitHub {
      owner = "atotto";
      repo  = "clipboard";
      rev   = "v0.1.4";
      hash  = "sha256-ZZ7U5X0gWOu8zcjZcWbcpzGOGdycwq0TjTFh/eZHjXk=";
    };
    subPackages = [ "cmd/gocopy" "cmd/gopaste" ];
    vendorHash = null;
  };
in

{
  home.packages = with pkgs; [
    # essentials
    curl
    ghq
    # search & file utilities
    ripgrep
    fd
    bat
    eza
    jq
    fzf
    zoxide
    # shell
    shellcheck
    shfmt
    mo
    # dev tools
    gh
    lazydocker
    gocopy
  ];
}
