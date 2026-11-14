return {
	"nvim-mini/mini.ai",
	branch = "stable",
	lazy = false,
	priority = 900,
	dependencies = { "nvim-mini/mini.extra" },
	config = function()
		local gen = require("mini.extra").gen_ai_spec
		require("mini.ai").setup({
			custom_textobjects = {
				e = gen.buffer(),
				D = gen.diagnostic(),
				I = gen.indent(),
				L = gen.line(),
				N = gen.number(),
				J = { { "()%d%d%d%d%-%d%d%-%d%d()", "()%d%d%d%d%/%d%d%/%d%d()" } },
			},
		})
		vim.keymap.set({ "x", "o" }, "A", function()
			return vim.api.nvim_get_mode().mode == t("<C-v>") and "A" or "ae"
		end, { remap = true, expr = true, desc = "Select entire buffer" })
		-- Keep the reference's quote objects after mini.ai installs its mappings.
		for _, quote in ipairs({ '"', "'", "`" }) do
			vim.keymap.set({ "x", "o" }, "a" .. quote, "2i" .. quote)
		end
	end,
}
