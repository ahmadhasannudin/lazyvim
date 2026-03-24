-- Sundb MySQL connection via CLI

local state = require("sundb.state")

local M = {}

function M.load_config()
  local config_path = vim.fn.getcwd() .. "/.sundb.json"
  if vim.fn.filereadable(config_path) ~= 1 then
    return nil
  end
  local content = table.concat(vim.fn.readfile(config_path), "\n")
  local ok, config = pcall(vim.fn.json_decode, content)
  if not ok or not config then
    vim.notify("Sundb: invalid .sundb.json", vim.log.levels.ERROR)
    return nil
  end
  state.state.config = config
  return config
end

function M.get_env_config(env_name)
  local config = state.state.config or M.load_config()
  if not config or not config.environments then
    return nil
  end
  return config.environments[env_name]
end

function M.get_env_names()
  local config = state.state.config or M.load_config()
  if not config or not config.environments then
    return {}
  end
  local names = {}
  for name, _ in pairs(config.environments) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

local MYSQL_PATHS = {
  "mysql",
  "/opt/homebrew/opt/mysql-client/bin/mysql",
  "/usr/local/opt/mysql-client/bin/mysql",
  "/usr/local/bin/mysql",
  "/opt/homebrew/bin/mysql",
}

local function find_mysql()
  for _, path in ipairs(MYSQL_PATHS) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end
  return nil
end

local function build_mysql_cmd(env_config, database, sql)
  local mysql_bin = find_mysql()
  if not mysql_bin then
    return nil, "mysql not found. Install with: brew install mysql-client"
  end
  local args = { mysql_bin, "--batch" }
  if env_config.host then
    table.insert(args, "-h")
    table.insert(args, env_config.host)
  end
  if env_config.port then
    table.insert(args, "-P")
    table.insert(args, tostring(env_config.port))
  end
  if env_config.user then
    table.insert(args, "-u")
    table.insert(args, env_config.user)
  end
  if env_config.password and env_config.password ~= "" then
    table.insert(args, "-p" .. env_config.password)
  end
  local db = database or env_config.default_database
  if db then
    table.insert(args, db)
  end
  table.insert(args, "-e")
  table.insert(args, sql)
  return args
end

-- MySQL --batch (without --raw) escapes special chars: \n, \t, \\, \0
-- We unescape them back to real values for display
local function unescape(s)
  -- Wrap in () to discard the gsub count return value
  return (s:gsub("\\(.)", function(c)
    local map = { n = "\n", t = "\t", r = "\r", ["0"] = "\0", ["\\"] = "\\" }
    return map[c] or c
  end))
end

local function split_tabs(s)
  local cols = {}
  local pos = 1
  while pos <= #s + 1 do
    local tab_pos = s:find("\t", pos, true)
    if tab_pos then
      table.insert(cols, unescape(s:sub(pos, tab_pos - 1)))
      pos = tab_pos + 1
    else
      table.insert(cols, unescape(s:sub(pos)))
      break
    end
  end
  return cols
end

function M.parse_tsv(raw_output)
  local lines = {}
  for line in raw_output:gmatch("[^\n]+") do
    -- Strip trailing \r (CR) in case of CRLF line endings from the client
    table.insert(lines, (line:gsub("\r$", "")))
  end
  if #lines == 0 then
    return { headers = {}, rows = {} }
  end
  -- Headers are not escaped (column names), but run through split_tabs for consistency
  local headers = split_tabs(lines[1])
  local num_cols = #headers
  local rows = {}
  for i = 2, #lines do
    local row = split_tabs(lines[i])
    while #row < num_cols do
      table.insert(row, "")
    end
    table.insert(rows, row)
  end
  return { headers = headers, rows = rows }
end

function M.execute(sql, callback, opts)
  opts = opts or {}
  local env_name = opts.env or state.state.active_env
  local database = opts.database or state.state.active_db

  if not env_name then
    vim.notify("Sundb: no active environment", vim.log.levels.WARN)
    return
  end

  local env_config = M.get_env_config(env_name)
  if not env_config then
    vim.notify("Sundb: environment '" .. env_name .. "' not found", vim.log.levels.ERROR)
    return
  end

  local cmd, cmd_err = build_mysql_cmd(env_config, database, sql)
  if not cmd then
    vim.notify("Sundb: " .. cmd_err, vim.log.levels.ERROR)
    return
  end
  local stdout_chunks = {}
  local stderr_chunks = {}
  local start_time = vim.loop.hrtime()

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stdout_chunks, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr_chunks, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        local elapsed = (vim.loop.hrtime() - start_time) / 1e9
        local raw = table.concat(stdout_chunks, "\n")
        local err_msg = table.concat(stderr_chunks, "\n")

        -- Filter out mysql password warning
        err_msg = err_msg:gsub(
          "%[Warning%].-Using a password on the command line interface can be insecure%.%s*",
          ""
        )

        if exit_code ~= 0 and err_msg ~= "" then
          callback(nil, err_msg, elapsed)
        else
          local result = M.parse_tsv(raw)
          result.elapsed = elapsed
          result.row_count = #result.rows
          callback(result, nil, elapsed)
        end
      end)
    end,
  })
end

return M
