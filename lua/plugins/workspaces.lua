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
          open_pre = function()
            -- Set global flag to prevent toggleterm from opening
            vim.g.switching_workspace = true
            
            -- Hide terminal windows (but keep buffers alive for this workspace)
            local current_workspace = vim.fn.getcwd()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
                -- Tag this terminal with its workspace
                vim.b[buf].terminal_workspace = current_workspace
                
                -- Close windows showing this terminal
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
                    pcall(vim.api.nvim_win_close, win, true)
                  end
                end
              end
            end
            
            -- Save current session before switching
            local ok, persistence = pcall(require, "persistence")
            if ok then
              persistence.save()
            end
          end,
          open = function(name, path)
            -- Hide all terminal windows (keep buffers for their workspaces)
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
                -- Close windows but keep buffer alive
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
                    pcall(vim.api.nvim_win_close, win, true)
                  end
                end
              end
            end
            
            -- Change directory (this will trigger DirChanged autocmd)
            vim.cmd("cd " .. path)
            
            -- Load session after switching workspace
            vim.schedule(function()
              local ok, persistence = pcall(require, "persistence")
              if ok then
                local session_file = persistence.current()
                if session_file and vim.fn.filereadable(session_file) == 1 then
                  -- Close all non-terminal buffers before loading session
                  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype ~= "terminal" then
                      vim.api.nvim_buf_delete(buf, { force = true })
                    end
                  end
                  
                  -- Small delay to ensure buffers are closed
                  vim.defer_fn(function()
                    persistence.load()
                    
                    -- After loading session, hide terminals from other workspaces
                    vim.defer_fn(function()
                      local new_workspace = vim.fn.getcwd()
                      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
                          local buf_workspace = vim.b[buf].terminal_workspace
                          -- If terminal belongs to different workspace, hide it
                          if buf_workspace and buf_workspace ~= new_workspace then
                            for _, win in ipairs(vim.api.nvim_list_wins()) do
                              if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
                                pcall(vim.api.nvim_win_close, win, true)
                              end
                            end
                          end
                        end
                      end
                    end, 50)
                    
                    -- Restart LSP clients after session load
                    vim.defer_fn(function()
                      -- Stop all LSP clients
                      for _, client in pairs(vim.lsp.get_active_clients()) do
                        client.stop()
                      end
                      
                      -- Restart LSP for current buffer
                      vim.defer_fn(function()
                        vim.cmd("edit")
                      end, 100)
                    end, 250)
                    
                    vim.notify("✓ Loaded session: " .. name, vim.log.levels.INFO)
                    
                    -- Clear workspace switching flag
                    vim.defer_fn(function()
                      vim.g.switching_workspace = false
                    end, 100)
                  end, 50)
                else
                  -- No session file, close current buffers and open explorer
                  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype ~= "terminal" then
                      vim.api.nvim_buf_delete(buf, { force = true })
                    end
                  end
                  vim.defer_fn(function()
                    vim.notify("⚠ " .. name .. " (no session found)", vim.log.levels.WARN)
                    vim.cmd("Neotree")
                    
                    -- Clear workspace switching flag
                    vim.defer_fn(function()
                      vim.g.switching_workspace = false
                    end, 100)
                  end, 50)
                end
              end
              
              -- Reload SFTP config for new workspace
              local sftp = require("config.sftp")
              sftp.reload_config()
            end)
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
      dir = vim.fn.stdpath("state") .. "/sessions/",
      -- Don't save terminal buffers in sessions
      pre_save = function()
        -- Close terminal windows before saving (but keep buffers)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
            -- Close windows with this buffer
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
                pcall(vim.api.nvim_win_close, win, true)
              end
            end
          end
        end
      end,
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
        "<leader>qS",
        function()
          require("persistence").save()
          vim.notify("✓ Session saved", vim.log.levels.INFO)
        end,
        desc = "Save Session",
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
