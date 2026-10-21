{ ... }:
{
  imports = [
    ./core.nix
    ../base/cli
    ../base/gui/terminal
    ../base/gui/zed
    ../base/gui/gtk.nix
    ../base/gui/niri
    ../base/gui/kanshi
    ../base/gui/wayland.nix
    ../base/gui/clipboard.nix
    ../base/gui/fcitx5.nix
    ../base/gui/hypridle.nix
    ../base/gui/pyprland.nix
    ../base/gui/desktop-apps/nautilus.nix
    ../base/gui/desktop-apps/vesktop.nix
    ../base/gui/desktop-apps/zen-browser
    ../base/gui/desktop-apps/obsidian.nix
    ../base/gui/noctalia
    ../base/gui/xdg
  ];
}
