{ pkgs, ... }:

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
    mise
  ];
}
