-- Sundb sidebar tree view

local state = require("sundb.state")
local connection = require("sundb.connection")

local M = {}

-- Tree node structure:
-- { type="env"|"database"|"table"|"column", name="...", expanded=bool, children={}, parent=node, meta={} }

function M.build_tree()
  local envs = connection.get_env_names()
  local tree = {}
  for _, env_name in ipairs(envs) do
    local env_config = connection.get_env_config(env_name)
    table.insert(tree, {
      type = "env",
      name = env_name,
      expanded = false,
      children = {},
      meta = { config = env_config },
    })
  end
  state.state.sidebar.tree = tree
  M.render()
end

function M.render()
  local buf = state.state.sidebar.buf
  if not state.valid_buf(buf) then
    return
  end

  local lines = {}
  local node_map = {} -- line -> node mapping

  local function walk(nodes, depth)
    for _, node in ipairs(nodes) do
      local indent = string.rep("  ", depth)
      local icon = M.get_icon(node)
      local arrow = ""
      if node.type ~= "column" then
        arrow = node.expanded and "▾ " or "▸ "
      end
      local line = indent .. arrow .. icon .. node.name
      if node.type == "column" and node.meta and node.meta.col_type then
        line = line .. "  " .. node.meta.col_type
      end
      table.insert(lines, line)
      table.insert(node_map, node)
      if node.expanded and node.children then
        walk(node.children, depth + 1)
      end
    end
  end

  walk(state.state.sidebar.tree, 0)

  if #lines == 0 then
    lines = { "  No connections", "", "  Add .sundb.json to project root" }
    node_map = { nil, nil, nil }
  end

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Store node map on buffer for lookups
  vim.b[buf] = vim.b[buf] or {}
  M._node_map = node_map

  -- Highlight active env/db
  local ns = vim.api.nvim_create_namespace("sundb_sidebar")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, node in ipairs(node_map) do
    if node then
      if node.type == "env" and node.name == state.state.active_env then
        vim.api.nvim_buf_add_highlight(buf, ns, "Title", i - 1, 0, -1)
      elseif node.type == "database" and node.name == state.state.active_db then
        vim.api.nvim_buf_add_highlight(buf, ns, "String", i - 1, 0, -1)
      elseif node.type == "column" then
        vim.api.nvim_buf_add_highlight(buf, ns, "Comment", i - 1, 0, -1)
      end
    end
  end
end

function M.get_icon(node)
  if node.type == "env" then return " " end
  if node.type == "database" then return " " end
  if node.type == "table" then return " " end
  if node.type == "column" then return "  " end
  return ""
end

function M.get_node_at_cursor()
  local buf = state.state.sidebar.buf
  if not state.valid_buf(buf) then
    return nil
  end
  local win = state.state.sidebar.win
  if not state.valid_win(win) then
    return nil
  end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  if M._node_map and M._node_map[row] then
    return M._node_map[row]
  end
  return nil
end

function M.find_parent_env(node)
  -- Walk tree to find the env ancestor
  local function search(nodes, target, env_name)
    for _, n in ipairs(nodes) do
      local current_env = n.type == "env" and n.name or env_name
      if n == target then
        return current_env
      end
      if n.children then
        local found = search(n.children, target, current_env)
        if found then return found end
      end
    end
    return nil
  end
  return search(state.state.sidebar.tree, node, nil)
end

function M.find_parent_db(node)
  local function search(nodes, target, db_name)
    for _, n in ipairs(nodes) do
      local current_db = n.type == "database" and n.name or db_name
      if n == target then
        return current_db
      end
      if n.children then
        local found = search(n.children, target, current_db)
        if found then return found end
      end
    end
    return nil
  end
  return search(state.state.sidebar.tree, node, nil)
end

function M.toggle_node()
  local node = M.get_node_at_cursor()
  if not node or node.type == "column" then
    return
  end

  if node.expanded then
    node.expanded = false
    M.render()
    return
  end

  node.expanded = true

  if node.type == "env" then
    -- Set active env
    state.state.active_env = node.name
    local env_config = connection.get_env_config(node.name)
    if env_config and env_config.default_database then
      state.state.active_db = env_config.default_database
    end
    if #node.children == 0 then
      M.fetch_databases(node)
      return
    end
  elseif node.type == "database" then
    state.state.active_db = node.name
    state.state.active_env = M.find_parent_env(node)
    if #node.children == 0 then
      M.fetch_tables(node)
      return
    end
  elseif node.type == "table" then
    if #node.children == 0 then
      M.fetch_columns(node)
      return
    end
  end

  M.render()
end

function M.fetch_databases(env_node)
  connection.execute("SHOW DATABASES", function(result, err)
    if err then
      vim.notify("Sundb: " .. err, vim.log.levels.ERROR)
      return
    end
    env_node.children = {}
    for _, row in ipairs(result.rows) do
      table.insert(env_node.children, {
        type = "database",
        name = row[1],
        expanded = false,
        children = {},
      })
    end
    M.render()
  end, { env = env_node.name, database = nil })
end

function M.fetch_tables(db_node)
  local env_name = M.find_parent_env(db_node)
  connection.execute("SHOW TABLES", function(result, err)
    if err then
      vim.notify("Sundb: " .. err, vim.log.levels.ERROR)
      return
    end
    db_node.children = {}
    for _, row in ipairs(result.rows) do
      table.insert(db_node.children, {
        type = "table",
        name = row[1],
        expanded = false,
        children = {},
      })
    end
    M.render()
  end, { env = env_name, database = db_node.name })
end

function M.fetch_columns(table_node)
  local env_name = M.find_parent_env(table_node)
  local db_name = M.find_parent_db(table_node)
  connection.execute("DESCRIBE `" .. table_node.name .. "`", function(result, err)
    if err then
      vim.notify("Sundb: " .. err, vim.log.levels.ERROR)
      return
    end
    table_node.children = {}
    for _, row in ipairs(result.rows) do
      table.insert(table_node.children, {
        type = "column",
        name = row[1],
        children = nil,
        meta = { col_type = row[2], nullable = row[3], key = row[4] },
      })
    end
    M.render()
  end, { env = env_name, database = db_name })
end

function M.send_select_to_editor()
  local node = M.get_node_at_cursor()
  if not node or node.type ~= "table" then
    return
  end

  local env_name = M.find_parent_env(node)
  local db_name = M.find_parent_db(node)
  if env_name then
    state.state.active_env = env_name
  end
  if db_name then
    state.state.active_db = db_name
  end

  local sql = "SELECT * FROM `" .. node.name .. "`;"
  local editor_buf = state.state.editor.buf
  if not state.valid_buf(editor_buf) then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(editor_buf)
  local last_line = vim.api.nvim_buf_get_lines(editor_buf, line_count - 1, line_count, false)[1] or ""

  local new_lines = {}
  if last_line ~= "" then
    table.insert(new_lines, "")
  end
  table.insert(new_lines, sql)

  vim.api.nvim_buf_set_lines(editor_buf, line_count, line_count, false, new_lines)

  -- Focus editor and move cursor
  if state.valid_win(state.state.editor.win) then
    vim.api.nvim_set_current_win(state.state.editor.win)
    local new_count = vim.api.nvim_buf_line_count(editor_buf)
    vim.api.nvim_win_set_cursor(state.state.editor.win, { new_count, 0 })
  end
end

function M.describe_table()
  local node = M.get_node_at_cursor()
  if not node or node.type ~= "table" then
    return
  end

  local env_name = M.find_parent_env(node)
  local db_name = M.find_parent_db(node)

  local sql = "DESCRIBE `" .. node.name .. "`"
  local results = require("sundb.results")
  local log = require("sundb.log")

  -- Insert DESCRIBE query into editor and execute inline
  local editor_buf = state.state.editor.buf
  if not state.valid_buf(editor_buf) then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(editor_buf)
  local last_line = vim.api.nvim_buf_get_lines(editor_buf, line_count - 1, line_count, false)[1] or ""
  local new_lines = {}
  if last_line ~= "" then
    table.insert(new_lines, "")
  end
  table.insert(new_lines, sql .. ";")
  vim.api.nvim_buf_set_lines(editor_buf, line_count, line_count, false, new_lines)

  local stmt_line = vim.api.nvim_buf_line_count(editor_buf)

  connection.execute(sql, function(result, err, elapsed)
    if err then
      log.add(env_name, db_name, sql, elapsed or 0, 0, true)
      results.show_error_inline(err, env_name, db_name, elapsed, stmt_line)
      return
    end
    log.add(env_name, db_name, sql, elapsed, result.row_count, false)
    results.show_inline(result, env_name, db_name, stmt_line)
  end, { env = env_name, database = db_name })
end

function M.refresh()
  -- Clear all children and rebuild
  for _, env_node in ipairs(state.state.sidebar.tree) do
    env_node.children = {}
    env_node.expanded = false
  end
  M.build_tree()
end

function M.setup_buf(buf)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "buflisted", false)
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_name(buf, "sundb://sidebar")

  -- Keymaps
  vim.keymap.set("n", "<CR>", function()
    M.toggle_node()
  end, { buffer = buf, desc = "Expand/collapse" })
  vim.keymap.set("n", "r", function()
    M.refresh()
  end, { buffer = buf, desc = "Refresh tree" })
  vim.keymap.set("n", "e", function()
    M.send_select_to_editor()
  end, { buffer = buf, desc = "Send SELECT to editor" })
  vim.keymap.set("n", "d", function()
    M.describe_table()
  end, { buffer = buf, desc = "Describe table" })
end

return M
