{ lnk, ... }:
{
  xdg.configFile = {
    "hypr/monitors/desk.lua".source = lnk ./monitors/desk.lua;
    "hypr/monitors/bed.lua".source  = lnk ./monitors/bed.lua;
  };
}
