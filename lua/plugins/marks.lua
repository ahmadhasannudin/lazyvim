return {
  "chentoast/marks.nvim",
  event = "VeryLazy",
  opts = {
    default_mappings = true,
    builtin_marks = { ".", "<", ">", "^" },
    cyclic = true,
    force_write_shada = false,
    refresh_interval = 250,
    sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
    excluded_filetypes = {
      "snacks_picker_list",
      "snacks_picker_input",
      "neo-tree",
      "TelescopePrompt",
      "lazy",
      "mason",
      "help",
      "alpha",
      "dashboard",
    },
    bookmark_0 = {
      sign = "⚑",
      virt_text = "",
      annotate = false,
    },
    mappings = {},
  },
}
