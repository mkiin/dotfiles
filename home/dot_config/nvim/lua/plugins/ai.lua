return {
	{
		"folke/sidekick.nvim",
		opts = {
			cli = {
				win = {
					keys = {
						prompt = false,
					},
				},
				tools = {
					claude = {
						cmd = { "claude" },
					},
					["claude-danger"] = {
						cmd = { "claude", "--dangerously-skip-permissions" },
					},
					["claude-auto"] = {
						cmd = { "claude", "--enable-auto-mode" },
					},
				},
			},
			nes = {
				enabled = false,
			},
			copilot = {
				enabled = false,
			},
		},
		keys = {
			{ "<leader>ap", false },
			{ "<C-b>", false },
			{
				"<leader>aa",
				function()
					require("sidekick.cli").toggle({ name = "claude-auto", focus = true })
				end,
				desc = "Sidekick Toggle Claude (自動モード)",
			},
			{
				"<leader>aA",
				function()
					require("sidekick.cli").toggle({ name = "claude-danger", focus = true })
				end,
				desc = "Sidekick Toggle Claude (危険モード)",
			},
		},
	},
}
