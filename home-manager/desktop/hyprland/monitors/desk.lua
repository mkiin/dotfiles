hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "2560x1440@180", position = "1920x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080@100", position = "4480x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", disabled = true })

-- WS はグローバルプール。monitor= の workspace_rule は書かない。WS は最初に開いた
-- モニターに生まれてそこに居続けるので、所属は使ううちに自然に決まる (i3/sway 方式)。
