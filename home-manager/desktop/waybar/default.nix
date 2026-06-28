{ lnk, ... }:
{
  xdg.configFile = {
    "waybar/config.jsonc".source = lnk ./config.jsonc;
    "waybar/style.css".source    = lnk ./style.css;
    "waybar/scripts".source      = lnk ./scripts;
    "waybar/styles".source       = lnk ./styles;
  };
}
