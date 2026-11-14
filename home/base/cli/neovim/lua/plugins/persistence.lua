return {
	"folke/persistence.nvim",
	event = "BufReadPre",
	opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" } },
	keys = {
		{
			"<leader>ps",
			function()
				require("persistence").load()
			end,
			desc = "Restore session",
		},
		{
			"<leader>pS",
			function()
				require("persistence").select()
			end,
			desc = "Select session",
		},
	},
}
