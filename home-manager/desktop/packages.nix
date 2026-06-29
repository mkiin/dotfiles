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
    # terminals
    wezterm
    # session essentials (lock, screenshot, clipboard, media keys)
    hyprlock
    wl-clipboard
    brightnessctl
    pamixer
    # script dependencies (screenshot.sh, record.sh)
    grim
    slurp
    jq
    libnotify
  ];
}
