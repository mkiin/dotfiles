return {
	"folke/flash.nvim",
	opts = {
		search = {
			multi_window = false,
			exclude = {
				"notify",
				"cmp_menu",
				"noice",
				"flash_prompt",
				function(win)
					return not vim.api.nvim_win_get_config(win).focusable
				end,
			},
		},
		modes = {
			char = {
				jump_labels = true,
			},
			search = {
				enabled = true,
			},
		},
	},
	keys = {
		{ "s", false },
		{
			"R",
			mode = { "n", "o", "x" },
			"<cmd>lua require('flash').jump()<cr>",
			desc = "Flash",
		},
		{
			"S",
			mode = { "n", "o", "x" },
			"<cmd>lua require('flash').treesitter()<cr>",
			desc = "Flash Treesitter",
		},
	},
}
