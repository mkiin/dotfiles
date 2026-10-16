hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "nautilus-floating",
	match = { class = "^org\\.gnome\\.Nautilus$" },
	float = true,
	size = { "monitor_w * 0.4", "monitor_h * 0.4" },
	center = true,
})

hl.window_rule({
	name = "imv-floating",
	match = { class = "^imv$" },
	float = true,
	size = { 800, 600 },
	center = true,
})

hl.window_rule({
	name = "mpv-floating",
	match = { class = "^mpv$" },
	float = true,
	size = { 800, 600 },
	center = true,
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

hl.layer_rule({
	name = "logout-dialog",
	match = { namespace = "logout_dialog" },
	blur = true,
	dim_around = true,
})

hl.layer_rule({
	name = "noctalia",
	match = {
		namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
	},
	no_anim = true,
	ignore_alpha = 0.5,
	blur = true,
	blur_popups = true,
})

hl.window_rule({
	match = { class = "dev.noctalia.Noctalia" },
	float = true,
	size = { 1080, 920 },
})
