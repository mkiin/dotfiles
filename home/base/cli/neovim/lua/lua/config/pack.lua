require("core.plugin").init()

local lazy = require("lazy")

lazy.setup({
	spec = {
		{ import = "plugin" },
	},
	defaults = { lazy = true },
	checker = { enabled = false },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
