{ config, dotfilesDir, ... }:

let
  sym = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/quickshell/${path}";
in
{
  xdg.configFile = {
    "quickshell/shell.json".source  = sym "shell.json";
    "quickshell/shell".source       = sym "shell";
    "quickshell/audio".source       = sym "audio";
    "quickshell/bluetooth".source   = sym "bluetooth";
  };
}
