{ lnk, ... }:
{
  xdg.configFile."fastfetch/config.jsonc".source = lnk ./config.jsonc;
}
