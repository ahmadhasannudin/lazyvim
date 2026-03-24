return {
  dir = vim.fn.stdpath("config") .. "/lua/sundb",
  name = "sundb",
  lazy = false,
  config = function()
    require("sundb").setup()
  end,
  keys = {
    {
      "<leader>db",
      function()
        require("sundb").toggle()
      end,
      desc = "Toggle Sundb",
    },
  },
}
