---@type LazySpec
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "saghen/blink.cmp" },
  config = function()
    vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp_on_attach", { clear = true }),
      callback = function(event)
        local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
        require("plugins.nvim-lspconfig.on_attach")(client, event.buf)
      end,
    })
    vim.lsp.enable({
      "lua_ls",
      "nixd",
      "tsrs",
      "oxlint",
      "oxfmt",
    })
  end,
}
