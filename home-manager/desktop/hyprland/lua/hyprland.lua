local xdg = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
package.path = xdg .. "/hypr/?.lua;" .. xdg .. "/hypr/?/init.lua;" .. package.path

require("color-scheme")
require("appearance")
require("input")
require("autostart")
require("keybinds")
require("rules")
pcall(require, "monitors")
