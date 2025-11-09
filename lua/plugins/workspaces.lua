return {
  {
    "natecraddock/workspaces.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("workspaces").setup({
        path = vim.fn.stdpath("data") .. "/workspaces",
        hooks = {
          open = function()
            -- Only load session if it exists for this workspace
            local ok, persistence = pcall(require, "persistence")
            if ok then
              local session_file = require("persistence").current()
              if vim.fn.filereadable(session_file) == 1 then
                persistence.load()
              end
            end
          end,
        },
      })

      -- Integrate with Telescope (for workspace picker)
      require("telescope").load_extension("workspaces")
    end,
    keys = {
      {
        "<leader>pw",
        function()
          require("telescope").extensions.workspaces.workspaces()
        end,
        desc = "Open Workspace",
      },
      {
        "<leader>pa",
        function()
          vim.ui.input({ prompt = "Workspace name: " }, function(name)
            if name then
              require("workspaces").add(vim.fn.getcwd(), name)
            end
          end)
        end,
        desc = "Add Workspace",
      },
    },
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {
      options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
    },
    keys = {
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "Restore Session",
      },
      {
        "<leader>ql",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore Last Session",
      },
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "Don't Save Current Session",
      },
    },
  },
}
