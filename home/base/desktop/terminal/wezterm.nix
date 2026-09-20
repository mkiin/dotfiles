{ pkgs, ... }:

{
  programs.wezterm = {
    enable = true;
    package = pkgs.wezterm;
  };

  xdg.configFile."wezterm/wezterm.lua" = {
    source = ./wezterm.lua;
  };
}
