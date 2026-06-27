{ config, dotfilesDir, ... }:

let
  sym = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/hypr/monitors/${path}";
in
{
  xdg.configFile = {
    "hypr/monitors/desk.lua".source = sym "desk.lua";
    "hypr/monitors/bed.lua".source  = sym "bed.lua";
  };
}
