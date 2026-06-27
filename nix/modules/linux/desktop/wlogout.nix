{ dotLink, ... }:

let
  sym = dotLink "wlogout";
in
{
  xdg.configFile = {
    "wlogout/layout".source    = sym "layout";
    "wlogout/style.css".source = sym "style.css";
    "wlogout/icons".source     = sym "icons";
  };
}
