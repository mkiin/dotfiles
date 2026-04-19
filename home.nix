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
    mise

    # シェルユーティリティ
    shellcheck
    shfmt

    # Hyprland 周辺ツール
    matugen
    awww  # 壁紙エンジン (旧名 swww)
    wallust

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
    "hypr".source = mkOutOfStoreSymlink "${dotDir}/hypr";
    "matugen".source = mkOutOfStoreSymlink "${dotDir}/matugen";
    "quickshell".source = mkOutOfStoreSymlink "${dotDir}/quickshell";
    "waybar".source = mkOutOfStoreSymlink "${dotDir}/waybar";
    "swaync".source = mkOutOfStoreSymlink "${dotDir}/swaync";
    "rofi".source = mkOutOfStoreSymlink "${dotDir}/rofi";
    "wlogout".source = mkOutOfStoreSymlink "${dotDir}/wlogout";
    "fcitx5/config".source = mkOutOfStoreSymlink "${dotDir}/fcitx5/config";
    "fcitx5/profile".source = mkOutOfStoreSymlink "${dotDir}/fcitx5/profile";
    "fcitx5/conf/notifications.conf".source = mkOutOfStoreSymlink "${dotDir}/fcitx5/conf/notifications.conf";
    "environment.d/fcitx5.conf".text = ''
      GTK_IM_MODULE=fcitx
      QT_IM_MODULE=fcitx
      XMODIFIERS=@im=fcitx
      INPUT_METHOD=fcitx
    '';
  };

  home.sessionVariables = {
  };

  # ディレクトリ構成の初期化
  home.activation.createDirectories = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/personal/apps
    mkdir -p ~/personal/tools
    mkdir -p ~/personal/experiments
    mkdir -p ~/learning/courses
    mkdir -p ~/learning/books
    mkdir -p ~/learning/practice
  '';

  programs.home-manager.enable = true;
}
