return {
	"akinsho/bufferline.nvim",
	opts = function(_, opts)
		-- LazyVim は catppuccin のときだけ bufferline 専用 highlight を焼き込む。
		-- その値が themery の実行時切替後も残り（bufferline #1030 で ColorScheme 時に
		-- 再生成されない）、tokyonight/rose-pine で色が崩れる。テーマごとに highlights を
		-- 選び直して ColorScheme のたびに setup し直す。
		local function highlights_for(name)
			name = name or ""
			if name:find("catppuccin") then
				local ok, m = pcall(require, "catppuccin.special.bufferline")
				return ok and m.get_theme() or {}
			elseif name:find("rose%-pine") then
				local ok, m = pcall(require, "rose-pine.plugins.bufferline")
				return ok and m or {}
			end
			-- 専用テーブルを持たないテーマ（tokyonight/kanagawa 等）は
			-- bufferline のカラースキーム自動生成に委ねる
			return {}
		end

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
