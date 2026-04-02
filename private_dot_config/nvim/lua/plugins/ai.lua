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
			{
				"<leader>aa",
				function()
					require("sidekick.cli").toggle({ name = "claude", focus = true })
				end,
				desc = "Sidekick Toggle Claude (通常モード)",
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
