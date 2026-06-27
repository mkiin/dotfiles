{ pkgs, dotLink, ... }:

{
  home.packages = [ pkgs.mise ];

  xdg.configFile."mise/config.toml".source = dotLink "mise" "config.toml";
}
