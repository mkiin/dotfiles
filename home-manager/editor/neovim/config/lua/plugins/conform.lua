return {
	"stevearc/conform.nvim",
	opts = {
		formatters_by_ft = {
			c = { "clang_format" },
			cpp = { "clang_format" },
			javascript = { "oxfmt" },
			javascriptreact = { "oxfmt" },
			typescript = { "oxfmt" },
			typescriptreact = { "oxfmt" },
			json = { "oxfmt" },
			vue = { "oxfmt" },
			jsonc = { "deno_fmt" },
			sh = { "shfmt" },
			bash = { "shfmt" },
		},
	},
}
