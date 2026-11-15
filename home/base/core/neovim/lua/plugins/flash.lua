---@type LazySpec
return {
  "https://github.com/folke/flash.nvim",
  event = "BufReadPost",
  ---@type Flash.Config
  opts = {
    modes = {
      char = { enabled = false },
      search = { enabled = false },
    },
  },
  keys = {
    -- A leader prefix can finish the operator before which-key replays the mapping.
    {
      "S",
      mode = { "n", "x", "o" },
      function()
        require("flash").treesitter()
      end,
      desc = "Flash Treesitter selection",
    },
    {
      "r",
      mode = "o",
      function()
        require("flash").remote()
      end,
      desc = "Remote Flash",
    },
    {
      "<CR>",
      mode = { "n", "x", "o", "v" },
      function()
        require("flash").jump({
          label = { before = true, after = false },
          -- TODO: kensaku integration
        })
      end,
      desc = "Flash",
    },
  },
}
