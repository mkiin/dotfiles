{ config, lib, ... }:
{
  options.modules.desktop.nvidia.enable = lib.mkEnableOption "NVIDIA video acceleration environment";

  config = lib.mkIf config.modules.desktop.nvidia.enable {
    home.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
    };
  };
}
