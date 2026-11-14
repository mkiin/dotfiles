local root_markers = { ".oxfmtrc.jsonc", ".oxfmtrc.json", "oxfmt.config.ts", "package.json", ".git" }

---@type vim.lsp.Config
return {
  root_markers = root_markers,
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, root_markers)
    if root then
      on_dir(root)
    end
  end,
}
