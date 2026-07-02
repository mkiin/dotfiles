local xdg = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
package.path = xdg .. "/hypr/?.lua;" .. xdg .. "/hypr/?/init.lua;" .. package.path

require("plugins")
require("env")
require("color-scheme")
require("appearance")
require("input")
require("keybinds")
require("rules")
pcall(require, "monitors.desk")
