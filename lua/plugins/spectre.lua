return {
  "nvim-pack/nvim-spectre",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = "Spectre",
  opts = {
    open_cmd = "vnew",
  },
  keys = {
    {
      "<leader>sr",
      function()
        require("spectre").open()
      end,
      desc = "Replace in files (Spectre)",
    },
    {
      "<leader>sw",
      function()
        require("spectre").open_visual({ select_word = true })
      end,
      desc = "Replace current word (Spectre)",
    },
    {
      "<leader>sw",
      function()
        require("spectre").open_visual()
      end,
      mode = "v",
      desc = "Replace selection (Spectre)",
    },
    {
      "<leader>sf",
      function()
        require("spectre").open_file_search({ select_word = true })
      end,
      desc = "Replace in current file (Spectre)",
    },
  },
}
