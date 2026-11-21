{ config, ... }:
{
  disko.devices.disk.system = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-eui.000000000000000100a075244c33c582";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          device = config.disko.devices.disk.system.device + "-part1";
          priority = 1;
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };
        root = {
          device = config.disko.devices.disk.system.device + "-part2";
          priority = 2;
          size = "940603124K";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
        swap = {
          device = config.disko.devices.disk.system.device + "-part3";
          priority = 3;
          size = "35108800K";
          content.type = "swap";
        };
      };
    };
  };
}
