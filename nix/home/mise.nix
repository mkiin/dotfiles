{ pkgs, ... }:

{
  home.packages = [ pkgs.mise ];

  xdg.configFile."mise/config.toml".source = ../../mise/config.toml;
}
