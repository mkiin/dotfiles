hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "2560x1440@180", position = "1920x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080@100", position = "4480x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", disabled = true })

-- 起動時の初期配置: 中央DP-2(メイン)=WS1 / 左DP-1=WS2 / 右DP-3=WS3。
-- persistent は付けない(空WSは消え follow_focus の追従対象に戻す)。
hl.workspace_rule({ workspace = "1", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-3", default = true })
