{ ... }:

{
  xdg.configFile = {
    "hypr/monitors/desk.lua".text = ''
      hl.monitor({ output = "DP-3",     mode = "1920x1080@60",   position = "0x0",    scale = 1 })
      hl.monitor({ output = "DP-2",     mode = "2560x1440@180",  position = "1920x0", scale = 1 })
      hl.monitor({ output = "DP-1",     mode = "1920x1080@100",  position = "4480x0", scale = 1 })
      hl.monitor({ output = "HDMI-A-1", disabled = true })

      hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true, persistent = true })
      hl.workspace_rule({ workspace = "2", monitor = "DP-2", default = true, persistent = true })
      hl.workspace_rule({ workspace = "3", monitor = "DP-1", default = true, persistent = true })
    '';
    "hypr/monitors/bed.lua".text = ''
      hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
      hl.monitor({ output = "DP-3",  disabled = true })
      hl.monitor({ output = "DP-2",  disabled = true })
      hl.monitor({ output = "DP-1",  disabled = true })

      for i = 1, 10 do
        hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1", default = i == 1, persistent = i == 1 })
      end
    '';
  };
}
