{ pkgs, ... }:

{
  home.packages = with pkgs; [
    matugen
    wallust
    # hypr ecosystem
    hypridle
    hyprlock
    hyprpolkitagent
    hyprshot
    hyprshutdown
    # desktop utilities
    wlogout
    cliphist
    socat
    resvg
    mpv
    pwvucontrol
    awww
    cava
    waybar
    playerctl
    # fonts & themes
    nerd-fonts.jetbrains-mono
    inter
    papirus-icon-theme
  ];
}
