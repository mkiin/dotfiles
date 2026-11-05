{
  disko.devices.disk.system = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-eui.044a50126133cc87";
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
          size = "239780964K";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
        swap = {
          priority = 3;
          size = "9227472K";
          content.type = "swap";
        };
      };
    };
  };
}
