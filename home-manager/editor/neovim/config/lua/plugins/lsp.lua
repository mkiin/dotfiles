return {
	{
		"mfussenegger/nvim-lint",
		enabled = false,
	},
	{ "mason-org/mason.nvim", enabled = false },
	{ "mason-org/mason-lspconfig.nvim", enabled = false },
	{
		"neovim/nvim-lspconfig",
		opts = {
			inlay_hints = {
				enabled = false,
			},
			servers = {
				tsgo = {
					server_capabilities = {
						documentFormattingProvider = false,
						documentRangeFormattingProvider = false,
						documentOnTypeFormattingProvider = false,
					},
				},
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = {
								globals = { "vim" },
							},
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false,
							},
						},
					},
				},
				nixd = {},
				bashls = {},
				clangd = {
					cmd = {
						"clangd",
						"--background-index",
						"--clang-tidy",
						"--header-insertion=never",
						"--query-driver=**/bin/xtensa-*-elf-*,**/bin/riscv32-*-elf-*",
					},
					capabilities = {
						offsetEncoding = { "utf-16" },
					},
				},
			},
		},
	},
	{
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
	},
}
