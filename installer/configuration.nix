{ pkgs, lib, ... }:
{
  imports = [
    ./modules/user.nix
    ./modules/network.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [
    "root"
    "mkiin"
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
  ];
  environment.systemPackages = with pkgs; [
    git
    age
    vim
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";
}
