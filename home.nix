{ config, pkgs, lib, ... }:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  dotDir = "/home/mkiin/personal/dotfiles/config";
in
{
  home.username = "mkiin";
  home.homeDirectory = "/home/mkiin";
  home.stateVersion = "25.11";

  # non-NixOS (CachyOS) で Nix 周りの XDG 変数を整える
  targets.genericLinux.enable = true;

  # systemd user manager のデフォルト環境に Nix 系 PATH を宣言的に注入。
  # これにより walker.service / elephant.service 等が ~/.nix-profile/bin を認識する。
  # (Hyprland 側 import-environment の都度流し込みを置き換える恒久対処)
  systemd.user.settings.Manager.DefaultEnvironment = {
    PATH = builtins.concatStringsSep ":" [
      "%h/.nix-profile/bin"
      "/nix/var/nix/profiles/default/bin"
      "%h/.local/bin"
      "/usr/local/sbin"
      "/usr/local/bin"
      "/usr/sbin"
      "/usr/bin"
      "/sbin"
      "/bin"
    ];
  };

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
    "awww".source = mkOutOfStoreSymlink "${dotDir}/awww";
    "quickshell".source = mkOutOfStoreSymlink "${dotDir}/quickshell";
    "waybar".source = mkOutOfStoreSymlink "${dotDir}/waybar";
    "swaync".source = mkOutOfStoreSymlink "${dotDir}/swaync";
    "wlogout".source = mkOutOfStoreSymlink "${dotDir}/wlogout";
    "fcitx5/config".source = mkOutOfStoreSymlink "${dotDir}/fcitx5/config";
    "fcitx5/profile".source = mkOutOfStoreSymlink "${dotDir}/fcitx5/profile";
    "fcitx5/conf/notifications.conf".source = mkOutOfStoreSymlink "${dotDir}/fcitx5/conf/notifications.conf";
    # Walker (ランチャー + 壁紙セレクタ基盤)。
    # programs.walker.enable で package/service のみ使い、config/theme は dotfiles 側で管理。
    "walker".source = mkOutOfStoreSymlink "${dotDir}/walker";
    # Elephant の menus プロバイダ (wallselect.lua のみ)。
    # elephant/providers/*.so は HM 側が生成するため dir ごと symlink しない。
    "elephant/menus/wallselect.lua".source = mkOutOfStoreSymlink "${dotDir}/elephant/menus/wallselect.lua";
    "environment.d/fcitx5.conf".text = ''
      GTK_IM_MODULE=fcitx
      QT_IM_MODULE=fcitx
      XMODIFIERS=@im=fcitx
      INPUT_METHOD=fcitx
    '';
  };

  home.sessionVariables = {
  };

  # Walker: パッケージ + systemd service のみ使う。
  # config.toml / themes/*.css+*.xml は dotfiles 側で管理するため、
  # HM モジュールによる xdg.configFile 生成を lib.mkForce {} で無効化。
  programs.walker = {
    enable = true;
    runAsService = true;
    config = lib.mkForce {};
    themes = lib.mkForce {};
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
