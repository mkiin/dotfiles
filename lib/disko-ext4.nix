# Keep the existing ESP/root/swap order. Sizes are supplied by each host.
{
  device,
  rootSize,
  swapSize,
}:
{
  disko.devices.disk.system = {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
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
          priority = 2;
          size = rootSize;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
        swap = {
          priority = 3;
          size = swapSize;
          content.type = "swap";
        };
      };
    };
  };
}
