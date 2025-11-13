-- ~/.config/nvim/lua/plugins/git-conflict.lua
return {
  "akinsho/git-conflict.nvim",
  event = "BufReadPost",
  config = function()
    require("git-conflict").setup({
      default_mappings = true,  -- enable VSCode-like keymaps
      disable_diagnostics = false,
      highlights = {            -- customize colors like VSCode
        incoming = "DiffText",
        current  = "DiffAdd",
      },
    })
  end,
}
