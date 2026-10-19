{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./kanshi.nix
    ../../base
    ../../base/desktop/terminal/ghostty.nix
    ../../base/desktop/terminal/kitty.nix
    ../../linux/terminal
    ../../linux/desktop/gtk.nix
    ../../linux/desktop/niri
    ../../linux/desktop/kanshi
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

  modules.desktop.noctalia.idle = {
    lockTimeout = 900;
    screenOffTimeout = 1800;
    suspendTimeout = 3600;
  };

  modules.desktop.niri.enable = true;
  modules.desktop.nvidia.enable = false;
  modules.desktop.pyprland.enable = false;

  home.packages = with pkgs; [
    brightnessctl
    playerctl
  ];
}
