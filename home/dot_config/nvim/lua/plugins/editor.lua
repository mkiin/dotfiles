return {
	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			opts.terminal = {
				win = {
					position = "float",
					border = "rounded",
					key = {
						-- normal modeへ移行するキーバインド
						normal_mode = { "<C-q>", "<C-\\><C-n>", desc = "Normal Mode", mode = "t" },
					},
				},
			}
			opts.picker = {
				sources = {
					files = { hidden = true, exclude = { "node_modules", ".git", "dist", ".next" } },
					grep = { hidden = true, exclude = { "node_modules", ".git", "dist", ".next" } },
				},
			}
		end,
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		keys = {
			{
				"<leader>o",
				function()
					require("neo-tree.command").execute({ focus = true })
				end,
				desc = "Focus NeoTree",
			},
			{
				"<leader>fe",
				function()
					require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
				end,
				desc = "Explorer NeoTree (cwd)",
			},
		},
		opts = {
			filesystem = {
				filtered_items = {
					visible = true,
					hide_dotfiles = false,
					hide_gitignored = false,
				},
				use_libuv_file_watcher = true,
			},
		},
	},
	{
		"folke/flash.nvim",
		opts = {
			search = {
				multi_window = false,
				exclude = {
					"neo-tree",
					"notify",
					"cmp_menu",
					"noice",
					"flash_prompt",
					function(win)
						return not vim.api.nvim_win_get_config(win).focusable
					end,
				},
			},
			modes = {
				char = {
					jump_labels = true,
				},
				search = {
					enabled = true,
				},
			},
		},
		keys = {
			{ "s", false },
			{
				"R",
				mode = { "n", "o", "x" },
				"<cmd>lua require('flash').jump()<cr>",
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "o", "x" },
				"<cmd>lua require('flash').treesitter()<cr>",
				desc = "Flash Treesitter",
			},
		},
	},
}
