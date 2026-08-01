{ config, ... }:
{
  # モニタは dGPU(nvidia) 接続。未使用の Ryzen iGPU を無効化し、
  # コンポジタが出力の無い iGPU を掴んで "Could not enable any output" になるのを防ぐ。
  boot.blacklistedKernelModules = [ "amdgpu" ];

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    # production(595.84) は Blackwell + open module で Xid 31 MMU Fault を起こし
    # Hyprland を道連れに落とす既知バグを踏むため、new feature branch(610) を使う。
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    powerManagement.enable = true;
  };
}
