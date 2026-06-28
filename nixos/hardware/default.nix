{ ... }:
{
  imports = [
    ./nvidia
    ./bluetooth
  ];

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
}
