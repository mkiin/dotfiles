return {
	{
		"folke/snacks.nvim",
		opts = function(_, opts)
			-- デフォルトの "c"(Config) を Claude Code に差し替え
			for i, key in ipairs(opts.dashboard.preset.keys) do
				if key.key == "c" then
					opts.dashboard.preset.keys[i] = {
						icon = "󰚩 ",
						key = "c",
						desc = "Claude Code (danger)",
						action = function()
							require("sidekick.cli").toggle({ name = "claude-danger", focus = true })
						end,
					}
					break
				end
			end

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
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "o", "x" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
		},
	},
}
