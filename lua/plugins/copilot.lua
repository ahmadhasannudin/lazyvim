return {
  -- GitHub Copilot
  -- check for
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      -- Disable default Tab mapping
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true

      -- Set up keymaps after a delay to ensure they override everything
      vim.defer_fn(function()
        -- Custom Tab behavior: prefer snippets, fallback to Copilot
        vim.keymap.set("i", "<Tab>", function()
          -- Check if blink.cmp menu is visible
          local blink = package.loaded["blink.cmp"]
          if blink and blink.windows and blink.windows.autocomplete and blink.windows.autocomplete:is_open() then
            return "<C-n>"  -- Navigate completion menu
          end

          -- Check if snippet is active
          if vim.snippet and vim.snippet.active({ direction = 1 }) then
            return "<Cmd>lua vim.snippet.jump(1)<CR>"
          end

          -- Check if Copilot has a suggestion
          local suggestion = vim.fn["copilot#GetDisplayedSuggestion"]()
          if suggestion.text ~= "" then
            vim.fn["copilot#Accept"]("")
            return ""
          end

          -- Fallback to regular Tab
          return "<Tab>"
        end, { expr = true, silent = true, replace_keycodes = false })

        -- Custom Shift-Tab for snippet backward jump
        vim.keymap.set("i", "<S-Tab>", function()
          if vim.snippet and vim.snippet.active({ direction = -1 }) then
            return "<Cmd>lua vim.snippet.jump(-1)<CR>"
          end
          return "<S-Tab>"
        end, { expr = true, silent = true, replace_keycodes = false })

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
              return ""
            end
          end

          -- Then check if there's a Copilot suggestion and dismiss it
          local suggestion = vim.fn["copilot#GetDisplayedSuggestion"]()
          if suggestion.text ~= "" then
            vim.fn["copilot#Dismiss"]()
            return ""
          end

          -- If none are active, go to normal mode
          return vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        end, { expr = true, silent = true })
      end, 100)

      -- Optional: Use Ctrl-J as alternative accept
      vim.keymap.set("i", "<C-J>", 'copilot#Accept("<CR>")', { expr = true, silent = true })
    end,
  },
}
