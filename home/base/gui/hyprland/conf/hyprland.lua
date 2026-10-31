-- require("color-scheme")
require("appearance")
require("input")
require("keybinds")
require("rules")
require("monitors")

if package.searchpath("noctalia", package.path) then
	require("noctalia").apply_theme()
end

hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm app -- noctalia")
end)
