{ pkgs, ... }:

{
  programs.wezterm = {
    enable = true;

    package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.wezterm;
  };

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
}
