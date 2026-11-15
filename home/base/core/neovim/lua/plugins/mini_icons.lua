---@type LazySpec
return {
  "nvim-mini/mini.icons",
  branch = "stable",
  lazy = false,
  priority = 900,
  config = function()
    require("mini.icons").setup()
    require("mini.icons").mock_nvim_web_devicons()
  end,
}
