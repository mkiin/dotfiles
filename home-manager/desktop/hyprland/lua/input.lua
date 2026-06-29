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
		no_warps = false,
		sync_gsettings_theme = false,
		enable_hyprcursor = true,
	},
})
