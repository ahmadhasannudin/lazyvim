return {
  -- GitHub Copilot
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      -- Disable default Tab mapping
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true

      -- Set up keymaps after a delay to ensure they override everything
      vim.defer_fn(function()
        -- Custom Tab behavior with priority: 1. Snippet, 2. Copilot, 3. Normal Tab
        vim.keymap.set("i", "<Tab>", function()
          -- Priority 1: Check if blink.cmp menu is visible (snippet/autocomplete)
          local blink = package.loaded["blink.cmp"]
          if blink then
            local is_visible = false
            if blink.is_visible and blink.is_visible() then
              is_visible = true
            elseif blink.windows and blink.windows.autocomplete and blink.windows.autocomplete.win then
              if type(blink.windows.autocomplete.win) == "number" and vim.api.nvim_win_is_valid(blink.windows.autocomplete.win) then
                is_visible = true
              end
            end
            
            if is_visible then
              -- Accept the selected item in blink.cmp
              if blink.accept then
                blink.accept()
              elseif blink.windows and blink.windows.autocomplete and blink.windows.autocomplete.accept then
                blink.windows.autocomplete.accept()
              end
              return
            end
          end

          -- Priority 2: Check if Copilot has a suggestion (only if no snippet menu)
          if vim.fn["copilot#GetDisplayedSuggestion"]().text ~= "" then
            vim.api.nvim_feedkeys(vim.fn["copilot#Accept"](""), "n", true)
            return
          end

          -- Priority 3: Fallback to regular Tab
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end, { silent = true })

        -- Custom Shift-Tab for snippet backward jump
        vim.keymap.set("i", "<S-Tab>", function()
          if vim.snippet and vim.snippet.active({ direction = -1 }) then
            vim.snippet.jump(-1)
            return
          end
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
        end, { silent = true })

        -- Custom Esc behavior in insert mode - stay in insert mode when dismissing
        -- Priority: 1. Snippet/Autocomplete menu, 2. Copilot suggestion, 3. Normal mode
        vim.keymap.set("i", "<Esc>", function()
          -- Check if blink.cmp menu is visible and close it (highest priority - "snippet")
          local blink_cmp = package.loaded["blink.cmp"]
          if blink_cmp then
            local is_visible = false
            -- Try different ways to check if menu is visible
            if blink_cmp.is_visible and blink_cmp.is_visible() then
              is_visible = true
            elseif blink_cmp.windows and blink_cmp.windows.autocomplete then
              if type(blink_cmp.windows.autocomplete.win) == "number" and vim.api.nvim_win_is_valid(blink_cmp.windows.autocomplete.win) then
                is_visible = true
              end
            end
            
            if is_visible then
              if blink_cmp.hide then
                blink_cmp.hide()
              elseif blink_cmp.windows and blink_cmp.windows.autocomplete and blink_cmp.windows.autocomplete.close then
                blink_cmp.windows.autocomplete.close()
              end
              return
            end
          end

          -- Then check if there's a Copilot suggestion and dismiss it
          local suggestion = vim.fn["copilot#GetDisplayedSuggestion"]()
          if suggestion.text ~= "" then
            vim.fn["copilot#Dismiss"]()
            return
          end

          -- If none are active, go to normal mode
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
        end, { silent = true })
      end, 100)

      -- Optional: Use Ctrl-J as alternative accept
      vim.keymap.set("i", "<C-J>", 'copilot#Accept("<CR>")', { expr = true, silent = true })
    end,
  },
}
