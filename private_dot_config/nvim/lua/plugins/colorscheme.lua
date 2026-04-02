return {
	-- LazyVimのcolorschemeをoshicolorに設定
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "oshicolor",
		},
	},
	-- カラースキームプラグイン
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			theme = "dragon",
			background = {
				dark = "dragon",
				light = "lotus",
			},
		},
	},
	-- カラーコードのハイライト表示
	{
		"brenoprata10/nvim-highlight-colors",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			render = "virtual",
			virtual_symbol = "■",
			virtual_symbol_position = "inline",
			enable_tailwind = false,
		},
	},

	-- 他に使いたいテーマがあれば追加
	{ "folke/tokyonight.nvim", lazy = false },
	{ "catppuccin/nvim", name = "catppuccin", lazy = false },
	{ "rose-pine/neovim", name = "rose-pine", lazy = false },

	-- テーマ切り替え管理
	{
		"zaldih/themery.nvim",
		lazy = false,
		config = function()
			require("themery").setup({
				themes = {
					"oshicolor",
					"kanagawa-dragon",
					"kanagawa-wave",
					"kanagawa-lotus",
					"tokyonight",
					"tokyonight-night",
					"tokyonight-storm",
					"catppuccin",
					"catppuccin-mocha",
					"rose-pine",
					"rose-pine-moon",
				},
				livePreview = true,
			})
		end,
		keys = {
			{ "<leader>ut", "<cmd>Themery<cr>", desc = "Theme Switcher" },
		},
	},
}
