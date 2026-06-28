{ pkgs, ... }:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  systemd.services.bt-agent = {
    description = "Bluetooth auto-pairing agent (NoInputNoOutput)";
    after = [ "bluetooth.target" ];
    requires = [ "bluetooth.target" ];
    wantedBy = [ "bluetooth.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bluez-tools}/bin/bt-agent --capability=NoInputNoOutput";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
