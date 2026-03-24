-- Sundb blink-cmp completion source

local sql_keywords = {
  "SELECT", "FROM", "WHERE", "AND", "OR", "NOT", "IN", "LIKE", "ILIKE",
  "ORDER BY", "GROUP BY", "HAVING", "LIMIT", "OFFSET",
  "INSERT INTO", "VALUES", "UPDATE", "SET", "DELETE FROM",
  "JOIN", "LEFT JOIN", "RIGHT JOIN", "INNER JOIN", "OUTER JOIN", "CROSS JOIN", "ON",
  "CREATE TABLE", "ALTER TABLE", "DROP TABLE", "CREATE INDEX", "DROP INDEX", "CREATE VIEW",
  "AS", "DISTINCT", "COUNT", "SUM", "AVG", "MAX", "MIN",
  "ASC", "DESC", "NULL", "IS NULL", "IS NOT NULL", "IS", "BETWEEN", "EXISTS",
  "CASE", "WHEN", "THEN", "ELSE", "END",
  "UNION", "UNION ALL", "EXCEPT", "INTERSECT",
  "PRIMARY KEY", "FOREIGN KEY", "REFERENCES", "UNIQUE", "INDEX",
  "SHOW DATABASES", "SHOW TABLES", "DESCRIBE", "EXPLAIN",
  "CONCAT", "SUBSTRING", "REPLACE", "TRIM", "LOWER", "UPPER", "LENGTH",
  "NOW", "DATE", "COALESCE", "IFNULL", "NULLIF", "CAST", "CONVERT",
  "ROUND", "FLOOR", "CEIL", "ABS", "MOD",
  "TRUE", "FALSE", "DEFAULT", "AUTO_INCREMENT",
  "VARCHAR", "INT", "INTEGER", "BIGINT", "BOOLEAN", "TEXT", "LONGTEXT",
  "DATETIME", "TIMESTAMP", "DATE", "FLOAT", "DECIMAL",
}

local KIND = vim.lsp.protocol.CompletionItemKind

local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:get_completions(ctx, callback)
  local ok, state = pcall(require, "sundb.state")
  if not ok then
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
    return
  end

  -- Only active in sundb editor buffer
  local cur_buf = vim.api.nvim_get_current_buf()
  if state.state.editor.buf ~= cur_buf then
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
    return
  end

  local items = {}
  local base = ctx.word or ""
  local base_lower = base:lower()
  local base_upper = base:upper()

  -- SQL keywords
  for _, kw in ipairs(sql_keywords) do
    local kw_upper = kw:upper()
    if base == "" or kw_upper:sub(1, #base_upper) == base_upper then
      table.insert(items, {
        label = kw:lower(),
        labelDetails = { description = "keyword" },
        kind = KIND.Keyword,
        insertText = kw:lower(),
        sortText = "3_" .. kw,
      })
    end
  end

  -- Table and column names from sidebar tree
  local tree = state.state.sidebar.tree or {}
  for _, env_node in ipairs(tree) do
    for _, db_node in ipairs(env_node.children or {}) do
      for _, tbl_node in ipairs(db_node.children or {}) do
        -- Table names
        if base == "" or tbl_node.name:lower():sub(1, #base_lower) == base_lower then
          table.insert(items, {
            label = tbl_node.name,
            labelDetails = { description = db_node.name },
            kind = KIND.Module,
            insertText = tbl_node.name,
            sortText = "1_" .. tbl_node.name,
          })
        end
        -- Column names
        for _, col_node in ipairs(tbl_node.children or {}) do
          if base == "" or col_node.name:lower():sub(1, #base_lower) == base_lower then
            local col_type = (col_node.meta and col_node.meta.col_type) or ""
            table.insert(items, {
              label = col_node.name,
              labelDetails = { description = tbl_node.name .. "." .. col_type },
              kind = KIND.Field,
              insertText = col_node.name,
              sortText = "2_" .. col_node.name,
            })
          end
        end
      end
    end
  end

  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items,
  })
end

function source:get_trigger_characters()
  return { ".", " ", "(" }
end

function source:enabled()
  local ok, state = pcall(require, "sundb.state")
  if not ok then return false end
  local cur_buf = vim.api.nvim_get_current_buf()
  return state.state.editor.buf == cur_buf
end

return source
