{ lnk, ... }:

{
  xdg.configFile."mise/config.toml".source = lnk ./config.toml;
}
