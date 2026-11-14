---@type LazySpec
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPost", "BufNewFile" },
  cmd = "Gitsigns",
  opts = {
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~_" },
    },
    current_line_blame = true,
    on_attach = function(buf)
      local gs = require("gitsigns")
      vim.keymap.set("n", "]h", function()
        gs.nav_hunk("next")
      end, { buffer = buf, desc = "Next hunk" })
      vim.keymap.set("n", "[h", function()
        gs.nav_hunk("prev")
      end, { buffer = buf, desc = "Previous hunk" })
      vim.keymap.set("n", "<leader>gs", gs.stage_hunk, { buffer = buf, desc = "Stage hunk" })
      vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = buf, desc = "Preview hunk" })
    end,
  },
}
