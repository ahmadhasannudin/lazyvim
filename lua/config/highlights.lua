-- Custom highlight groups for better syntax highlighting
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    -- Variables
    vim.api.nvim_set_hl(0, "@variable", { link = "Identifier" })
    vim.api.nvim_set_hl(0, "@variable.builtin", { link = "Special" })
    vim.api.nvim_set_hl(0, "@variable.parameter", { link = "Identifier" })
    vim.api.nvim_set_hl(0, "@variable.member", { link = "Identifier" })
  end,
})

-- Apply immediately on startup
vim.defer_fn(function()
  vim.api.nvim_set_hl(0, "@variable", { link = "Identifier" })
  vim.api.nvim_set_hl(0, "@variable.builtin", { link = "Special" })
  vim.api.nvim_set_hl(0, "@variable.parameter", { link = "Identifier" })
  vim.api.nvim_set_hl(0, "@variable.member", { link = "Identifier" })
end, 200)
