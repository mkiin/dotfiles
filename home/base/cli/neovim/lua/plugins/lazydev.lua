---@type LazySpec
return {
  "folke/lazydev.nvim",
  ft = "lua",
  opts = function()
    return {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv", "uv%.UV_timer_t" } },
        { path = vim.env.VIMRUNTIME, words = { "vim%.lsp%.Config", "vim%.keymap%.set%.Opts" } },
        { path = "lazy.nvim", words = { "LazySpec" } },
        { path = "snacks.nvim", words = { "Snacks", "snacks%." } },
        { path = "flash.nvim", words = { "Flash%.Config" } },
        { path = "noice.nvim", words = { "NoiceConfig" } },
        { path = "blink.cmp", words = { "blink%.cmp%.Config" } },
      },
    }
  end,
}
