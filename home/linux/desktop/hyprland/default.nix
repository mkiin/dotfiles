{ config, lib, ... }:
let
  cfg = config.modules.desktop.hyprland;

  luaModules = [
    "vars"
    "color-scheme"
    "appearance"
    "input"
    "keybinds"
    "rules"
  ];
in
{
  options.modules.desktop.hyprland.enable = lib.mkEnableOption "personal Hyprland configuration";

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      systemd.enable = false;
      configType = "lua";

      extraLuaFiles = lib.genAttrs luaModules (name: {
        content = ./conf + "/${name}.lua";
        autoLoad = false;
      });

      extraConfig = builtins.readFile ./conf/hyprland.lua;
    };
  };
}
