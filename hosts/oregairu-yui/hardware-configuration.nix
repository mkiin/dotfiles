# Hardware configuration for Yui.
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.cleanOnBoot = true;

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "sdhci_pci"
  ];
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/b63cb892-1929-493c-be6d-d5df12260bd0";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A762-06A8";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/d1343163-cd7e-4b32-8011-7f88a6d2390a"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.networkmanager.enable = true;
}
