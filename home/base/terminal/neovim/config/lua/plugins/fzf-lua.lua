return {
	"ibhagwan/fzf-lua",
	opts = {
		files = { hidden = true },
		grep = { hidden = true },
	},
	keys = {
		{ "<leader>gb", "<cmd>FzfLua git_branches<cr>", desc = "Branches" },
	},
}
