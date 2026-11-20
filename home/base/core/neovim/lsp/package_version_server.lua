---@type vim.lsp.Config
return {
  cmd = { "package-version-server" },
  filetypes = { "json" },
  root_dir = function(bufnr, on_dir)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if vim.fs.basename(path) == "package.json" then
      on_dir(vim.fs.dirname(path))
    end
  end,
}
