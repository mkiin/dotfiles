local vars = require("vars")

local mod = vars.mainMod
local terminal = vars.terminal
local fileManager = vars.fileManager
local browser = vars.browser

-- Applications / UI

hl.bind(mod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("vesktop"))

-- Wallpaper

hl.bind(mod .. " + W", hl.dsp.exec_cmd("noctalia msg wallpaper-next"))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"))

-- Capture

hl.bind(mod .. " + Z", hl.dsp.exec_cmd("noctalia msg screenshot-region"))
hl.bind(mod .. " + SHIFT + Z", hl.dsp.exec_cmd("noctalia msg screenshot-window"))

-- Window

hl.bind(mod .. " + C", hl.dsp.window.close())
hl.bind(mod .. " + V", function()
	local window = hl.get_active_window()
	if not window then
		return
	end

	local was_floating = window.floating
	local monitor = hl.get_active_monitor()
	hl.dispatch(hl.dsp.window.float({ action = "toggle", window = window }))

	if not was_floating and monitor then
		hl.dispatch(hl.dsp.window.resize({
			x = math.floor(monitor.width * 0.8),
			y = math.floor(monitor.height * 0.8),
			relative = false,
			window = window,
		}))
		-- hl.dispatch(hl.dsp.window.center({ window = window }))
		-- hl.dispatch(hl.dsp.window.move({
		-- 	x = window.at.x,
		-- 	y = monitor.y + monitor.reserved.top + 12,
		-- 	relative = false,
		-- 	window = window,
		-- }))
	end
end)
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())

-- Noctalia
hl.bind(mod .. " + A", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
hl.bind(mod .. " + S", hl.dsp.exec_cmd("noctalia msg settings-toggle"))
hl.bind(mod .. " + Q", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd("noctalia msg window-switcher"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("noctalia msg dock-toggle"))

-- Focus

hl.bind(mod .. " + H", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + L", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mod .. " + U", hl.dsp.focus({ monitor = "l" }))
hl.bind(mod .. " + I", hl.dsp.focus({ monitor = "r" }))
hl.bind(mod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }))

-- Move

hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + SHIFT + U", hl.dsp.window.move({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + I", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Resize

hl.bind(mod .. " + minus", function()
	local monitor = hl.get_active_monitor()
	if monitor then
		hl.dispatch(hl.dsp.window.resize({ x = math.floor(monitor.width * -0.1), y = 0, relative = true }))
	end
end, { repeating = true })

hl.bind(mod .. " + equal", function()
	local monitor = hl.get_active_monitor()
	if monitor then
		hl.dispatch(hl.dsp.window.resize({ x = math.floor(monitor.width * 0.1), y = 0, relative = true }))
	end
end, { repeating = true })

hl.bind(mod .. " + SHIFT + minus", function()
	local monitor = hl.get_active_monitor()
	if monitor then
		hl.dispatch(hl.dsp.window.resize({ x = 0, y = math.floor(monitor.height * -0.1), relative = true }))
	end
end, { repeating = true })

hl.bind(mod .. " + SHIFT + equal", function()
	local monitor = hl.get_active_monitor()
	if monitor then
		hl.dispatch(hl.dsp.window.resize({ x = 0, y = math.floor(monitor.height * 0.1), relative = true }))
	end
end, { repeating = true })

-- Mouse

hl.bind(
	mod .. " + mouse_down",
	hl.dsp.focus({
		workspace = "m+1",
	})
)

hl.bind(
	mod .. " + mouse_up",
	hl.dsp.focus({
		workspace = "m-1",
	})
)

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- IME
hl.bind("Escape", hl.dsp.exec_cmd("fcitx5-remote -c"), { non_consuming = true })
