hl.config({
	general = {
		gaps_in = 3,
		gaps_out = 8,
		border_size = 1,
		layout = "dwindle",
		resize_on_border = true,
		allow_tearing = false,
	},
	decoration = {
		rounding = 14,
		active_opacity = 0.93,
		inactive_opacity = 0.92,
		fullscreen_opacity = 1.0,
		shadow = {
			enabled = true,
			range = 15,
			render_power = 5,
			offset = "0 0",
		},
		blur = {
			enabled = true,
			size = 1,
			passes = 4,
			contrast = 1.1,
			brightness = 1.1,
			vibrancy = 0.2,
			vibrancy_darkness = 0.2,
			noise = 0.03,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
		},
	},
	animations = { enabled = true },
	dwindle = { preserve_split = true },
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
})

hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.1, 1 }, { 0.1, 1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 6, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "once" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" })
