{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop.hyprland;

  screenshotAppName = pkgs.writeShellApplication {
    name = "screenshot-app-name";
    runtimeInputs = [
      pkgs.gjs
      pkgs.steam-acf
      pkgs.systemd
    ];
    text = ''
      exec gjs -m ${pkgs.writeText "screenshot-app-name.js" ''
        import {resolveAppName} from 'file://${./app-name.js}';
        if (ARGV.length !== 1) throw new Error('Usage: screenshot-app-name <window-json>');
        print(resolveAppName(JSON.parse(ARGV[0])));
      ''} "$@"
    '';
  };

  screenshotWindow = pkgs.writeShellApplication {
    name = "screenshot-window-by-app";
    runtimeInputs = [
      pkgs.nushell
      osConfig.programs.hyprland.package
      config.programs.noctalia.package
      screenshotAppName
    ];
    text = ''
      exec nu --no-config-file ${./screenshot-window.nu} "$@"
    '';
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
    home.packages = [
      screenshotWindow
      screenshotAppName
    ];

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
