local M = {}

function M.on_attach(_, bufnr)
  vim.keymap.set("n", "gd", function()
    Snacks.picker.lsp_definitions()
  end, { buffer = bufnr, desc = "Definitions" })
  vim.keymap.set("n", "gr", function()
    Snacks.picker.lsp_references()
  end, { buffer = bufnr, desc = "References" })
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
  vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename symbol" })
  vim.keymap.set("n", "<leader>cf", function()
    vim.lsp.buf.format({ name = "oxfmt" })
  end, { buffer = bufnr, desc = "Format with oxfmt" })
end

return M
