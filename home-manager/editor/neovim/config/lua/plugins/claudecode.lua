return {
	"coder/claudecode.nvim",
	cmd = {
		"ClaudeCode",
		"ClaudeCodeFocus",
		"ClaudeCodeOpen",
		"ClaudeCodeClose",
		"ClaudeCodeStart",
		"ClaudeCodeStop",
		"ClaudeCodeStatus",
		"ClaudeCodeSend",
		"ClaudeCodeAdd",
	},
	opts = {
		terminal = {
			provider = "external",
			provider_opts = {
				-- wezterm のカレントペインを右に分割し claude を起動する。
				-- mux サーバーは jobstart の env を継承しないため env_table を env(1) で明示注入する。
				external_terminal_cmd = function(cmd_string, env_table)
					local width_percent = 40
					local parts = {
						"wezterm",
						"cli",
						"split-pane",
						"--right",
						"--percent",
						tostring(width_percent),
						"--cwd",
						vim.fn.getcwd(),
						"--",
						"env",
					}
					for k, v in pairs(env_table or {}) do
						table.insert(parts, string.format("%s=%s", k, tostring(v)))
					end
					vim.list_extend(parts, vim.split(cmd_string, " ", { trimempty = true }))
					return parts
				end,
			},
		},
	},
	keys = {
		{ "<leader>a", "", desc = "+claude", mode = { "n", "v" } },
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "起動/トグル (wezterm ペイン)" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = { "n", "v" }, desc = "選択を送信" },
		{
			"<leader>ab",
			function()
				vim.cmd("ClaudeCodeAdd " .. vim.fn.expand("%"))
			end,
			desc = "現在バッファを追加",
		},
		{ "<leader>aS", "<cmd>ClaudeCodeStart<cr>", desc = "連携を開始" },
		{ "<leader>aq", "<cmd>ClaudeCodeStop<cr>", desc = "連携を停止" },
		{ "<leader>ai", "<cmd>ClaudeCodeStatus<cr>", desc = "接続状態を表示" },
		{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "モデル選択して起動" },
		{ "<leader>ay", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "diff を承認" },
		{ "<leader>an", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "diff を却下" },
	},
}
