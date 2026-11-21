{ pkgs, ... }:
{
  home.packages = with pkgs; [
    loupe
    playerctl
    showtime
  ];
}
