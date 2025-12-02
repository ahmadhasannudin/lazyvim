return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      dashboard = {
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            {
              icon = " ",
              key = "p",
              desc = "Projects",
              action = ":lua require('telescope').extensions.workspaces.workspaces()",
            },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
          header = [[
⠈⠙⠲⢶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣿⡀⠀⠀⠀⠀⠀⠀⠀⡄⠀⠀⡄⠀⠀⠀⠀⠀⠀⠀⣼⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣿⠟⠓⠉
⠀⠀⠀⠀⠈⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⢀⣧⣶⣦⣇⠀⠀⠀⠀⠀⢀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠉⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣶⣶⣶⣾⣿⣿⣿⣿⣶⣶⣶⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠛⠛⠛⠛⠛⠛⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠟⠛⠛⠛⠛⠛⠛⠃⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
          ]],
          --           header = [[
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢹⣿⣿⣿⣿⣿⣿⣿⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁⢸⣿⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⣿⣿⣿⣿⣿⢀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⣿⣿⣿⣿⣿⣿⣿⣼⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⡿⠿⠿⠿⠿⢿⣿⡿⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠈⠃⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠃⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡦⢄⡀⠀⢀⢠⠀⢀⣠⠤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣬⣽⣾⢿⣿⣯⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢹⣿⣿⣿⣿⣿⣷⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⢈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠟⠋⢁⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀⠙⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠛⠛⠉⠀⠀⠀⠀⠀⠈⠹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠄⠀⠀⠀⠈⠉⠛⠛⠛⠻⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⡿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⢻⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢉⣽⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣄⠈⠉⠛⠿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⢁⠀⠀⠀⠀⣀⣴⡾⠀⠀⠀⠀⠀⠀⠠⠚⠉⡀⢤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡦⢄⡈⠀⠀⠀⠀⠀⠀⠀⢠⣀⣀⠀⠀⠀⠐⣆⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⠀⠀⣠⣾⣿⡟⠀⠀⠀⠀⠀⠀⢀⡠⠒⠉⠀⠈⠻⣿⣿⣿⠛⠿⢻⣿⣿⡿⠋⠀⠀⠈⠢⢄⠀⠀⠀⠀⠀⠀⠙⢿⣿⣶⣤⡀⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣀⣾⣿⣿⣿⣴⣾⠀⠀⠀⢀⡴⠋⠀⠀⠀⠀⠀⠀⠀⠉⠁⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠑⢄⠀⠀⠀⣐⣶⣦⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣾⣂⣴⣟⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣈⣳⣄⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⣀⣀⣀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          -- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          --           ]],
        },
      },
      picker = {
        preview = {
          enabled = false,
        },
        sources = {
          files = {
            hidden = true,
            ignored = true,
            preview = false,
          },
          explorer = {
            -- hidden = true,
            layout = {
              layout = {
                position = "right",
              },
            },
          },
          projects = {
            enabled = false,
          },
        },
        exclude = {
          "vendor",
          "node_modules",
          ".svn",
          ".git",
          "public",
        },
        grep = {
          search = {
            fixed_strings = false,
          },
        },
      },
    },
    keys = {
      {
        "<D-f>",
        function()
          require("snacks.picker").grep({
            args = {
              "--vimgrep",
              "--smart-case",
              "--hidden",
              "--fixed-strings",
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
      {
        "<D-p>",
        function()
          local pickers = require("telescope.pickers")
          local finders = require("telescope.finders")
          local conf = require("telescope.config").values
          local actions = require("telescope.actions")
          local action_state = require("telescope.actions.state")
          local sorters = require("telescope.sorters")
          local entry_display = require("telescope.pickers.entry_display")
          
          -- State for toggles
          local show_hidden = true
          local show_ignored = false
          
          local function create_picker(opts)
            opts = opts or {}
            local hidden = opts.hidden or show_hidden
            local ignored = opts.ignored or show_ignored
            
            -- Get current working directory
            local cwd = vim.fn.getcwd()
            
            -- Get open buffers (highest priority) - in REVERSE order (most recent first)
            local open_buffers = {}
            local buffer_files = {}
            local bufs = vim.api.nvim_list_bufs()
            
            for i = #bufs, 1, -1 do
              local buf = bufs[i]
              local name = vim.api.nvim_buf_get_name(buf)
              if name ~= "" and vim.fn.filereadable(name) == 1 then
                local relative = vim.fn.fnamemodify(name, ":.")
                if not open_buffers[relative] then
                  table.insert(buffer_files, relative)
                  open_buffers[relative] = true
                end
              end
            end
            
            -- Build fd command based on toggles
            local fd_cmd = "fd --type f --color never"
            if hidden then
              fd_cmd = fd_cmd .. " --hidden"
            end
            if not ignored then
              fd_cmd = fd_cmd .. " --exclude .git --exclude node_modules --exclude vendor"
            end
            
            -- Collect all files
            local all_files = {}
            local handle = io.popen(fd_cmd)
            if handle then
              for line in handle:lines() do
                if not open_buffers[line] then
                  table.insert(all_files, line)
                end
              end
              handle:close()
            end
            
            -- Custom sorter that ALWAYS shows matched buffers first, then matched files
            local default_sorter = conf.file_sorter({})
            local custom_sorter = sorters.Sorter:new({
              scoring_function = function(_, prompt, line, entry)
                if not prompt or prompt == "" then
                  -- No search: show buffers first, then files
                  if entry.is_buffer then
                    return -1000000 - entry.idx -- Very negative = appears first
                  else
                    return entry.idx -- Positive = appears later
                  end
                end
                
                -- With search: get normal score from telescope
                local score = default_sorter:scoring_function(prompt, line)
                
                -- CRITICAL FIX: If score is too high (no match), filter it out
                -- Telescope's fuzzy matcher returns very high scores for non-matches
                if score == -1 or score > 1000000 then
                  -- This entry doesn't match the search - hide it completely
                  return -1  -- Return -1 to indicate no match (Telescope convention)
                end
                
                -- CRITICAL: Ensure buffers ALWAYS come before files
                -- by putting them in a completely different score range
                if entry.is_buffer then
                  -- Buffers: score range [-2000000, -1000000]
                  -- Lower score = better match = appears first
                  return -2000000 + score
                else
                  -- Files: score range [0, 1000000]
                  -- This ensures even the WORST matching buffer appears before the BEST matching file
                  return score
                end
              end,
              highlighter = function(_, prompt, display)
                return default_sorter:highlighter(prompt, display)
              end,
            })
            
            -- Prepare all entries
            local results = {}
            
            -- Add open buffers first
            for idx, file in ipairs(buffer_files) do
              table.insert(results, {
                "+ " .. file,
                file = file,
                is_buffer = true,
                idx = idx,
              })
            end
            
            -- Add all other files
            for idx, file in ipairs(all_files) do
              table.insert(results, {
                "  " .. file,
                file = file,
                is_buffer = false,
                idx = idx + #buffer_files,
              })
            end
            
            local title = "Find Files"
            if hidden then title = title .. " [Hidden]" end
            if ignored then title = title .. " [Ignored]" end
            
            pickers
              .new(opts, {
                prompt_title = title,
                finder = finders.new_table({
                  results = results,
                  entry_maker = function(entry)
                    return {
                      value = entry.file,
                      display = entry[1],
                      ordinal = entry.file,
                      path = entry.file,
                      is_buffer = entry.is_buffer,
                      idx = entry.idx,
                    }
                  end,
                }),
                sorter = custom_sorter,
                previewer = nil,
                attach_mappings = function(prompt_bufnr, map)
                  actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    if selection then
                      vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
                    end
                  end)
                  
                  -- S-i to toggle hidden files
                  map("i", "<S-i>", function()
                    actions.close(prompt_bufnr)
                    vim.schedule(function()
                      show_hidden = not show_hidden
                      create_picker({ hidden = show_hidden, ignored = show_ignored })
                    end)
                  end)
                  
                  -- S-h to toggle ignored files
                  map("i", "<S-h>", function()
                    actions.close(prompt_bufnr)
                    vim.schedule(function()
                      show_ignored = not show_ignored
                      create_picker({ hidden = show_hidden, ignored = show_ignored })
                    end)
                  end)
                  
                  return true
                end,
                layout_strategy = "vertical",
                layout_config = {
                  prompt_position = "top",
                  width = { 0.6, min = 80 },
                  height = 0.95,
                  preview_cutoff = 0,
                },
                sorting_strategy = "ascending",
              })
              :find()
          end
          
          create_picker()
        end,
        desc = "Find files (Cmd+P)",
      },
      {
        "<D-S-f>",
        function()
          -- Get the parent directory of the current buffer
          local current_file = vim.api.nvim_buf_get_name(0)
          local default_folder = vim.fn.fnamemodify(current_file, ":h")

          -- Prompt for folder path
          vim.ui.input({ prompt = "Search in folder: ", default = default_folder }, function(folder)
            if folder and folder ~= "" then
              require("snacks.picker").grep({
                cwd = folder,
                args = {
                  "--vimgrep",
                  "--smart-case",
                  "--hidden",
                  "--fixed-strings",
                  "--glob",
                  "!**/vendor/**",
                  "--glob",
                  "!vendor/**",
                  "--glob",
                  "!**node_modules/**",
                },
              })
            end
          end)
        end,
        desc = "Search in specific folder (Cmd+Shift+F)",
      },
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "Toggle Explorer (Snacks)",
      },
    },
  },
}
