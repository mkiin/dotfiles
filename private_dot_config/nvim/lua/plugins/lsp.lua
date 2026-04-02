return {
	{
		"mfussenegger/nvim-lint",
		enabled = false,
	},
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
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				javascript = { "oxfmt" },
				javascriptreact = { "oxfmt" },
				typescript = { "oxfmt" },
				typescriptreact = { "oxfmt" },
				json = { "oxfmt" },
				vue = { "oxfmt" },
			},
		},
	},
}
