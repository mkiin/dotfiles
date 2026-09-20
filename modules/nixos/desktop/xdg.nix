{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg = {
    autostart.enable = lib.mkDefault true;
    menus.enable = lib.mkDefault true;
    mime.enable = lib.mkDefault true;
    icons.enable = lib.mkDefault true;
  };

  xdg.terminal-exec = {
    enable = true;
    package = pkgs.xdg-terminal-exec;
    settings.default = [
      "com.mitchellh.ghostty.desktop"
      "org.wezfurlong.wezterm.desktop"
    ];
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;

    config = {
      common.default = [ "gtk" ];

      hyprland = lib.mkIf config.programs.hyprland.enable {
        default = [
          "hyprland"
          "gtk"
        ];
      };
    };

    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
