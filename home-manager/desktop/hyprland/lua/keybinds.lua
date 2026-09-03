local vars = require("vars")
local mainMod = vars.mainMod
local terminal = vars.terminal
local fileManager = vars.fileManager
local browser = vars.browser

-- 壁紙 (pyprland wallpapers): W=次へ+回転再開 / SHIFT+W=回転停止
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pypr wall next"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("pypr wall pause"))

-- アプリ起動
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("vesktop"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("~/.config/rofi/launch.sh"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs -c shell ipc call cc toggle"))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("pkill -x wlogout || wlogout"))

-- スクリーンショット
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/.config/rofi/screenshot-menu.sh"))
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh output DP-3"))

-- 画面録画
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/rofi/record-menu.sh"))
hl.bind(
	mainMod .. " + CTRL + R",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/record.sh ~/personal/tools/facefusion/media/target")
)

-- ウィンドウ操作
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))

-- フォーカス移動
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- ウィンドウ移動
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))

-- WS はグローバルプール (i3/sway 方式)。WS をモニター間で動かさず、フォーカスの方を
-- 移動させる。Hyprland は「各モニターが常にちょうど 1 つの WS を表示する」不変条件を
-- 持つため、WS を手元に引き寄せると供給元のモニターが代わりの WS を調達してしまい
-- (控えから奪う / 番号外の WS を生成する)、所属が操作のたびに乱れる。動かさなければ
-- 所属は固定され、SUPER+N の行き先が常に同じ物理モニターになる。

-- 前後移動は m±1 = 現在のモニターに属する WS 内で巡回。他モニターへ飛ばず、
-- 他モニターが表示中だからと番号を飛ばすこともない。
hl.bind(mainMod .. " + I", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + O", hl.dsp.focus({ workspace = "m+1" }))
-- follow = false で movetoworkspacesilent 相当(送るだけで自分は付いていかない)
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.window.move({ workspace = "m-1", follow = false }))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.window.move({ workspace = "m+1", follow = false }))

-- ワークスペース切替。WS は 1..10 運用で、10 番は数字行の並び通り 0 キーに置く
for i = 1, 10 do
	local key = i == 10 and "0" or tostring(i)
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- スペシャルワークスペース(stash)。S=表示トグル、SHIFT+S=フォーカス窓の退避/復帰。
-- 退避/復帰は往復動作が要るため native の片方向 move ではなく pyprland toggle_special を使う。
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("stash"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("pypr toggle_special stash"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("pypr lost_windows"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("pypr toggle fetch"))

-- マウス
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ウィンドウリサイズ (repeating)
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })

-- メディアキー (locked + repeating)
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- メディアコントロール (locked)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
