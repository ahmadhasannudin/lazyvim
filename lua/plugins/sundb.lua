return {
  dir    = vim.fn.stdpath("config") .. "/lua/sundb",
  name   = "sundb",
  lazy   = true,
  cmd    = { "Sundb", "SundbConnect", "SundbQuery" },
  config = function()
    require("sundb").setup()
  end,
  keys = {
    { "<leader>db", function() require("sundb").toggle()             end, desc = "Toggle Sundb" },
    { "<leader>ts", function() require("sundb.ui").toggle_sidebar()  end, desc = "Sundb: toggle sidebar" },
    { "<leader>tl", function() require("sundb.ui").toggle_log()      end, desc = "Sundb: toggle log" },
  },
}
