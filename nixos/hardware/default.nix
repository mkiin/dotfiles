{ ... }:
{
  imports = [
    ./nvidia
    ./bluetooth
    ./sleep
  ];

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
}
