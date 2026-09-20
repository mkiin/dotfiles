{
  pkgs,
  config,
  lib,
  ...
}:
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

    home.file.".wayland-session" = {
      executable = true;
      text = ''
        uwsm stop 2>/dev/null || true
        exec uwsm start hyprland-uwsm.desktop
      '';
    };

    systemd.user.services.polkit-agent = {
      Unit = {
        Description = "PolicyKit Authentication Agent";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
