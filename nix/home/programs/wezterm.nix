{ pkgs, config, dotfilesDir, ... }:

let
  wezterm-wrapped = pkgs.writeShellScriptBin "wezterm" ''
    export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
    exec ${pkgs.wezterm}/bin/wezterm "$@"
  '';
in

{
  home.packages = [ wezterm-wrapped ];

  xdg.configFile."wezterm/wezterm.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/wezterm/wezterm.lua";
}
