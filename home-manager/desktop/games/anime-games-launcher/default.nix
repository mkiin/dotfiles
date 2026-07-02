{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.anime-games-launcher.packages.${pkgs.system}.default
  ];
}
