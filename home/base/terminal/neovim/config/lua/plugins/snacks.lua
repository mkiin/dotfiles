return {
	"folke/snacks.nvim",
	keys = {
		{
			"<leader>gb",
			function()
				Snacks.picker.git_branches()
			end,
			desc = "Branches",
		},
	},
	opts = function(_, opts)
		opts.terminal = {
			win = {
				position = "float",
				border = "rounded",
				key = {
					-- normal modeへ移行するキーバインド
					normal_mode = { "<C-q>", "<C-\\><C-n>", desc = "Normal Mode", mode = "t" },
				},
			},
		}
		opts.picker = opts.picker or {}
		opts.picker.sources = vim.tbl_deep_extend("force", opts.picker.sources or {}, {
			explorer = { hidden = true },
			files = { hidden = true },
			grep = { hidden = true },
		})
	end,
}
