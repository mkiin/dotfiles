{ myvars, ... }:
{
  imports = [
    ../../base/home.nix
    ../../linux/desktop
  ];

  modules.desktop.hyprland.enable = true;

  # 画面ロック・画面暗転の設定
  modules.desktop.hypridle = {
    # keyboardBacklightTimeout = 900;
    lockTimeout = 1200; # 15min
    screenOffTimeout = 1800; # 30min
  };

  # Yukino 固有のモニター設定
  wayland.windowManager.hyprland.extraLuaFiles.monitors = {
    content = ./monitors.lua;
    autoLoad = false;
  };

  # xdg.configFile."niri/niri-hardware.kdl".source =
  #   mkSymlink "${config.home.homeDirectory}/nix-config/hosts/idols-ai/niri-hardware.kdl";
}
