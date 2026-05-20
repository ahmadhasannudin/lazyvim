return {
  {
    "mg979/vim-visual-multi",
    branch = "master",
    init = function()
      -- VS Code-style keymaps
      vim.g.VM_maps = {
        ["Find Under"] = "<D-d>", -- Cmd + D (Mac) - Add next occurrence
        ["Find Subword Under"] = "<D-d>", -- same for sub-words
        ["Skip Region"] = "<D-k>", -- Cmd + K - Skip current and find next
        ["Add Cursor Down"] = "<D-Down>",
        ["Add Cursor Up"] = "<D-Up>",
        ["Visual Cursors"] = "<D-S-i>", -- Cmd + Shift + I - Cursors at start of each line
        ["Visual Add"] = "v", -- Press v to start visual mode on all cursors
        ["Visual Find"] = "v", -- Visual mode works across all cursors
        ["Switch Mode"] = "v", -- Toggle extend/cursor mode with v
      }

      -- Optional tweaks
      vim.g.VM_mouse_mappings = 1
      vim.g.VM_show_warnings = 0
      vim.g.VM_silent_exit = 1
      
      -- Start VM immediately when using Cmd+D
      vim.g.VM_default_mappings = 1

      vim.api.nvim_create_autocmd("User", {
        pattern = "visual_multi_exit",
        callback = function()
          -- move cursor to the last visual-multi position instead of restoring old one
          vim.cmd("normal! gv") -- reselect last visual area
          vim.cmd("normal! `<") -- move to start of selection
        end,
      })

      -- VSCode-style distribute paste while VM is active. Bind paste keys
      -- only inside VM-buffer-local maps so behaviour outside VM is untouched.
      vim.api.nvim_create_autocmd("User", {
        pattern = "visual_multi_mappings",
        callback = function()
          local smart = require("config.vm_smart_paste")
          local buf = vim.api.nvim_get_current_buf()
          local map_opts = { buffer = buf, silent = true, nowait = true }

          vim.keymap.set("n", "p", function()
            smart.paste({ before = false })
          end, vim.tbl_extend("force", map_opts, { desc = "VM smart paste (after)" }))

          vim.keymap.set("n", "P", function()
            smart.paste({ before = true })
          end, vim.tbl_extend("force", map_opts, { desc = "VM smart paste (before)" }))

          vim.keymap.set("n", "<D-v>", function()
            smart.paste({ before = false, register = "+" })
          end, vim.tbl_extend("force", map_opts, { desc = "VM smart paste from system clipboard" }))
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "visual_multi_exit",
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          pcall(vim.keymap.del, "n", "p", { buffer = buf })
          pcall(vim.keymap.del, "n", "P", { buffer = buf })
          pcall(vim.keymap.del, "n", "<D-v>", { buffer = buf })
        end,
      })
    end,
    keys = {
      {
        "<D-d>",
        function()
          vim.cmd([[call vm#commands#find_under(0, 1)]])
        end,
        mode = { "n", "v" },
        desc = "Add cursor to next match (Cmd+D)",
      },
      {
        "<D-L>",
        function()
          local mode = vim.fn.mode()
          if mode == "v" or mode == "V" or mode == "\22" then
            vim.cmd([[execute "normal! \<Plug>(VM-Visual-All)"]])
          else
            vim.cmd([[execute "normal! \<Plug>(VM-Select-All)"]])
          end
        end,
        mode = { "n", "v" },
        desc = "Select all occurrences (Cmd+Shift+L)",
      },
      {
        "gC",
        function()
          vim.cmd([[execute "normal! \<Plug>(VM-Visual-Cursors)"]])
        end,
        mode = { "v" },
        desc = "Add cursors at start of each selected line (leader mc)",
      },
    },
  },
}

