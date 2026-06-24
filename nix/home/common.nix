{ pkgs, ... }:

{
  imports = [
    ./zsh
    ./git.nix
    ./mise.nix
  ];

  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    eza
    jq
    fzf
    zoxide
    lazygit
    lazydocker
    gh
    starship
    sheldon
    shellcheck
    shfmt
    delta
    mo
  ];
}
