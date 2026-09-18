return {
	"folke/snacks.nvim",
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
		opts.picker = {
			sources = {
				explorer = { hidden = true },
			},
		}
	end,
}
