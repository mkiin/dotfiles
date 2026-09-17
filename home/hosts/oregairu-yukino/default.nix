{ vars, ... }:
{
  imports = [
    ../../base/home.nix
    ../../linux/desktop
  ];

  home.homeDirectory = "/home/${vars.username}";

  # Home Manager 側の有効化
  modules.desktop.hyprland.enable = true;

  # Yukino 固有のモニター設定
  wayland.windowManager.hyprland.extraLuaFiles.monitors = {
    content = ./monitors.lua;
    autoLoad = false;
  };

  # xdg.configFile."niri/niri-hardware.kdl".source =
  #   mkSymlink "${config.home.homeDirectory}/nix-config/hosts/idols-ai/niri-hardware.kdl";
}
