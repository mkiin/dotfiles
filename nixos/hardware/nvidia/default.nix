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
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
