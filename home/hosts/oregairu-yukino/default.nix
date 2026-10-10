{ config, ... }:
{
  imports = [
    ../../base
    ../../base/desktop
    ../../linux/desktop.nix
  ];

  programs.ssh.settings."github.com" = {
    IdentityFile = "${config.home.homeDirectory}/.ssh/oregairu-yukino";
    IdentitiesOnly = true;
  };
  programs.git.signing.key = "${config.home.homeDirectory}/.ssh/oregairu-yukino.pub";

  modules.desktop.hyprland.enable = true;
  modules.desktop.nvidia.enable = true;
  modules.desktop.pyprland.enable = true;
  modules.desktop.recording.enable = true;

  # 画面ロック・画面暗転の設定
  modules.desktop.hypridle = {
    # keyboardBacklightTimeout = 900;
    lockTimeout = 900;
    screenOffTimeout = 1800;
    suspendTimeout = 3600;
  };

  wayland.windowManager.hyprland.extraLuaFiles = {
    host-keybinds = {
      content = ./keybinds.lua;
      autoLoad = true;
    };
    monitors = {
      content = ./monitors.lua;
      autoLoad = false;
    };
  };
}
