local mod = require("vars").mainMod

hl.bind(mod .. " + X", hl.dsp.exec_cmd("noctalia msg plugin noctalia/screen_recorder:service all toggle"))
hl.bind(mod .. " + R", hl.dsp.exec_cmd("noctalia msg plugin noctalia/screen_recorder:service all replay-toggle"))
hl.bind(mod .. " + G", hl.dsp.exec_cmd("noctalia msg plugin noctalia/screen_recorder:service all replay-save"))
