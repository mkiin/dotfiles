{ pkgs, ... }:
{
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim --clean";
  };

  environment.systemPackages = with pkgs; [
    # core
    nushell
    zsh
    bash
    neovim
    git
    gh
    zip
    unzip
    jq
    fzf
    fd
    ripgrep
    duf
    ncdu
    curl
    file
    openssh
    which
    tree
    tealdeer
    trash-cli
    fastfetch
    gnumake

    # nixos only
    btop
    dig
    wl-clipboard-rs
  ];
}
