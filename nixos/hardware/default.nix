{ ... }:
{
  imports = [
    ./nvidia.nix
    ./bluetooth.nix
  ];

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
}
