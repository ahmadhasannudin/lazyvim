return {
  "lewis6991/satellite.nvim",
  event = "BufReadPost",
  opts = {
    current_only = false,
    winblend = 50,
    zindex = 40,
    excluded_filetypes = {
      "neo-tree",
      "TelescopePrompt",
      "noice",
      "notify",
      "floaterm",
      "DressingInput",
      "DressingSelect",
      "prompt",
      "lazy",
      "mason",
    },
    width = 2,
    handlers = {
      cursor = {
        enable = true,
      },
      search = {
        enable = true,
      },
      diagnostic = {
        enable = true,
        signs = { "-", "=", "≡" },
        min_severity = vim.diagnostic.severity.HINT,
      },
      gitsigns = {
        enable = true,
        signs = {
          add = "│",
          change = "│",
          delete = "-",
        },
      },
      marks = {
        enable = true,
        show_builtins = false,
      },
    },
  },
}
