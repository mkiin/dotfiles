{ ... }:
{
  imports = [
    ./nvidia
    ./bluetooth
    ./sleep
    ./asrock-led
  ];

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
}
