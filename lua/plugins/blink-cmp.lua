return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = opts.keymap or {}
      opts.keymap.preset = "none"  -- Disable all default keymaps
      
      -- Only set the keymaps we want
      opts.keymap["<C-n>"] = { "select_next", "fallback" }
      opts.keymap["<C-p>"] = { "select_prev", "fallback" }
      opts.keymap["<CR>"] = { "accept", "fallback" }
      opts.keymap["<C-space>"] = { "show", "hide" }
      opts.keymap["<C-e>"] = { "hide" }
      
      -- Explicitly disable Tab, Shift-Tab, and Esc
      opts.keymap["<Tab>"] = {}
      opts.keymap["<S-Tab>"] = {}
      opts.keymap["<Esc>"] = {}
      
      -- Fix snippet parsing for LSP servers with malformed snippets
      opts.snippets = opts.snippets or {}
      opts.snippets.expand = function(snippet)
        -- Clean up malformed escape sequences
        local cleaned = snippet:gsub("\\(%$)", "%1")
        vim.snippet.expand(cleaned)
      end
      
      -- Sundb SQL completion source
      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.sundb = {
        name = "Sundb",
        module = "sundb.completion",
        score_offset = 10,
      }
      opts.sources.default = opts.sources.default or { "lsp", "path", "snippets", "buffer" }
      -- Add sundb source to defaults so it's always available (it self-disables outside sundb)
      local has_sundb = false
      for _, s in ipairs(opts.sources.default) do
        if s == "sundb" then has_sundb = true; break end
      end
      if not has_sundb then
        table.insert(opts.sources.default, "sundb")
      end

      return opts
    end,
  },
}

