{ pkgs, nixgl, config, dotfilesDir, ... }:

let
  wezterm-wrapped = pkgs.writeShellScriptBin "wezterm" ''
    exec ${nixgl.nixGLNvidia}/bin/nixGLNvidia ${pkgs.wezterm}/bin/wezterm "$@"
  '';
in

{
  home.packages = [ wezterm-wrapped ];

  xdg.configFile."wezterm/wezterm.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/wezterm/wezterm.lua";
}
