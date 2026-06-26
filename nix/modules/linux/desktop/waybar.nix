{ config, dotfilesDir, ... }:

let
  sym = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/waybar/${path}";
in
{
  xdg.configFile = {
    "waybar/config.jsonc".source = sym "config.jsonc";
    "waybar/style.css".source    = sym "style.css";
    "waybar/scripts".source      = sym "scripts";
    "waybar/styles".source       = sym "styles";
  };
}
