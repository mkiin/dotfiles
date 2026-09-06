return {
	"akinsho/bufferline.nvim",
	opts = function(_, opts)
		-- LazyVim は catppuccin のときだけ bufferline 専用 highlight を焼き込む。
		-- その値が themery の実行時テーマ切替後も残って tokyonight で色が崩れる。
		-- ColorScheme のたびにテーマ別 highlights を選び直して bufferline を setup し直す。
		local function highlights_for(name)
			name = name or ""
			-- catppuccin は完全な highlights を関数形式で返すのでそのまま使う。
			if name:find("catppuccin") then
				local ok, m = pcall(function()
					return require("catppuccin.special.bufferline").get_theme()
				end)
				if ok and m then
					return m
				end
			end
			local base = {}
			-- Normal を透過(bg=NONE)にしているため bufferline は separator 色を導けず
			-- "NONE"→白グリフになる。separator セルも透過にして buffer 背景に溶け込ませる。
			for _, k in ipairs({ "separator", "separator_visible", "separator_selected" }) do
				base[k] = { fg = "NONE", bg = "NONE" }
			end
			return base
		end

		-- 区切りの │ グリフ自体を描かない（透過端末で白線が原理的に出ないように）。
		opts.options = opts.options or {}
		opts.options.separator_style = { "", "" }

		opts.highlights = highlights_for(vim.g.colors_name)

		vim.api.nvim_create_autocmd("ColorScheme", {
			group = vim.api.nvim_create_augroup("bufferline_theme_follow", { clear = true }),
			callback = function(ev)
				opts.highlights = highlights_for(ev.match)
				require("bufferline").setup(opts)
				vim.cmd("redrawtabline")
			end,
		})
	end,
}
