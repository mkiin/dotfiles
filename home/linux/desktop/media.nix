{ pkgs, ... }:
{
  programs.mpv.enable = true;
  programs.imv.enable = true;

  home.packages = with pkgs; [
    audacity
    playerctl
    pwvucontrol
  ];
}
