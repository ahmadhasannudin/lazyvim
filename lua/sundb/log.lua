-- Sundb query execution log

local state = require("sundb.state")

local M = {}

local MAX_ENTRIES = 500

function M.add(env, db, sql, elapsed, row_count, is_error)
  local entry = {
    time = os.date("%H:%M:%S"),
    env = env or "?",
    db = db or "?",
    sql = sql:gsub("%s+", " "):sub(1, 200),
    elapsed = elapsed,
    row_count = row_count,
    is_error = is_error or false,
  }
  table.insert(state.state.log.entries, entry)
  if #state.state.log.entries > MAX_ENTRIES then
    table.remove(state.state.log.entries, 1)
  end
  M.render()
end

function M.format_entry(entry)
  local duration = string.format("%.2fs", entry.elapsed or 0)
  local suffix = entry.is_error and " ERROR" or string.format(" %d rows", entry.row_count or 0)
  return string.format("[%s] %s/%s > %s (%s,%s)", entry.time, entry.env, entry.db, entry.sql, duration, suffix)
end

function M.render()
  local buf = state.state.log.buf
  if not state.valid_buf(buf) then
    return
  end

  local lines = {}
  for _, entry in ipairs(state.state.log.entries) do
    table.insert(lines, M.format_entry(entry))
  end

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Auto-scroll to bottom
  local win = state.state.log.win
  if state.valid_win(win) then
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(win, { line_count, 0 })
  end

  -- Highlight errors
  vim.api.nvim_buf_clear_namespace(buf, vim.api.nvim_create_namespace("sundb_log"), 0, -1)
  for i, entry in ipairs(state.state.log.entries) do
    if entry.is_error then
      vim.api.nvim_buf_add_highlight(buf, vim.api.nvim_create_namespace("sundb_log"), "DiagnosticError", i - 1, 0, -1)
    end
  end
end

function M.setup_buf(buf)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "buflisted", false)
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_name(buf, "sundb://log")
end

return M
