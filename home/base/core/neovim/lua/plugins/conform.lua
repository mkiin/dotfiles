local lsp_formatters = {
  bash = "bashls",
  c = "clangd",
  ["c.doxygen"] = "clangd",
  cpp = "clangd",
  ["cpp.doxygen"] = "clangd",
  cuda = "clangd",
  lua = "stylua",
  luau = "stylua",
  nix = "nixd",
  objc = "clangd",
  objcpp = "clangd",
  python = "ruff",
  sh = "bashls",
}

---@type LazySpec
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  opts = {
    formatters_by_ft = {
      bash = { "shfmt" },
      lua = { "stylua" },
      luau = { "stylua" },
      nix = { "nixfmt" },
      sh = { "shfmt" },
    },
    default_format_opts = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
    format_on_save = function(bufnr)
      -- Pick one server when several support formatting in the same buffer.
      return {
        name = lsp_formatters[vim.bo[bufnr].filetype] or "oxfmt",
      }
    end,
  },
}
