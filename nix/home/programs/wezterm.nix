{ pkgs, config, dotfilesDir, ... }:

let
  wezterm-wrapped = pkgs.writeShellScriptBin "wezterm" ''
    export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
    export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
    export WGPU_BACKEND=vulkan
    exec ${pkgs.wezterm}/bin/wezterm "$@"
  '';
in

{
  home.packages = [ wezterm-wrapped ];

  xdg.configFile."wezterm/wezterm.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/wezterm/wezterm.lua";
}
