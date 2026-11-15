{ lib, ... }:
{
  # Start with device autodetection; select disks per host when needed.
  services.smartd.enable = lib.mkDefault true;
}
