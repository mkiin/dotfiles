{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    pulseaudio
    file-roller
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
  services.gvfs.enable = true; # ゴミ箱機能、USBマウント、ネットワーク共有
  services.tumbler.enable = true; # 画像・動画のサムネイル生成

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  services = {
    printing.enable = true;
    geoclue2.enable = true;

    # https://github.com/rvaiya/keyd
    keyd = {
      enable = true;
      keyboards.default.settings = {
        main = {
          # overloads the capslock key to function as both escape (when tapped) and control (when held)
          capslock = "overload(control, esc)";
          esc = "capslock";
        };
      };
    };
  };

}
