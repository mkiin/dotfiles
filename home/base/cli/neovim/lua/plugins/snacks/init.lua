---@type LazySpec
return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  init = function()
    vim.api.nvim_create_user_command("Bdelete", function()
      Snacks.bufdelete()
    end, {})
    vim.api.nvim_create_user_command("Bdeleteall", function()
      Snacks.bufdelete.all()
    end, {})
  end,
  opts = function()
    return {
      bigfile = { enabled = true },
      input = { enabled = true },
      explorer = { enabled = true },
      picker = { enabled = true, ui_select = true },
      dashboard = require("plugins.snacks.dashboard"),
      terminal = {
        start_insert = false,
        auto_insert = false,
        win = { position = "float", width = 0.8, height = 0.8 },
      },
    }
  end,
  keys = {
    {
      "<leader>e",
      function()
        Snacks.explorer()
      end,
      desc = "File explorer",
    },
    {
      "<leader>tt",
      function()
        Snacks.terminal.toggle()
      end,
      mode = { "n", "t" },
      desc = "Toggle terminal",
    },
    {
      "<leader><space>",
      function()
        Snacks.picker.smart()
      end,
      desc = "Smart files",
    },
    {
      ",f",
      function()
        Snacks.picker.files({ hidden = true })
      end,
      desc = "Files",
    },
    {
      ",<space>",
      function()
        Snacks.picker.grep({ hidden = true })
      end,
      desc = "Grep",
    },
    {
      ",B",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Buffers",
    },
    {
      ",h",
      function()
        Snacks.picker.help()
      end,
      desc = "Help",
    },
    {
      ",P",
      function()
        Snacks.picker.projects()
      end,
      desc = "Projects",
    },
    {
      ",d",
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = "Buffer diagnostics",
    },
    {
      ",D",
      function()
        Snacks.picker.diagnostics()
      end,
      desc = "Diagnostics",
    },
  },
}
