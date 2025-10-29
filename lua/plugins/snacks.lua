return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        exclude = {
          "vendor",
          "node_modules",
        },
        grep = {},
      },
    },
    keys = {
      {
        "<leader>ss",
        function()
          require("snacks.picker").grep({
            args = {
              "--vimgrep",
              "--smart-case",
              "--hidden",
              "--glob",
              "!**/vendor/**",
              "--glob",
              "!vendor/**",
              "--glob",
              "!**node_modules/**",
              "--glob",
              "!/Users/ahmadhasanudin/projects/old_app/**",
            },
          })
        end,
        desc = "Grep with exclusions",
      },
    },
  },
}
