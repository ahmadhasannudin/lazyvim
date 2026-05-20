-- Sundb blink-cmp completion source

local sql_keywords = {
  "SELECT", "FROM", "WHERE", "AND", "OR", "NOT", "IN", "LIKE",
  "ORDER BY", "GROUP BY", "HAVING", "LIMIT", "OFFSET",
  "INSERT INTO", "VALUES", "UPDATE", "SET", "DELETE FROM",
  "JOIN", "LEFT JOIN", "RIGHT JOIN", "INNER JOIN", "CROSS JOIN", "ON",
  "CREATE TABLE", "ALTER TABLE", "DROP TABLE", "CREATE INDEX", "CREATE VIEW",
  "AS", "DISTINCT", "COUNT", "SUM", "AVG", "MAX", "MIN",
  "ASC", "DESC", "NULL", "IS NULL", "IS NOT NULL", "BETWEEN", "EXISTS",
  "CASE", "WHEN", "THEN", "ELSE", "END",
  "UNION", "UNION ALL", "SHOW DATABASES", "SHOW TABLES", "DESCRIBE", "EXPLAIN",
  "CONCAT", "SUBSTRING", "REPLACE", "TRIM", "LOWER", "UPPER", "LENGTH",
  "NOW", "DATE", "COALESCE", "IFNULL", "NULLIF", "CAST", "CONVERT",
  "ROUND", "FLOOR", "CEIL", "ABS", "MOD",
  "TRUE", "FALSE", "DEFAULT", "AUTO_INCREMENT",
  "VARCHAR", "INT", "INTEGER", "BIGINT", "BOOLEAN", "TEXT", "LONGTEXT",
  "DATETIME", "TIMESTAMP", "FLOAT", "DECIMAL",
}

local KIND = vim.lsp.protocol.CompletionItemKind

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  local ok, state = pcall(require, "sundb.state")
  if not ok then return false end
  local cur_buf = vim.api.nvim_get_current_buf()
  -- Active for any sundb tab buffer
  for _, tab in ipairs(state.state.tabs or {}) do
    if tab.buf == cur_buf then return true end
  end
  return false
end

function source:get_trigger_characters()
  return { ".", " ", "(", "`" }
end

function source:get_completions(ctx, callback)
  local empty = { is_incomplete_forward = false, is_incomplete_backward = false, items = {} }
  if not self:enabled() then callback(empty); return end

  local ok, state = pcall(require, "sundb.state")
  if not ok then callback(empty); return end

  local env_name = state.state.active_env
  local db_name  = state.state.active_db
  local key      = (env_name or "") .. "/" .. (db_name or "")
  local cached   = env_name and db_name and state.state.schema[key]

  -- If not cached yet, trigger a background fetch; return keywords now
  if env_name and db_name and (not cached or not cached.fetched) then
    local conn = require("sundb.connection")
    conn.fetch_schema(env_name, db_name, function()
      -- Schema ready – blink will call get_completions again via trigger
    end)
  end

  local items  = {}
  local word   = ctx.word or ""
  local wlower = word:lower()
  local wupper = word:upper()

  -- SQL keywords
  for _, kw in ipairs(sql_keywords) do
    if word == "" or kw:upper():sub(1, #wupper) == wupper then
      table.insert(items, {
        label       = kw:lower(),
        labelDetails = { description = "keyword" },
        kind        = KIND.Keyword,
        insertText  = kw:lower(),
        sortText    = "3_" .. kw,
      })
    end
  end

  -- Tables + columns from schema cache (fast path)
  local tables = cached and cached.tables or {}
  for _, tbl in ipairs(tables) do
    if word == "" or tbl.name:lower():sub(1, #wlower) == wlower then
      table.insert(items, {
        label        = tbl.name,
        labelDetails = { description = db_name },
        kind         = KIND.Module,
        insertText   = tbl.name,
        sortText     = "1_" .. tbl.name,
      })
    end
    for _, col in ipairs(tbl.columns or {}) do
      if word == "" or col.name:lower():sub(1, #wlower) == wlower then
        table.insert(items, {
          label        = col.name,
          labelDetails = { description = tbl.name .. "  " .. (col.type or "") },
          kind         = KIND.Field,
          insertText   = col.name,
          sortText     = "2_" .. col.name,
        })
      end
    end
  end

  callback({
    is_incomplete_forward  = false,
    is_incomplete_backward = false,
    items = items,
  })
end

return source
