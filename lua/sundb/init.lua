-- Sundb - Lightweight database editor for Neovim

local M = {}

function M.setup()
  local ui = require("sundb.ui")
  local state = require("sundb.state")

  -- Commands
  vim.api.nvim_create_user_command("Sundb", function()
    ui.toggle()
  end, { desc = "Toggle Sundb" })

  vim.api.nvim_create_user_command("SundbConnect", function(opts)
    local env_name = opts.args
    if env_name == "" then
      vim.ui.select(require("sundb.connection").get_env_names(), {
        prompt = "Select environment:",
      }, function(choice)
        if choice then
          state.state.active_env = choice
          local env_config = require("sundb.connection").get_env_config(choice)
          if env_config and env_config.default_database then
            state.state.active_db = env_config.default_database
          end
          vim.notify("Sundb: connected to " .. choice, vim.log.levels.INFO)
        end
      end)
    else
      state.state.active_env = env_name
      local env_config = require("sundb.connection").get_env_config(env_name)
      if env_config and env_config.default_database then
        state.state.active_db = env_config.default_database
      end
      vim.notify("Sundb: connected to " .. env_name, vim.log.levels.INFO)
    end
  end, { nargs = "?", desc = "Connect to environment" })

  vim.api.nvim_create_user_command("SundbQuery", function(opts)
    local sql = opts.args
    if sql == "" then
      return
    end
    local connection = require("sundb.connection")
    local results = require("sundb.results")
    local log = require("sundb.log")
    connection.execute(sql, function(result, err, elapsed)
      if err then
        log.add(state.state.active_env, state.state.active_db, sql, elapsed or 0, 0, true)
        vim.notify("Sundb: " .. err, vim.log.levels.ERROR)
        return
      end
      log.add(state.state.active_env, state.state.active_db, sql, elapsed, result.row_count, false)
      if state.state.is_open then
        results.show(result, state.state.active_env, state.state.active_db)
      end
    end)
  end, { nargs = "+", desc = "Execute SQL query" })
end

function M.toggle()
  require("sundb.ui").toggle()
end

function M.open()
  require("sundb.ui").open()
end

function M.close()
  require("sundb.ui").close()
end

return M
