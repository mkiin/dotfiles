local root_markers = { ".oxfmtrc.jsonc", ".oxfmtrc.json", "package.json", ".git" }

---@type vim.lsp.Config
return {
  filetypes = {
    "css",
    "scss",
    "less",
    "html",
    "vue",
    "svelte",
    "astro",
    "json",
    "jsonc",
    "json5",
    "graphql",
    "handlebars",
    "markdown",
    "markdown.mdx",
    "yaml",
  },
  root_markers = root_markers,
  -- Override nvim-lspconfig's root_dir so these markers also apply to plain Git projects.
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, root_markers)
    if root then
      on_dir(root)
    end
  end,
}
