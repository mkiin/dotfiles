{ pkgs, lnk, ... }:

{
  home.packages = [ pkgs.mise ];

  xdg.configFile."mise/config.toml".source = lnk ./config.toml;
}
