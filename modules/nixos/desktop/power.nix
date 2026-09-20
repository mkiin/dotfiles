{ ... }:
{
  services.tuned = {
    enable = true;
    settings.dynamic_tuning = true;
    ppdSupport = true; # translation of power-profiles-daemon API calls to TuneD
    ppdSettings.main.default = "balanced"; # balanced / performance / power-saver
  };

  services.upower.enable = true;

  services.power-profiles-daemon.enable = false;
  services.tlp.enable = false;
}
