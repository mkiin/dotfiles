{ config, pkgs, ... }:

{
  home.username = "mkiin";
  home.homeDirectory = "/home/mkiin";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # CLIユーティリティ
    ripgrep
    fd
    fzf
    bat
    eza
    jq
    delta
    zoxide
    lazygit
    lazydocker
    gh
    starship
    sheldon
    neovim

    # シェルユーティリティ
    shellcheck
    shfmt

    # 基本ツール
    git
    curl
    wget
    unzip
  ];

  home.file = {
  };

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}
