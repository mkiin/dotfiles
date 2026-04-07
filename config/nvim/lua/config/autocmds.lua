-- Turn off paste mode when leaving insert
vim.api.nvim_create_autocmd("InsertLeave", {
	pattern = "*",
	command = "set nopaste",
})

-- Disable the concealing in some file formats
-- The default conceallevel is 3 in LazyVim
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "json", "jsonc", "markdown" },
	callback = function()
		vim.opt.conceallevel = 0
	end,
})

-- Neo-tree git status refresh after git operations
vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained" }, {
	callback = function()
		local ok, manager = pcall(require, "neo-tree.sources.manager")
		if ok then
			manager.refresh("git_status")
		end
	end,
})

-- スペルチェッカーの無効化
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
