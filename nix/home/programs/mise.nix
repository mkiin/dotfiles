{ pkgs, config, dotfilesDir, ... }:

{
  home.packages = [ pkgs.mise ];

  xdg.configFile."mise/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/mise/config.toml";
}
