return {
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
}
