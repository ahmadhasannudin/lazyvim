return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function()
      local settings = vim.g.SETTINGS or { auto_format_on_save = false }
      return {
        formatters_by_ft = {
          lua = { "stylua" },
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          svelte = { "prettier" },
          json = { "prettier" },
          html = { "prettier" },
          css = { "prettier" },
          scss = { "prettier" },
          -- PHP will use LSP formatting (intelephense)
        },
        format_on_save = settings.auto_format_on_save and function(bufnr)
          return { timeout_ms = 500, lsp_fallback = true }
        end or nil,
        format_after_save = nil,
      }
    end,
  },
}
