return {
	{
		"b0o/incline.nvim",
		dependencies = { "nvim-mini/mini.icons" },
		event = "VeryLazy",
		config = function()
			local helpers = require("incline.helpers")
			local devicons = require("nvim-web-devicons")
			require("incline").setup({
				-- 表示・非表示の制御
				hide = {
					cursorline = "smart",
					focused_win = false,
				},
				-- ウィンドウの見た目と配置
				window = {
					padding = 0,
					margin = { horizontal = 1, vertical = 1 },
					placement = { horizontal = "right", vertical = "top" },
					overlap = {
						borders = true,
						statusline = false, -- typo修正: stausline → statusline
						tabline = false,
						winbar = false,
					},
					zindex = 50,
				}, -- ← window の閉じ括弧

				-- レンダリング関数（setup直下に配置）
				render = function(props)
					local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
					if filename == "" then
						filename = "[No Name]"
					end
					local ft_icon, ft_color = devicons.get_icon_color(filename)
					local modified = vim.bo[props.buf].modified

					local function get_diagnostic_label()
						local icons = { error = " ", warn = " ", info = " ", hint = " " }
						local label = {}
						for severity, icon in pairs(icons) do
							local n = #vim.diagnostic.get(props.buf, {
								severity = vim.diagnostic.severity[string.upper(severity)],
							})
							if n > 0 then
								table.insert(label, { icon .. n .. " ", group = "DiagnosticSign" .. severity })
							end
						end
						if #label > 0 then
							table.insert(label, { "┊ " })
						end
						return label
					end

					return {
						{ get_diagnostic_label() },
						ft_icon and { " ", ft_icon, " ", guibg = ft_color, guifg = helpers.contrast_color(ft_color) }
							or "",
						" ",
						{ filename, gui = modified and "bold,italic" or "bold" },
						" ",
						guibg = "#44406e",
					}
				end,
			})
		end,
	},
}
