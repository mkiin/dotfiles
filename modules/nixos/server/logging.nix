{ lib, ... }:
{
  services.journald.settings.Journal = {
    Storage = lib.mkDefault "persistent";
    # Initial limits; adjust to actual log volume after services are deployed.
    SystemMaxUse = lib.mkDefault "512M";
    MaxRetentionSec = lib.mkDefault "14day";
  };
}
