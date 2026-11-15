{ lib, ... }:
{
  boot.loader.systemd-boot = {
    # Keep boot files bounded while retaining rollback choices.
    configurationLimit = lib.mkDefault 5;
    # pick the highest resolution for systemd-boot's console.
    consoleMode = lib.mkDefault "max";
  };

  boot.loader.timeout = lib.mkDefault 3; # wait for x seconds to select the boot entry
}
