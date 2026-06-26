{ config, dotfilesDir, ... }:

let
  sym = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/wallust/${path}";
in
{
  xdg.configFile = {
    "wallust/wallust.toml".source             = sym "wallust.toml";
    "wallust/templates/waybar.css".source     = sym "templates/waybar.css";
    "wallust/templates/ghostty.conf".source   = sym "templates/ghostty.conf";
    "wallust/templates/wezterm.toml".source   = sym "templates/wezterm.toml";
    "wallust/templates/pywal-colors.json".source = sym "templates/pywal-colors.json";
  };
}
