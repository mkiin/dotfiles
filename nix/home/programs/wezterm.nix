{ pkgs, config, dotfilesDir, ... }:

{
  home.packages = [ pkgs.wezterm ];

  xdg.configFile."wezterm/wezterm.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/wezterm/wezterm.lua";
}
