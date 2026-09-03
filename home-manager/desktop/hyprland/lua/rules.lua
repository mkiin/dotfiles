hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

hl.window_rule({
	name = "float-guvcview",
	match = { class = "^guvcview$" },
	float = true,
})

hl.window_rule({
	name = "float-pwvucontrol",
	match = { class = "^com%.saivert%.pwvucontrol$" },
	float = true,
	size = "700 800",
	center = 1,
})

hl.layer_rule({
	name = "logout-blur",
	match = { namespace = "logout_dialog" },
	blur = true,
})

hl.layer_rule({
	name = "logout-dim",
	match = { namespace = "logout_dialog" },
	dim_around = true,
})

hl.layer_rule({
	name = "waybar-glass-blur",
	match = { namespace = "waybar" },
	blur = true,
	ignore_alpha = 0.2,
})

-- PopupCard は全面透明オーバーレイの上にカードを描くため、
-- ignore_alpha でカードの半透明部分だけに blur を乗せる
hl.layer_rule({
	name = "quickshell-glass-blur",
	match = { namespace = "quickshell" },
	blur = true,
	ignore_alpha = 0.2,
})
