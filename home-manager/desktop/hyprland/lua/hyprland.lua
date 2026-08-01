local xdg = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
package.path = xdg .. "/hypr/?.lua;" .. xdg .. "/hypr/?/init.lua;" .. package.path

require("env")
require("color-scheme")
require("appearance")
require("input")
require("keybinds")
require("rules")
-- monitors.lua は mode.sh が書き出す可変ファイル(未生成の環境では desk へ倒す)。
if not pcall(require, "monitors") then
	pcall(require, "monitors.desk")
end
