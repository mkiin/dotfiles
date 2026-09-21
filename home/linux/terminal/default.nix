{ myvars, mylib, ... }:
{
  imports = mylib.scanPaths ./.;

  home.homeDirectory = "/home/${myvars.username}";
}
