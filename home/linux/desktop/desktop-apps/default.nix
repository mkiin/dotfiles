{ pkgs, mylib, ... }:
{
  imports = mylib.scanPaths ./.;
  home.packages = with pkgs; [
    limo # mod manager
  ];

}
