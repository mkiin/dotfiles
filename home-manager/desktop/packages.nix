{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # color / wallpaper pipeline
    matugen wallust awww
    # desktop utilities
    wlogout cliphist socat resvg mpv pwvucontrol cava waybar playerctl
    # fonts & themes
    nerd-fonts.jetbrains-mono inter papirus-icon-theme
    # terminals
    wezterm
    # session essentials (lock, screenshot, clipboard, media keys)
    hyprlock hyprshot wl-clipboard brightnessctl pamixer hypridle
    # script dependencies (screenshot.sh, record.sh)
    jq libnotify
  ];
}
