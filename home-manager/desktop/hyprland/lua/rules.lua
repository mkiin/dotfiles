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

hl.window_rule({
	name = "hide-wine-explorer-desktop",
	match = { class = "^steam_proton$", title = "^$", xwayland = true },
	workspace = "special silent",
	no_focus = true,
})

-- NIKKE 本体窓(Xwayland)に blur 4pass + shadow + rounding を掛けると
-- nvidia 595.84(Blackwell)が Xid 69 を吐き Hyprland ごと巻き添えで落ちる。
hl.window_rule({
	name = "nikke-no-effects",
	match = { class = "^steam_proton$", title = "^NIKKE$", xwayland = true },
	no_blur = true,
	no_shadow = true,
	rounding = 0,
	no_anim = true,
	opaque = true,
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
