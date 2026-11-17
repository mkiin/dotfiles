{
  lib,
  myvars,
  pkgs,
  ...
}:
#############################################################
#
#  Yukino - my main computer, with NixOS + Ryzen7 7800x3D + RTX 5070ti GPU, for gaming & daily use.
#
#############################################################
{
  networking.hostName = "oregairu-yukino";
  networking.networkmanager.enable = true;
  networking.networkmanager.connectionConfig."ethernet.wake-on-lan" = 64;

  services.greetd.settings.initial_session = {
    user = myvars.username;
    command = "${pkgs.uwsm}/bin/uwsm start -e -D Hyprland hyprland.desktop";
  };

  modules.desktop.sunshine.enable = true;

  imports = [
    ./hardware-configuration.nix
    ./hardware-amd.nix
    ./hardware-nvidia.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.cleanOnBoot = true;

  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"
  ];

  _module.args.hostVars.primaryOutput = "DP-2";

  modules.zswap.enable = true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  services.tuned.ppdSettings.main.default = "performance";

  networking.firewall.allowedTCPPorts = [ 5173 ];
  networking.firewall.extraCommands = ''
    for ip in 89.127.233.127 89.126.250.172; do
      iptables -w -C OUTPUT -d "$ip" -j DROP 2>/dev/null || iptables -w -I OUTPUT -d "$ip" -j DROP
    done
  '';
  networking.firewall.extraStopCommands = ''
    for ip in 89.127.233.127 89.126.250.172; do
      iptables -w -D OUTPUT -d "$ip" -j DROP 2>/dev/null || true
    done
  '';

  # This machine resumes reliably through modern standby, while S3/deep is
  # intermittent. Keep the sleep-mode choice local to this host.
  boot.kernelParams = [
    "pm_async=off"
    "mem_sleep_default=s2idle"
  ];

  system.stateVersion = "26.05";
}
