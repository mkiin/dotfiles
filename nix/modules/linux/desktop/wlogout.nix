{ config, dotfilesDir, ... }:

let
  sym = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/wlogout/${path}";
in
{
  xdg.configFile = {
    "wlogout/layout".source    = sym "layout";
    "wlogout/style.css".source = sym "style.css";
    "wlogout/icons".source     = sym "icons";
  };
}
