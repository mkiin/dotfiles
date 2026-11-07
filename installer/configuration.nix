{
  pkgs,
  lib,
  myvars,
  inputs,
  ...
}:
let
  initialHashedPassword = lib.removeSuffix "\n" (builtins.readFile ./initial-password-hash);
in
{
  assertions = [
    {
      assertion = lib.hasPrefix "$y$" initialHashedPassword || lib.hasPrefix "$6$" initialHashedPassword;
      message = "Set installer/initial-password-hash with mkpasswd.";
    }
  ];

  users.users.${myvars.username} = {
    uid = 1000;
    inherit initialHashedPassword;
  };
  networking.networkmanager.enable = true;
  hardware.enableRedistributableFirmware = true;
  services.openssh = {
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [
    "root"
    myvars.username
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
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    git
    age
    vim
  ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "26.05";
}
