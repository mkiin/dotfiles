---@type LazySpec
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  opts = {
    flavour = "mocha",
    auto_integrations = true,
    custom_highlights = function(colors)
      return {
        FlashLabel = { fg = colors.crust, bg = colors.red, style = { "bold" } },
      }
    end,
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
