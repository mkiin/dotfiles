{ dotLink, ... }:

let
  sym = dotLink "waybar";
in
{
  xdg.configFile = {
    "waybar/config.jsonc".source = sym "config.jsonc";
    "waybar/style.css".source    = sym "style.css";
    "waybar/scripts".source      = sym "scripts";
    "waybar/styles".source       = sym "styles";
  };
}
