hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "2560x1440@180", position = "1920x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080@100", position = "4480x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", disabled = true })

-- WS はどのモニターにも属さない共有プール。monitor= の workspace_rule は書かない
-- (番号ごとに表示先が固定され、窓を送るとフォーカスが別画面へ飛ぶため)。
-- 実際の引き寄せは scripts/workspace.sh と pyprland workspaces_follow_focus が担う。
