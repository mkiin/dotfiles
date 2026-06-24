{ pkgs, config, dotfilesDir, ... }:

{
  home.packages = [ pkgs.git ];

  home.file.".gitconfig".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/git/config";
}
