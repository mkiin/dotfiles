{ pkgs, ... }:
{
  home.packages = with pkgs; [
    limo # mod manager
  ];
}
