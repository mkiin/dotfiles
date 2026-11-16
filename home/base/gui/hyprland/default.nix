{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop.hyprland;

  screenshotWindow = pkgs.writeShellApplication {
    name = "screenshot-window-by-app";
    runtimeInputs = with pkgs; [
      jq
      gawk
      coreutils
      gnugrep
      gnused
      findutils
    ];
    text = builtins.readFile ./screenshot-window.sh;
  };

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
  options.modules.desktop.hyprland = {
    enable = lib.mkEnableOption "personal Hyprland configuration";
    effects.enable = lib.mkEnableOption "Hyprland blur, shadows and animations" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ screenshotWindow ];
    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      systemd.enable = false;
      configType = "lua";

      settings.config.input.kb_layout = osConfig.services.xserver.xkb.layout;

      extraLuaFiles = lib.genAttrs luaModules (name: {
        content = ./conf + "/${name}.lua";
        autoLoad = false;
      });

      extraConfig =
        builtins.readFile ./conf/hyprland.lua
        + lib.optionalString (!cfg.effects.enable) ''
          hl.config({
            decoration = { blur = { enabled = false }, shadow = { enabled = false } },
            animations = { enabled = false },
          })
        '';
    };

    home.file.".wayland-session" = {
      executable = true;
      text = ''
        uwsm stop 2>/dev/null || true
        exec uwsm start hyprland-uwsm.desktop
      '';
    };
  };
}
