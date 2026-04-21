return {
	{
		"saghen/blink.cmp",
		opts = function(_, opts)
			opts.sources = {
				default = { "lsp", "snippets" },
			}
			return opts
		end,
		init = function()
			vim.api.nvim_set_hl(0, "SnippetTabstop", { bg = "NONE" })
		end,
	},
	{
		"nvim-mini/mini.surround",
		opts = {
			mappings = {
				add = "sa",
				delete = "sd",
				find = "sf",
				find_left = "sF",
				highlight = "sh",
				replace = "sr",
				update_n_lines = "sn",
			},
		},
	},
	{
		"umutondersu/smart-newline.nvim",
		event = "BufReadPost",
		opts = {
			brackets = { enabled = true },
			html_tags = { enabled = true },
		},
	},
}
