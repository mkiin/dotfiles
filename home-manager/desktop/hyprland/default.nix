{
  inputs,
  pkgs,
  lnk,
  ...
}:
{
  imports = [ ./monitor.nix ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = null;
    xwayland.enable = true;
    systemd.enable = false;
    configType = "lua";
  };

  xdg.configFile = {
    "hypr/hyprland.lua".source = lnk ./lua/hyprland.lua;
    "hypr/vars.lua".source = lnk ./lua/vars.lua;
    "hypr/color-scheme.lua".source = lnk ./lua/color-scheme.lua;
    "hypr/appearance.lua".source = lnk ./lua/appearance.lua;
    "hypr/env.lua".source = lnk ./lua/env.lua;
    "hypr/input.lua".source = lnk ./lua/input.lua;
    "hypr/keybinds.lua".source = lnk ./lua/keybinds.lua;
    "hypr/rules.lua".source = lnk ./lua/rules.lua;
    "hypr/scripts".source = lnk ./scripts;
    "hypr/hyprlock.conf".source = lnk ./hyprlock.conf;
    "hypr/lock-colors.conf".source = lnk ./lock-colors.conf;
    "hypr/lock.jpg".source = lnk ../../../images/lock/lock.jpg;
    "hypr/lock-scrim.png".source = lnk ../../../images/lock/lock-scrim.png;
  };
}
