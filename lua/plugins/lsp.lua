return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Enable PHP language server
      opts.servers = opts.servers or {}
      opts.servers.intelephense = {
        filetypes = { "php" },
      }
      -- Ensure root_dir respects workspace
      local util = require("lspconfig.util")
      local default_root_dir = util.root_pattern(".git", "package.json", ".project-root")
      
      -- Override root_dir for all servers to use workspace if available
      for server_name, server_config in pairs(opts.servers or {}) do
        if server_name ~= "*" then
          local original_root_dir = server_config.root_dir or default_root_dir
          server_config.root_dir = function(fname)
            -- First, check if we're in a workspace
            local ok, workspaces = pcall(require, "workspaces")
            if ok then
              local workspace_path = workspaces.path()
              if workspace_path and workspace_path ~= "" then
                return workspace_path
              end
            end
            -- Fallback to original root_dir detection
            if type(original_root_dir) == "function" then
              return original_root_dir(fname)
            end
            return original_root_dir
          end
        end
      end

      -- Global keys that apply to all servers
      opts.servers = opts.servers or {}
      opts.servers["*"] = {
        keys = {
          { "K", false }, -- Disable K hover for all servers
          { "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "Goto Definition", has = "definition" }, -- Override snacks picker
        },
      }
      
      return opts
    end,
  },
}
