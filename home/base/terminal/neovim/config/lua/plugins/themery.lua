return {
	"zaldih/themery.nvim",
	lazy = false,
	config = function()
		require("themery").setup({
			themes = {
				"kanagawa-dragon",
				"kanagawa-wave",
				"kanagawa-lotus",
				"tokyonight",
				"tokyonight-night",
				"tokyonight-storm",
				"catppuccin",
				"catppuccin-mocha",
			},
			livePreview = true,
		})
	end,
	keys = {
		{ "<leader>ut", "<cmd>Themery<cr>", desc = "Theme Switcher" },
	},
}
