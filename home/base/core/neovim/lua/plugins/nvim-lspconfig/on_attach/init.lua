return function(client, bufnr)
  require("plugins.nvim-lspconfig.on_attach.keymaps").on_attach(client, bufnr)
end
