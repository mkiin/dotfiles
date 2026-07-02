return {
	{
		"stevearc/oil.nvim",
		-- ディレクトリ引数や netrw 乗っ取りで即使うため遅延ロードしない
		lazy = false,
		dependencies = { "nvim-mini/mini.icons" },
		keys = {
			{ "<leader>e", "<cmd>Oil<cr>", desc = "Explorer Oil (buffer dir)" },
			{ "<leader>fe", "<cmd>Oil<cr>", desc = "Explorer Oil (buffer dir)" },
			{
				"<leader>E",
				function()
					require("oil").open(vim.uv.cwd())
				end,
				desc = "Explorer Oil (cwd)",
			},
			{
				"<leader>fE",
				function()
					require("oil").open(vim.uv.cwd())
				end,
				desc = "Explorer Oil (cwd)",
			},
			{ "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
		},
		opts = {
			default_file_explorer = true,
			delete_to_trash = true,
			skip_confirm_for_simple_edits = true,
			columns = { "icon" },
			view_options = {
				show_hidden = false,
			},
			keymaps = {
				-- <C-h>/<C-l> はウィンドウ移動に使うため oil 側では無効化
				["<C-h>"] = false,
				["<C-l>"] = false,
			},
		},
	},
}
