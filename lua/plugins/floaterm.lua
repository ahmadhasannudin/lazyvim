return {
  "nvzone/floaterm",
  dependencies = "nvzone/volt",
  cmd = "FloatermToggle",
  opts = {
    border = true,
    size = { h = 80, w = 90 },
    mappings = {
      sidebar = function(buf)
        -- Override default 'a' and add ta for creating terminal
        vim.keymap.set("n", "a", function()
          require("floaterm.api").new_term()
        end, { buffer = buf, desc = "Add new terminal" })
        
        vim.keymap.set("n", "ta", function()
          require("floaterm.api").new_term()
        end, { buffer = buf, desc = "Add new terminal" })
        
        -- Override default 'e' and add te for editing
        vim.keymap.set("n", "e", function()
          require("floaterm.api").edit_name()
        end, { buffer = buf, desc = "Edit terminal name" })
        
        vim.keymap.set("n", "te", function()
          require("floaterm.api").edit_name()
        end, { buffer = buf, desc = "Edit terminal name" })
        
        -- Override default 'd' and add td with confirmation
        vim.keymap.set("n", "d", function()
          local utils = require("floaterm.utils")
          local state = require("floaterm.state")
          local row = utils.get_buf_on_cursor()
          
          if row and state.terminals[row] then
            local term_name = state.terminals[row].name
            local term_buf = state.terminals[row].buf
            
            -- Close floaterm to show confirmation dialog
            vim.cmd("FloatermToggle")
            
            vim.defer_fn(function()
              vim.ui.select({"Yes", "No"}, {
                prompt = "Delete terminal '" .. term_name .. "'?",
              }, function(choice)
                if choice == "Yes" then
                  require("floaterm.api").delete_term(term_buf)
                  -- Reopen floaterm after deletion
                  vim.defer_fn(function()
                    vim.cmd("FloatermToggle")
                  end, 100)
                else
                  -- Reopen floaterm if cancelled
                  vim.cmd("FloatermToggle")
                end
              end)
            end, 100)
          end
        end, { buffer = buf, desc = "Delete terminal" })
        
        vim.keymap.set("n", "td", function()
          local utils = require("floaterm.utils")
          local state = require("floaterm.state")
          local row = utils.get_buf_on_cursor()
          
          if row and state.terminals[row] then
            local term_name = state.terminals[row].name
            local term_buf = state.terminals[row].buf
            
            -- Close floaterm to show confirmation dialog
            vim.cmd("FloatermToggle")
            
            vim.defer_fn(function()
              vim.ui.select({"Yes", "No"}, {
                prompt = "Delete terminal '" .. term_name .. "'?",
              }, function(choice)
                if choice == "Yes" then
                  require("floaterm.api").delete_term(term_buf)
                  -- Reopen floaterm after deletion
                  vim.defer_fn(function()
                    vim.cmd("FloatermToggle")
                  end, 100)
                else
                  -- Reopen floaterm if cancelled
                  vim.cmd("FloatermToggle")
                end
              end)
            end, 100)
          end
        end, { buffer = buf, desc = "Delete terminal" })
      end,
      term = function(buf)
        -- Exit terminal mode with jk
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], { buffer = buf, desc = "Exit terminal mode" })
        
        -- Esc in terminal mode should toggle floaterm (minimize it)
        vim.keymap.set("t", "<Esc>", "<cmd>FloatermToggle<cr>", { buffer = buf, desc = "Toggle floaterm" })
        
        -- q in normal mode should also toggle (minimize) not close session
        vim.keymap.set("n", "q", "<cmd>FloatermToggle<cr>", { buffer = buf, desc = "Toggle floaterm" })
        
        -- Window navigation from terminal
        vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { buffer = buf, desc = "Navigate left" })
        
        -- Cycle through terminals
        vim.keymap.set({ "t", "n" }, "<C-n>", function()
          require("floaterm.api").cycle_term_bufs("next")
        end, { buffer = buf, desc = "Next terminal" })
        
        vim.keymap.set({ "t", "n" }, "<C-p>", function()
          require("floaterm.api").cycle_term_bufs("prev")
        end, { buffer = buf, desc = "Previous terminal" })
        
        -- Create new terminal
        vim.keymap.set({ "t", "n" }, "<C-t>", function()
          require("floaterm.api").new_term()
        end, { buffer = buf, desc = "New terminal" })
        
        -- Add terminal with ta
        vim.keymap.set("t", "ta", [[<C-\><C-n>:lua require("floaterm.api").new_term()<CR>]], { buffer = buf, desc = "Add new terminal" })
        vim.keymap.set("n", "ta", function()
          require("floaterm.api").new_term()
        end, { buffer = buf, desc = "Add new terminal" })
        
        -- Edit current terminal name with te
        vim.keymap.set({ "t", "n" }, "te", function()
          local state = require("floaterm.state")
          local utils = require("floaterm.utils")
          local current_idx = utils.get_term_by_key(state.buf)
          if current_idx then
            -- Close floaterm to show input dialog
            vim.cmd("FloatermToggle")
            vim.defer_fn(function()
              vim.ui.input({ 
                prompt = "Terminal name: ",
                default = state.terminals[current_idx[1]].name
              }, function(input)
                if input and input ~= "" then
                  state.terminals[current_idx[1]].name = input
                  require("volt").redraw(state.sidebuf, "bufs")
                  vim.notify("✓ Renamed to: " .. input, vim.log.levels.INFO)
                end
                -- Reopen floaterm
                vim.defer_fn(function()
                  vim.cmd("FloatermToggle")
                end, 100)
              end)
            end, 100)
          end
        end, { buffer = buf, desc = "Rename terminal", noremap = true })
        
        -- Delete current terminal with td
        vim.keymap.set({ "t", "n" }, "td", function()
          local state = require("floaterm.state")
          local utils = require("floaterm.utils")
          local current_idx = utils.get_term_by_key(state.buf)
          if current_idx then
            local term_name = state.terminals[current_idx[1]].name
            local current_buf = state.buf
            local is_last_terminal = #state.terminals == 1
            
            -- Close floaterm first to show dialog in front
            vim.cmd("FloatermToggle")
            
            vim.defer_fn(function()
              vim.ui.select({"Yes", "No"}, {
                prompt = "Delete terminal '" .. term_name .. "'?",
              }, function(choice)
                if choice == "Yes" then
                  -- Delete the buffer
                  vim.api.nvim_buf_delete(current_buf, { force = true })
                  
                  -- Remove from terminals list
                  table.remove(state.terminals, current_idx[1])
                  
                  vim.notify("✓ Terminal '" .. term_name .. "' deleted", vim.log.levels.INFO)
                  
                  -- If it was the last terminal, reset state completely
                  if is_last_terminal then
                    state.volt_set = false
                    state.terminals = nil
                    state.buf = nil
                    state.sidebuf = nil
                    state.barbuf = nil
                    state.win = nil
                    state.barwin = nil
                    state.sidewin = nil
                    return
                  end
                  
                  -- Otherwise reopen floaterm with remaining terminals
                  vim.defer_fn(function()
                    vim.cmd("FloatermToggle")
                  end, 50)
                else
                  -- User cancelled, reopen floaterm
                  vim.defer_fn(function()
                    vim.cmd("FloatermToggle")
                  end, 50)
                end
              end)
            end, 100)
          end
        end, { buffer = buf, desc = "Delete current terminal", noremap = true })
        
        -- Terminal control mappings (pass through to shell)
        vim.keymap.set("t", "<M-BS>", "<M-BS>", { buffer = buf })
        vim.keymap.set("t", "<C-l>", "<C-l>", { buffer = buf })
        vim.keymap.set("t", "<C-u>", "<C-u>", { buffer = buf })
        vim.keymap.set("t", "<C-w>", "<C-w>", { buffer = buf })
        vim.keymap.set("t", "<C-a>", "<C-a>", { buffer = buf })
        vim.keymap.set("t", "<C-e>", "<C-e>", { buffer = buf })
        vim.keymap.set("t", "<C-r>", "<C-r>", { buffer = buf })
        vim.keymap.set("t", "<M-Left>", "<M-Left>", { buffer = buf })
        vim.keymap.set("t", "<M-Right>", "<M-Right>", { buffer = buf })
        vim.keymap.set("t", "<M-b>", "<M-b>", { buffer = buf })
        vim.keymap.set("t", "<M-f>", "<M-f>", { buffer = buf })
        
        -- Delete/terminate current terminal
        vim.keymap.set({ "t", "n" }, "tq", function()
          require("floaterm.api").delete_term()
        end, { buffer = buf, desc = "Delete current terminal" })
        
        -- Delete all terminals
        vim.keymap.set({ "t", "n" }, "tQ", function()
          local state = require("floaterm.state")
          if state.terminals and #state.terminals > 0 then
            vim.ui.select({"Yes", "No"}, {
              prompt = "Delete all " .. #state.terminals .. " terminal(s)?",
            }, function(choice)
              if choice == "Yes" then
                while state.terminals and #state.terminals > 0 do
                  require("floaterm.api").delete_term()
                end
                vim.notify("✓ All terminals deleted", vim.log.levels.INFO)
              end
            end)
          end
        end, { buffer = buf, desc = "Delete all terminals" })
      end,
    },
    terminals = function()
      local workspaces_ok, workspaces = pcall(require, "workspaces")
      local workspace_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
      
      if workspaces_ok then
        local current_dir = vim.fn.getcwd()
        local ws_list = workspaces.get()
        for _, ws in ipairs(ws_list) do
          if ws.path == current_dir then
            workspace_name = ws.name
            break
          end
        end
      end
      
      return { { name = workspace_name .. "-1" } }
    end,
  },
  config = function(_, opts)
    require("floaterm").setup(opts)
    
    -- Helper function to get workspace name
    local function get_workspace_name()
      local workspaces_ok, workspaces = pcall(require, "workspaces")
      if workspaces_ok then
        local current_dir = vim.fn.getcwd()
        local ws_list = workspaces.get()
        for _, ws in ipairs(ws_list) do
          if ws.path == current_dir then
            return ws.name
          end
        end
      end
      return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    end
    
    -- Override new_term to use workspace-based naming
    local floaterm_api = require("floaterm.api")
    local original_new_term = floaterm_api.new_term
    
    floaterm_api.new_term = function()
      local state = require("floaterm.state")
      local workspace_name = get_workspace_name()
      local next_index = state.terminals and (#state.terminals + 1) or 1
      local term_name = workspace_name .. "-" .. next_index
      
      original_new_term()
      
      -- Set the name after creating the terminal
      vim.defer_fn(function()
        if state.terminals and #state.terminals > 0 then
          state.terminals[#state.terminals].name = term_name
          if state.sidebuf and vim.api.nvim_buf_is_valid(state.sidebuf) then
            require("volt").redraw(state.sidebuf, "bufs")
          end
        end
      end, 50)
    end
    
    -- Register which-key mappings for floaterm
    local wk_ok, wk = pcall(require, "which-key")
    if wk_ok then
      -- Terminal group under leader
      wk.add({
        { "<leader>t", group = "terminal" },
        { "<leader>tt", "<cmd>FloatermToggle<cr>", desc = "Toggle terminal" },
        { "<leader>ta", desc = "Add new terminal (in floaterm)" },
        { "<leader>te", desc = "Edit terminal name (in floaterm)" },
        { "<leader>td", desc = "Delete terminal (in floaterm)" },
        { "<leader>tq", desc = "Quick delete terminal (in floaterm)" },
        { "<leader>tQ", desc = "Delete all terminals (in floaterm)" },
      })
    end
    
    -- Override toggle to handle invalid window IDs safely
    local floaterm = require("floaterm")
    local original_toggle = floaterm.toggle
    
    floaterm.toggle = function()
      local state = require("floaterm.state")
      
      -- Check if buffers or windows are invalid and reset state if needed
      local buffers_valid = (not state.sidebuf or vim.api.nvim_buf_is_valid(state.sidebuf))
        and (not state.barbuf or vim.api.nvim_buf_is_valid(state.barbuf))
        and (not state.buf or vim.api.nvim_buf_is_valid(state.buf))
      
      local windows_valid = (not state.win or vim.api.nvim_win_is_valid(state.win))
        and (not state.barwin or vim.api.nvim_win_is_valid(state.barwin))
        and (not state.sidewin or vim.api.nvim_win_is_valid(state.sidewin))
      
      -- If volt_set but buffers/windows are invalid, reset everything
      if state.volt_set and (not buffers_valid or not windows_valid) then
        state.volt_set = false
        state.terminals = nil
        state.buf = nil
        state.sidebuf = nil
        state.barbuf = nil
        state.win = nil
        state.barwin = nil
        state.sidewin = nil
        if state.bar_redraw_timer then
          pcall(function()
            state.bar_redraw_timer:stop()
            state.bar_redraw_timer:close()
          end)
          state.bar_redraw_timer = nil
        end
      end
      
      -- Even if volt_set is false, check if stale buffers exist
      if not state.volt_set then
        if state.sidebuf and not vim.api.nvim_buf_is_valid(state.sidebuf) then
          state.sidebuf = nil
        end
        if state.barbuf and not vim.api.nvim_buf_is_valid(state.barbuf) then
          state.barbuf = nil
        end
        if state.buf and not vim.api.nvim_buf_is_valid(state.buf) then
          state.buf = nil
        end
      end
      
      -- Call original toggle
      original_toggle()
    end
  end,
  keys = {
    -- Toggle terminal
    { "<C-\\>", "<cmd>FloatermToggle<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
    { "<D-t>", "<cmd>FloatermToggle<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
    
    -- Terminal group in which-key
    { "<leader>tt", "<cmd>FloatermToggle<cr>", desc = "Toggle terminal" },
  },
}
