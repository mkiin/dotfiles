{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.anime-games-launcher.packages.${pkgs.system}.default
    pkgs.umu-launcher
    pkgs.python3
    pkgs.bubblewrap
  ];
}
