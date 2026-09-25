hl.config({
	general = {
		gaps_in = 3,
		gaps_out = 8,
		border_size = 0,
		layout = "dwindle",
		resize_on_border = true,
		allow_tearing = false,
	},
	decoration = {
		rounding = 14,
		shadow = {
			enabled = true,
			range = 15,
			render_power = 4,
			-- offset = "0 0",
			color = "rgba(00000080)",
			color_inactive = "rgba(00000033)",
		},
		blur = {
			enabled = true,
			size = 3, -- ぼかす広さ
			passes = 4, -- ぼかし処理回数
			contrast = 0.9, -- ぼかした背後の明暗差
			brightness = 1.1, -- ぼかした背後の明るさ
			vibrancy = 0.2, -- ぼかした色の彩度を増やす
			vibrancy_darkness = 0.2, -- 暗い部分に対する彩度補強の強さ
			noise = 0.01, -- ぼかしに加える粒上感
			new_optimizations = true, -- ぼかしの最適化
			ignore_opacity = true, -- ぼかし層がウィンドウ不透明度を無視する設定
			xray = true, -- floatウィンドウのボカシがはいごのタイルウィンドウを無視する
		},
	},
	animations = { enabled = true },
	dwindle = { preserve_split = true },
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
})

hl.curve("wind", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1 } } })
hl.curve("winIn", { type = "bezier", points = { { 0.1, 1 }, { 0.1, 1 } } })
hl.curve("winOut", { type = "bezier", points = { { 0.3, -0.3 }, { 0, 1 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 6, bezier = "winIn", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "winOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "wind", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner", style = "once" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "wind" })
