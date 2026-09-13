{ lnk, ... }:
{
  xdg.configFile = {
    "mouse/g703h.sh".source = lnk ./g703h.sh;
    "mouse/m575-profiled.py".source = lnk ./m575-profiled.py;
    "mouse/profiles.toml".source = lnk ./profiles.toml;
  };
}
