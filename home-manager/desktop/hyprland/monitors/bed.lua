hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-3",  disabled = true })
hl.monitor({ output = "DP-2",  disabled = true })
hl.monitor({ output = "DP-1",  disabled = true })

for i = 1, 10 do
  hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1", default = i == 1, persistent = i == 1 })
end
