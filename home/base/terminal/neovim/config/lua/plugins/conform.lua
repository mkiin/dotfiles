return {
	"stevearc/conform.nvim",
	opts = {
		formatters = {
			nixfmt = {
				args = { "-" },
			},
		},
		formatters_by_ft = {
			nix = { "nixfmt" },
			c = { "clang_format" },
			cpp = { "clang_format" },
			javascript = { "oxfmt" },
			javascriptreact = { "oxfmt" },
			typescript = { "oxfmt" },
			typescriptreact = { "oxfmt" },
			python = { "ruff_format" },
			json = { "oxfmt" },
			vue = { "oxfmt" },
			jsonc = { "deno_fmt" },
			sh = { "shfmt" },
			bash = { "shfmt" },
		},
	},
}
