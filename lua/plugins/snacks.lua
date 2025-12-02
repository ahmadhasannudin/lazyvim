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
              action = ":lua require('telescope').extensions.workspaces.workspaces({layout_strategy='vertical',layout_config={prompt_position='top',width={0.6,min=80},height=0.95,preview_cutoff=0},sorting_strategy='ascending'})",
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
          
          -- State for toggles
          local show_hidden = true
          local show_ignored = false
          
          local function create_picker(opts)
            opts = opts or {}
            local hidden = opts.hidden or show_hidden
            local ignored = opts.ignored or show_ignored
            
            -- Get open buffers sorted by most recent access time
            local open_buffers = {}
            local buffer_list = {}
            
            -- Collect all valid buffers with their last used time
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_valid(buf) then
                local name = vim.api.nvim_buf_get_name(buf)
                if name ~= "" and vim.fn.filereadable(name) == 1 then
                  local relative = vim.fn.fnamemodify(name, ":.")
                  local lastused = vim.fn.getbufinfo(buf)[1].lastused
                  table.insert(buffer_list, {
                    file = relative,
                    lastused = lastused,
                    bufnr = buf,
                  })
                end
              end
            end
            
            -- Sort by lastused (most recent first)
            table.sort(buffer_list, function(a, b)
              return a.lastused > b.lastused  -- Higher timestamp = more recent = should be first
            end)
            
            -- Extract sorted file list (REVERSE to put most recent at top)
            local buffer_files = {}
            for i = #buffer_list, 1, -1 do
              local item = buffer_list[i]
              if not open_buffers[item.file] then
                buffer_files[#buffer_files + 1] = item.file
                open_buffers[item.file] = true
              end
            end
            
            -- Build fd command
            local fd_cmd = "fd --type f --color never"
            if hidden then fd_cmd = fd_cmd .. " --hidden" end
            if not ignored then fd_cmd = fd_cmd .. " --exclude .git --exclude node_modules --exclude vendor" end
            
            -- Collect all files (exclude already open buffers)
            local all_files = {}
            local handle = io.popen(fd_cmd)
            if handle then
              for line in handle:lines() do
                if not open_buffers[line] then
                  all_files[#all_files + 1] = line
                end
              end
              handle:close()
            end
            
            -- Custom sorter: matched buffers first, then matched files
            local default_sorter = conf.file_sorter({})
            local custom_sorter = sorters.Sorter:new({
              scoring_function = function(_, prompt, line, entry)
                if not prompt or prompt == "" then
                  return entry.is_buffer and (-1000000 - entry.idx) or entry.idx
                end
                
                local score = default_sorter:scoring_function(prompt, line)
                
                -- Filter out non-matches
                if score == -1 or score > 1000000 then
                  return -1
                end
                
                -- Buffers in range [-2000000, -1000000], files in [0, 1000000]
                return entry.is_buffer and (-2000000 + score) or score
              end,
              highlighter = function(_, prompt, display)
                return default_sorter:highlighter(prompt, display)
              end,
            })
            
            -- Prepare entries
            local results = {}
            local n_buffers = #buffer_files
            
            for idx, file in ipairs(buffer_files) do
              results[#results + 1] = {
                display = "+ " .. file,
                file = file,
                is_buffer = true,
                idx = idx,
              }
            end
            
            for idx, file in ipairs(all_files) do
              results[#results + 1] = {
                display = "  " .. file,
                file = file,
                is_buffer = false,
                idx = idx + n_buffers,
              }
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
                      display = entry.display,
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
