{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    pulseaudio
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  security.rtkit.enable = true;
  # Disable pulseaudio, it conflicts with pipewire too.
  services.pulseaudio.enable = false;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  services = {
    printing.enable = true;
    geoclue2.enable = true;
  };
}
