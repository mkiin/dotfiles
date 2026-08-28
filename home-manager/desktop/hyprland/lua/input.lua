hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.config({
	input = {
		kb_layout = "us",
		kb_options = "caps:none",
		repeat_rate = 40,
		repeat_delay = 250,
		follow_mouse = 1,
		accel_profile = "flat",
		sensitivity = 1.0,
		scroll_factor = 2,
		touchpad = { natural_scroll = false },
	},
	cursor = {
		-- movewindow(SHIFT+H/J/K/L)等でカーソルがウィンドウに吸い付くワープを止める
		no_warps = true,
		-- ただし WS 切替でフォーカスが別モニターへ移るときだけはカーソルも運ぶ。
		-- 置き去りにすると follow_mouse = 1 が効いて、マウスが少し動いた瞬間に
		-- 元のモニターへフォーカスが引き戻される。2 = no_warps を上書きして強制。
		warp_on_change_workspace = 2,
		sync_gsettings_theme = false,
		enable_hyprcursor = true,
	},
})
