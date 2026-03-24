-- Sundb SQL editor with query block detection

local state = require("sundb.state")
local connection = require("sundb.connection")
local results = require("sundb.results")
local log = require("sundb.log")

local M = {}

-- SQL keywords for autocomplete
local sql_keywords = {
  "SELECT", "FROM", "WHERE", "AND", "OR", "NOT", "IN", "LIKE",
  "ORDER", "BY", "GROUP", "HAVING", "LIMIT", "OFFSET",
  "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE",
  "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "CROSS", "ON",
  "CREATE", "ALTER", "DROP", "TABLE", "INDEX", "VIEW",
  "AS", "DISTINCT", "COUNT", "SUM", "AVG", "MAX", "MIN",
  "ASC", "DESC", "NULL", "IS", "BETWEEN", "EXISTS",
  "CASE", "WHEN", "THEN", "ELSE", "END",
  "UNION", "ALL", "EXCEPT", "INTERSECT",
  "PRIMARY", "KEY", "FOREIGN", "REFERENCES",
  "IF", "DATABASE", "USE", "SHOW", "DESCRIBE", "EXPLAIN",
  "CONCAT", "SUBSTRING", "REPLACE", "TRIM", "LOWER", "UPPER",
  "NOW", "DATE", "COALESCE", "IFNULL", "CAST",
  "BOOLEAN", "INT", "INTEGER", "VARCHAR", "TEXT", "DATETIME", "TIMESTAMP",
  "TRUE", "FALSE", "DEFAULT", "AUTO_INCREMENT", "NOT NULL",
}

function M.get_completions(findstart, base)
  if findstart == 1 then
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local start = col
    while start > 0 and line:sub(start, start):match("[%w_.]") do
      start = start - 1
    end
    return start
  end

  local items = {}
  local base_upper = base:upper()
  local base_lower = base:lower()

  -- SQL keywords
  for _, kw in ipairs(sql_keywords) do
    if kw:sub(1, #base_upper) == base_upper then
      table.insert(items, { word = kw:lower(), kind = "[K]", menu = "keyword" })
    end
  end

  -- Table and column names from sidebar tree
  local tree = state.state.sidebar.tree or {}
  for _, env_node in ipairs(tree) do
    for _, db_node in ipairs(env_node.children or {}) do
      for _, tbl_node in ipairs(db_node.children or {}) do
        if tbl_node.name:lower():sub(1, #base_lower) == base_lower then
          table.insert(items, { word = tbl_node.name, kind = "[T]", menu = db_node.name })
        end
        for _, col_node in ipairs(tbl_node.children or {}) do
          if col_node.name:lower():sub(1, #base_lower) == base_lower then
            local col_type = (col_node.meta and col_node.meta.col_type) or ""
            table.insert(items, { word = col_node.name, kind = "[C]", menu = tbl_node.name .. " " .. col_type })
          end
        end
      end
    end
  end

  return items
end

-- Find the nearest SQL statement at cursor position
-- Returns: { sql = "...", stmt_end_line = N } or nil
function M.get_query_at_cursor()
  local buf = state.state.editor.buf
  if not state.valid_buf(buf) then
    return nil
  end

  local cursor = vim.api.nvim_win_get_cursor(state.state.editor.win)
  local cursor_line = cursor[1] -- 1-indexed
  local total_lines = vim.api.nvim_buf_line_count(buf)
  local all_lines = vim.api.nvim_buf_get_lines(buf, 0, total_lines, false)

  -- Find block boundaries (empty lines or start/end of buffer)
  local block_start = cursor_line
  while block_start > 1 do
    local line = all_lines[block_start - 1]
    if not line or line:match("^%s*$") then
      break
    end
    block_start = block_start - 1
  end

  local block_end = cursor_line
  while block_end < total_lines do
    local line = all_lines[block_end + 1]
    if not line or line:match("^%s*$") then
      break
    end
    block_end = block_end + 1
  end

  -- Extract block text
  local block_lines = {}
  for i = block_start, block_end do
    table.insert(block_lines, all_lines[i])
  end
  local block_text = table.concat(block_lines, "\n")

  -- Parse statements by semicolons
  local statements = M.split_statements(block_text)
  if #statements == 0 then
    return nil
  end

  -- Find which statement the cursor is in
  local cursor_offset_in_block = 0
  for i = block_start, cursor_line - 1 do
    cursor_offset_in_block = cursor_offset_in_block + #all_lines[i] + 1
  end
  cursor_offset_in_block = cursor_offset_in_block + cursor[2]

  local running_pos = 0
  for _, stmt in ipairs(statements) do
    local stmt_end_pos = running_pos + #stmt.raw
    if cursor_offset_in_block >= running_pos and cursor_offset_in_block <= stmt_end_pos then
      -- Calculate the actual line number where this statement ends
      local chars_counted = 0
      local end_line = block_start
      for i = block_start, block_end do
        chars_counted = chars_counted + #all_lines[i] + 1
        if chars_counted >= stmt_end_pos then
          end_line = i
          break
        end
      end
      return { sql = stmt.sql, stmt_end_line = end_line }
    end
    running_pos = stmt_end_pos
  end

  -- Fallback: return last statement
  local last = statements[#statements]
  return { sql = last.sql, stmt_end_line = block_end }
end

function M.split_statements(text)
  local statements = {}
  local current = ""
  local in_string = false
  local string_char = nil

  for i = 1, #text do
    local c = text:sub(i, i)
    if in_string then
      current = current .. c
      if c == string_char then
        -- Count consecutive backslashes before this quote
        local num_bs = 0
        local j = i - 1
        while j >= 1 and text:sub(j, j) == "\\" do
          num_bs = num_bs + 1
          j = j - 1
        end
        -- Even number of backslashes means the quote is not escaped
        if num_bs % 2 == 0 then
          in_string = false
        end
      end
    elseif not in_string and (c == "'" or c == '"') then
      in_string = true
      string_char = c
      current = current .. c
    elseif c == ";" then
      local trimmed = current:match("^%s*(.-)%s*$")
      if trimmed and trimmed ~= "" then
        table.insert(statements, { sql = trimmed, raw = current .. ";" })
      end
      current = ""
    else
      current = current .. c
    end
  end

  -- Handle last statement without semicolon
  local trimmed = current:match("^%s*(.-)%s*$")
  if trimmed and trimmed ~= "" then
    table.insert(statements, { sql = trimmed, raw = current })
  end

  return statements
end

function M.execute_at_cursor()
  local query_info = M.get_query_at_cursor()
  if not query_info then
    vim.notify("Sundb: no query at cursor", vim.log.levels.WARN)
    return
  end

  local sql = query_info.sql
  local stmt_end_line = query_info.stmt_end_line

  -- Auto LIMIT for SELECT without LIMIT
  local auto_limited = false
  if state.state.auto_limit then
    local upper = sql:upper()
    if upper:match("^%s*SELECT") and not upper:match("LIMIT%s+%d+") then
      sql = sql .. " LIMIT 10"
      auto_limited = true
    end
  end

  local env = state.state.active_env
  local db = state.state.active_db

  if not env then
    vim.notify("Sundb: no active environment. Expand an environment in the sidebar first.", vim.log.levels.WARN)
    return
  end

  -- Show virtual text indicator for auto LIMIT
  if auto_limited then
    local buf = state.state.editor.buf
    local limit_ns = vim.api.nvim_create_namespace("sundb_auto_limit")
    vim.api.nvim_buf_clear_namespace(buf, limit_ns, 0, -1)
    vim.api.nvim_buf_set_extmark(buf, limit_ns, stmt_end_line - 1, 0, {
      virt_text = { { " +LIMIT 10", "Comment" } },
      virt_text_pos = "eol",
    })
    vim.defer_fn(function()
      if state.valid_buf(buf) then
        vim.api.nvim_buf_clear_namespace(buf, limit_ns, 0, -1)
      end
    end, 3000)
  end

  connection.execute(sql, function(result, err, elapsed)
    if err then
      log.add(env, db, sql, elapsed or 0, 0, true)
      results.show_error_inline(err, env, db, elapsed, stmt_end_line)
      return
    end
    log.add(env, db, sql, elapsed, result.row_count, false)
    results.show_inline(result, env, db, stmt_end_line)
  end)
end

function M.setup_buf(buf)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "buflisted", false)
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "sql")
  vim.api.nvim_buf_set_name(buf, "sundb://editor")

  -- Keymaps
  vim.keymap.set("n", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    results.focus_nearest(cursor[1])
  end, { buffer = buf, desc = "Focus result float" })
  vim.keymap.set("n", "<D-CR>", function()
    M.execute_at_cursor()
  end, { buffer = buf, desc = "Execute query" })
  vim.keymap.set("i", "<D-CR>", function()
    vim.cmd("stopinsert")
    M.execute_at_cursor()
  end, { buffer = buf, desc = "Execute query" })
  vim.keymap.set("n", "<C-CR>", function()
    M.execute_at_cursor()
  end, { buffer = buf, desc = "Execute query" })
  vim.keymap.set("i", "<C-CR>", function()
    vim.cmd("stopinsert")
    M.execute_at_cursor()
  end, { buffer = buf, desc = "Execute query" })
end

return M
