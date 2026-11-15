---@type LazySpec
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  enabled = true,
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  opts = function()
    return
    ---@type NoiceConfig
    {
      popupmenu = {
        enabled = true,
        backend = "nui",
      },
      notify = {
        enabled = true,
        view = "mini",
      },
      cmdline = {
        enabled = true,
      },
      messages = {
        view_search = "virtualtext",
        view = "mini",
      },
      presets = {
        long_message_to_split = true,
      },
    }
  end,
  config = true,
}
