{ config, pkgs, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  dotDir = "/home/mkiin/personal/dotfiles/config";
in
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

    # ターミナル
    ghostty

    # 基本ツール
    git
    curl
    wget
    zip
    unzip
    zsh
    gnupg
    openssh
  ];

  # dotfiles の配置
  home.file = {
    ".zshrc".source = mkOutOfStoreSymlink "${dotDir}/zsh/.zshrc";
    ".zshenv".source = mkOutOfStoreSymlink "${dotDir}/zsh/.zshenv";
    ".gitconfig".source = mkOutOfStoreSymlink "${dotDir}/git/.gitconfig";
    ".npmrc".source = mkOutOfStoreSymlink "${dotDir}/.npmrc";
  };

  xdg.configFile = {
    "ghostty/config".source = mkOutOfStoreSymlink "${dotDir}/ghostty/config";
    "lazygit/config.yml".source = mkOutOfStoreSymlink "${dotDir}/lazygit/config.yml";
    "lazydocker/config.yml".source = mkOutOfStoreSymlink "${dotDir}/lazydocker/config.yml";
    "starship/starship.toml".source = mkOutOfStoreSymlink "${dotDir}/starship/starship.toml";
    "sheldon/plugins.toml".source = mkOutOfStoreSymlink "${dotDir}/sheldon/plugins.toml";
    "mise/config.toml".source = mkOutOfStoreSymlink "${dotDir}/mise/config.toml";
    "uv/uv.toml".source = mkOutOfStoreSymlink "${dotDir}/uv/uv.toml";
    "pip/pip.conf".source = mkOutOfStoreSymlink "${dotDir}/pip/pip.conf";
    "wezterm/wezterm.lua".source = mkOutOfStoreSymlink "${dotDir}/wezterm/wezterm.lua";
    "nvim".source = mkOutOfStoreSymlink "${dotDir}/nvim";
    "environment.d/fcitx5.conf".text = ''
      GTK_IM_MODULE=fcitx
      QT_IM_MODULE=fcitx
      XMODIFIERS=@im=fcitx
      INPUT_METHOD=fcitx
    '';
  };

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
  };

  programs.home-manager.enable = true;
}
