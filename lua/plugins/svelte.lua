return {
  -- Svelte LSP setup
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.svelte = {
        capabilities = {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = true,
            },
          },
        },
        settings = {
          svelte = {
            plugin = {
              html = { completions = { enable = true, emmet = true } },
              svelte = { completions = { enable = true } },
              css = { completions = { enable = true } },
            },
          },
        },
      }
      return opts
    end,
  },
  
  -- Auto detect Svelte files
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.filetype.add({
        extension = {
          svelte = "svelte",
        },
        pattern = {
          [".*%.svelte"] = "svelte",
        },
      })
      return opts
    end,
  },
}
