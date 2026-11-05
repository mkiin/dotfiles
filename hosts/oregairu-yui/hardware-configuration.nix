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
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.networkmanager.enable = true;
}
