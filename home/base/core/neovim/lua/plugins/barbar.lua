---@type LazySpec
return {
  "romgrk/barbar.nvim",
  dependencies = { "nvim-mini/mini.icons", "lewis6991/gitsigns.nvim" },
  event = "VeryLazy",
  init = function()
    vim.g.barbar_auto_setup = false
  end,
  opts = {},
  keys = {
    { "H", "<cmd>BufferPrevious<cr>", desc = "Previous buffer" },
    { "L", "<cmd>BufferNext<cr>", desc = "Next buffer" },
    { "<leader>bp", "<cmd>BufferPick<cr>", desc = "Pick buffer" },
    { "<leader>bd", "<cmd>BufferClose<cr>", desc = "Close buffer" },
    { "<leader>bi", "<cmd>BufferPin<cr>", desc = "Pin buffer" },
  },
}
