{ pkgs, ... }:

{
  home.packages = with pkgs; [
    matugen
    wallust
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
