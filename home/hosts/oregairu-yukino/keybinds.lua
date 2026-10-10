local mod = require("vars").mainMod
local ipc = "noctalia msg "

local function run(keys, command)
	hl.bind(mod .. " + " .. keys, hl.dsp.exec_cmd(command))
end

run("X", ipc .. "plugin noctalia/screen_recorder:service all toggle")
run("R", ipc .. "plugin noctalia/screen_recorder:service all replay-toggle")
run("T", ipc .. "plugin noctalia/screen_recorder:service all replay-save")

run("SHIFT + N", "pypr toggle_special stash")
run("SHIFT + M", "pypr lost_windows")
run("SHIFT + F", "pypr toggle fetch")
run("SHIFT + B", "pypr toggle btop")
