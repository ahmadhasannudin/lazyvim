return {
  "sindrets/diffview.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewToggleFiles",
    "DiffviewFocusFiles",
    "DiffviewRefresh",
    "DiffviewFileHistory",
  },
  opts = {
    enhanced_diff_hl = true,
    view = {
      default = {
        layout = "diff2_horizontal",
      },
      merge_tool = {
        layout = "diff3_horizontal",
      },
      file_history = {
        layout = "diff2_horizontal",
      },
    },
    keymaps = {
      view = {
        -- Open actual file to edit and use gitsigns
        { "n", "gf", "<cmd>DiffviewClose<CR><cmd>e #<CR>", { desc = "Edit file (close diffview)" } },
      },
      file_panel = {
        -- Restore file (revert all changes)
        { "n", "X", function()
          local actions = require("diffview.actions")
          actions.restore_entry()
        end, { desc = "Restore file (revert all)" } },
      },
    },
  },
  keys = {
    {
      "<leader>gv",
      "<cmd>DiffviewOpen<cr>",
      desc = "Open Diffview",
    },
    {
      "<leader>gV",
      "<cmd>DiffviewClose<cr>",
      desc = "Close Diffview",
    },
    {
      "<leader>gfh",
      "<cmd>DiffviewFileHistory %<cr>",
      desc = "File History (Diffview)",
    },
    {
      "<leader>gbh",
      "<cmd>DiffviewFileHistory<cr>",
      desc = "Branch History (Diffview)",
    },
  },
}
