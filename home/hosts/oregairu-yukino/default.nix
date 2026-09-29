{ config, ... }:
{
  imports = [
    ../../base
    ../../linux/desktop
  ];

  programs.ssh.settings."github.com" = {
    IdentityFile = "${config.home.homeDirectory}/.ssh/oregairu-yukino";
    IdentitiesOnly = true;
  };
  programs.git.signing.key = "${config.home.homeDirectory}/.ssh/oregairu-yukino.pub";

  modules.desktop.hyprland.enable = true;

  # 画面ロック・画面暗転の設定
  modules.desktop.hypridle = {
    # keyboardBacklightTimeout = 900;
    lockTimeout = 30; # 20jmin
    screenOffTimeout = 60; # 30min
  };

  # Yukino 固有のモニター設定
  wayland.windowManager.hyprland.extraLuaFiles.monitors = {
    content = ./monitors.lua;
    autoLoad = false;
  };

  # xdg.configFile."niri/niri-hardware.kdl".source =
  #   mkSymlink "${config.home.homeDirectory}/nix-config/hosts/idols-ai/niri-hardware.kdl";
}
