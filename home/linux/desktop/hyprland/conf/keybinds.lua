local vars = require("vars")

local mod = vars.mainMod
local terminal = vars.terminal
local fileManager = vars.fileManager
local browser = vars.browser

local bind = hl.bind
local exec = hl.dsp.exec_cmd

local function modkey(keys)
	return mod .. " + " .. keys
end

local function run(keys, command, opts)
	bind(keys, exec(command), opts)
end

-- Applications / UI

run(modkey("G"), terminal)
run(modkey("E"), fileManager)
run(modkey("B"), browser)
run(modkey("D"), "vesktop")

run(modkey("A"), "noctalia msg panel-toggle launcher")
run(modkey("N"), "noctalia msg panel-toggle control-center notifications")
run(modkey("Q"), "noctalia msg panel-toggle session")

-- Wallpaper

run(modkey("W"), "noctalia msg wallpaper-next")
run(modkey("SHIFT + W"), "noctalia msg panel-toggle wallpaper")

-- Capture

run(modkey("P"), "screenshot-menu")
run(modkey("R"), "record-menu")

-- Window

bind(modkey("C"), hl.dsp.window.close())
bind(modkey("V"), hl.dsp.window.float({ action = "toggle" }))
bind(modkey("F"), hl.dsp.window.fullscreen())
bind(modkey("T"), hl.dsp.layout("togglesplit"))

-- Focus / Move / Resize

local directions = {
	H = "l",
	J = "d",
	K = "u",
	L = "r",
}

local resize = {
	l = { x = -30, y = 0 },
	d = { x = 0, y = 30 },
	u = { x = 0, y = -30 },
	r = { x = 30, y = 0 },
}

for key, direction in pairs(directions) do
	bind(
		modkey(key),
		hl.dsp.focus({
			direction = direction,
		})
	)

	bind(
		modkey("SHIFT + " .. key),
		hl.dsp.window.move({
			direction = direction,
		})
	)

	bind(
		modkey("CTRL + " .. key),
		hl.dsp.window.resize({
			x = resize[direction].x,
			y = resize[direction].y,
			relative = true,
		}),
		{ repeating = true }
	)
end

local arrowDirections = {
	left = "l",
	down = "d",
	up = "u",
	right = "r",
}

for key, direction in pairs(arrowDirections) do
	bind(
		modkey(key),
		hl.dsp.focus({
			direction = direction,
		})
	)
end

-- Workspace

bind(
	modkey("I"),
	hl.dsp.focus({
		workspace = "m-1",
	})
)

bind(
	modkey("O"),
	hl.dsp.focus({
		workspace = "m+1",
	})
)

bind(
	modkey("SHIFT + I"),
	hl.dsp.window.move({
		workspace = "m-1",
		follow = false,
	})
)

bind(
	modkey("SHIFT + O"),
	hl.dsp.window.move({
		workspace = "m+1",
		follow = false,
	})
)

for workspace = 1, 10 do
	local key = workspace == 10 and "0" or tostring(workspace)

	bind(
		modkey(key),
		hl.dsp.focus({
			workspace = workspace,
		})
	)

	bind(
		modkey("SHIFT + " .. key),
		hl.dsp.window.move({
			workspace = workspace,
		})
	)
end

-- Special workspace / Pyprland

bind(modkey("S"), hl.dsp.workspace.toggle_special("stash"))

run(modkey("SHIFT + S"), "pypr toggle_special stash")
run(modkey("SHIFT + M"), "pypr lost_windows")
run(modkey("SHIFT + F"), "pypr toggle fetch")

-- Dock Winddow

run(modkey("SHIFT + D"), "noctalia msg dock-toggle")

-- Mouse

bind(
	modkey("mouse_down"),
	hl.dsp.focus({
		workspace = "m+1",
	})
)

bind(
	modkey("mouse_up"),
	hl.dsp.focus({
		workspace = "m-1",
	})
)

bind(modkey("mouse:272"), hl.dsp.window.drag(), { mouse = true })
bind(modkey("mouse:273"), hl.dsp.window.resize(), { mouse = true })
