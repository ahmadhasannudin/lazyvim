return {
  -- GitHub Copilot
  -- check when Checck<Esc>
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
        vim.keymap.set("i", "<Esc>", function()
          local blink = package.loaded["blink.cmp"]
          
          -- Check if blink.cmp menu is visible and close it
          if blink and blink.windows and blink.windows.autocomplete and blink.windows.autocomplete:is_open() then
            blink.hide()
            return ""
          end

          -- Check if there's a Copilot suggestion and dismiss it
          local suggestion = vim.fn["copilot#GetDisplayedSuggestion"]()
          if suggestion.text ~= "" then
            vim.fn["copilot#Dismiss"]()
            return ""
          end

          -- Check if snippet is active
          if vim.snippet and vim.snippet.active() then
            vim.snippet.stop()
            return ""
          end

          -- Default: go to normal mode
          return "<Esc>"
        end, { expr = true, silent = true, replace_keycodes = false })
      end, 100)

      -- Optional: Use Ctrl-J as alternative accept
      vim.keymap.set("i", "<C-J>", 'copilot#Accept("<CR>")', { expr = true, silent = true })
    end,
  },
}
