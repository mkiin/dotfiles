---@type vim.lsp.Config
return {
	cmd = { "tsc", "--lsp", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
	root_dir = function(bufnr, on_dir)
		on_dir(vim.fs.root(bufnr, { "package.json", "tsconfig.json", ".git" }) or vim.fn.getcwd())
	end,
}
