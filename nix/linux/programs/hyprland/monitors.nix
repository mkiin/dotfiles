{ ... }:

{
  xdg.configFile = {
    "hypr/monitors/desk.conf".text = ''
      monitor = DP-3,     1920x1080@60,   0x0,    1
      monitor = DP-2,     2560x1440@180, 1920x0,  1
      monitor = DP-1,     1920x1080@100, 4480x0,  1
      monitor = HDMI-A-1, disable

      workspace = 1, monitor:DP-3, default:true, persistent:true
      workspace = 2, monitor:DP-2, default:true, persistent:true
      workspace = 3, monitor:DP-1, default:true, persistent:true
    '';
    "hypr/monitors/bed.conf".text = ''
      monitor = HDMI-A-1, 1920x1080@144, 0x0, 1
      monitor = DP-3,     disable
      monitor = DP-2,     disable
      monitor = DP-1,     disable

      workspace = 1,  monitor:HDMI-A-1, default:true, persistent:true
      workspace = 2,  monitor:HDMI-A-1
      workspace = 3,  monitor:HDMI-A-1
      workspace = 4,  monitor:HDMI-A-1
      workspace = 5,  monitor:HDMI-A-1
      workspace = 6,  monitor:HDMI-A-1
      workspace = 7,  monitor:HDMI-A-1
      workspace = 8,  monitor:HDMI-A-1
      workspace = 9,  monitor:HDMI-A-1
      workspace = 10, monitor:HDMI-A-1
    '';
  };
}
