{ lnk, ... }:
{
  xdg.configFile = {
    "wlogout/layout".source = lnk ./layout;
    "wlogout/style.css".source = lnk ./style.css;
    "wlogout/icons".source = lnk ./icons;
  };
}
