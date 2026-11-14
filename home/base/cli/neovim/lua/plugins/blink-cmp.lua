return {
	"saghen/blink.cmp",
	version = "1.*",
	event = { "InsertEnter", "CmdlineEnter" },
	cond = not is_vscode(),
	dependencies = { "folke/lazydev.nvim" },
	opts = {
		keymap = { preset = "enter", ["<C-k>"] = false },
		fuzzy = { implementation = "rust" },
		completion = { list = { selection = { preselect = false, auto_insert = false } } },
		sources = {
			default = { "lazydev", "lsp", "path", "snippets", "buffer" },
			providers = {
				lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
			},
		},
		cmdline = {
			enabled = true,
			keymap = { preset = "cmdline", ["<C-e>"] = false },
			completion = {
				menu = { auto_show = true },
				list = { selection = { preselect = false, auto_insert = true } },
			},
		},
	},
}
