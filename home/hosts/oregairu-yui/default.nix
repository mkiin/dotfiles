{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../../base
    ../../base/desktop/terminal/ghostty.nix
    ../../base/desktop/terminal/kitty.nix
    ../../linux/terminal
    ../../linux/desktop/gtk.nix
    ../../linux/desktop/hyprland
    ../../linux/desktop/desktop-tools
    ../../linux/desktop/desktop-apps/nautilus.nix
    ../../linux/desktop/desktop-apps/vesktop.nix
    ../../linux/desktop/desktop-apps/zen-browser
    ../../linux/desktop/desktop-apps/obsidian.nix
    ../../linux/desktop/noctalia
    ../../linux/desktop/xdg
    ../../linux/laptop/noctalia.nix
  ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."github.com" = {
      IdentityFile = "${config.home.homeDirectory}/.ssh/oregairu-yui";
      IdentitiesOnly = true;
    };
  };
  programs.git.signing.key = "${config.home.homeDirectory}/.ssh/oregairu-yui.pub";

  modules.desktop.hyprland.enable = true;
  modules.desktop.nvidia.enable = false;
  modules.desktop.pyprland.enable = false;

  modules.desktop.hypridle = {
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

  home.packages = with pkgs; [
    brightnessctl
    playerctl
  ];
}
