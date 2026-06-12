return {
  -- TypeScript/React LSP
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      
      -- TypeScript Language Server
      opts.servers.ts_ls = {
        -- Load tsconfig "plugins" (e.g. Next.js typed routes / RSC checks).
        -- ts_ls doesn't pick these up from tsconfig.json on its own.
        on_new_config = function(new_config, new_root_dir)
          local next_pkg = vim.fs.joinpath(new_root_dir, "node_modules", "next")
          if vim.fn.isdirectory(next_pkg) == 1 then
            new_config.init_options = new_config.init_options or {}
            new_config.init_options.plugins = new_config.init_options.plugins or {}
            table.insert(new_config.init_options.plugins, {
              name = "next",
              location = next_pkg,
              languages = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
            })
          end
        end,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
          },
        },
      }
      
      -- ESLint
      opts.servers.eslint = {
        settings = {
          workingDirectory = { mode = "auto" },
        },
      }
      
      -- Tailwind CSS
      opts.servers.tailwindcss = {
        filetypes = {
          "html",
          "css",
          "scss",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "svelte",
        },
      }
      
      return opts
    end,
  },
  
  -- Auto detect JSX/TSX files
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.filetype.add({
        extension = {
          jsx = "javascriptreact",
          tsx = "typescriptreact",
        },
      })
      return opts
    end,
  },
}
