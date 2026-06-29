{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # color / wallpaper pipeline
    matugen
    wallust
    awww
    # desktop utilities (waybar=programs.waybar, cliphist/hypridle=services)
    wlogout
    socat
    resvg
    mpv
    pwvucontrol
    cava
    playerctl
    # shell / panel (qs + quickshell on PATH for keybinds and matugen post_hook)
    quickshell
    # icon theme (fonts are managed system-wide in nixos/core/fonts)
    papirus-icon-theme
    # terminals
    wezterm
    # session essentials (lock, screenshot, clipboard, media keys)
    hyprlock
    hyprshot
    wl-clipboard
    brightnessctl
    pamixer
    # script dependencies (screenshot.sh, record.sh)
    jq
    libnotify
  ];
}
