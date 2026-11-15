---@type LazySpec
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      nix = { "nixfmt" },
      sh = { "shfmt" },
    },
    default_format_opts = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
    format_on_save = {
      -- Only restrict LSP formatting; the external formatters above still take precedence.
      name = "oxfmt",
    },
  },
}
