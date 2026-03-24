-- Sundb 3-panel layout management

local state = require("sundb.state")
local sidebar = require("sundb.sidebar")
local editor = require("sundb.editor")
local log = require("sundb.log")

local M = {}

function M.open()
  if state.state.is_open and state.is_valid() then
    -- Switch to existing tab
    if state.state.tab and vim.api.nvim_tabpage_is_valid(state.state.tab) then
      vim.api.nvim_set_current_tabpage(state.state.tab)
    end
    return
  end

  -- Clean up stale state
  state.reset()

  -- Create a new tab
  vim.cmd("tabnew")
  state.state.tab = vim.api.nvim_get_current_tabpage()

  -- The new tab creates a buffer — use it as editor
  local editor_win = vim.api.nvim_get_current_win()
  local editor_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(editor_win, editor_buf)
  state.state.editor.win = editor_win
  state.state.editor.buf = editor_buf
  editor.setup_buf(editor_buf)

  -- Create sidebar (left split)
  vim.cmd("topleft vsplit")
  local sidebar_win = vim.api.nvim_get_current_win()
  local sidebar_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(sidebar_win, sidebar_buf)
  vim.api.nvim_win_set_width(sidebar_win, 35)
  state.state.sidebar.win = sidebar_win
  state.state.sidebar.buf = sidebar_buf
  sidebar.setup_buf(sidebar_buf)

  vim.api.nvim_win_set_option(sidebar_win, "number", false)
  vim.api.nvim_win_set_option(sidebar_win, "relativenumber", false)
  vim.api.nvim_win_set_option(sidebar_win, "signcolumn", "no")
  vim.api.nvim_win_set_option(sidebar_win, "winfixwidth", true)

  -- Create log panel (bottom split spanning full width)
  vim.api.nvim_set_current_win(editor_win)
  vim.cmd("botright split")
  local log_win = vim.api.nvim_get_current_win()
  local log_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(log_win, log_buf)
  vim.api.nvim_win_set_height(log_win, 8)
  state.state.log.win = log_win
  state.state.log.buf = log_buf
  log.setup_buf(log_buf)

  vim.api.nvim_win_set_option(log_win, "number", false)
  vim.api.nvim_win_set_option(log_win, "relativenumber", false)
  vim.api.nvim_win_set_option(log_win, "signcolumn", "no")
  vim.api.nvim_win_set_option(log_win, "wrap", false)
  vim.api.nvim_win_set_option(log_win, "winfixheight", true)

  state.state.is_open = true

  -- Load config and build sidebar tree
  local connection = require("sundb.connection")
  connection.load_config()
  sidebar.build_tree()
  log.render()

  -- Focus editor
  vim.api.nvim_set_current_win(editor_win)

  -- Set up autocmd to detect when sundb tab is closed
  vim.api.nvim_create_autocmd("TabClosed", {
    group = vim.api.nvim_create_augroup("sundb_tab_close", { clear = true }),
    callback = function()
      if state.state.is_open and state.state.tab and not vim.api.nvim_tabpage_is_valid(state.state.tab) then
        require("sundb.results").close_all()
        state.reset()
      end
    end,
  })
end

function M.close()
  if not state.state.is_open then
    return
  end

  -- Close all result floats
  local results = require("sundb.results")
  results.close_all()

  -- Close all sundb windows
  for _, key in ipairs({ "sidebar", "editor", "log" }) do
    local win = state.state[key].win
    if state.valid_win(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- Close the tab if it's still valid and empty
  if state.state.tab and vim.api.nvim_tabpage_is_valid(state.state.tab) then
    local wins = vim.api.nvim_tabpage_list_wins(state.state.tab)
    if #wins <= 1 then
      vim.api.nvim_set_current_tabpage(state.state.tab)
      vim.cmd("tabclose")
    end
  end

  state.reset()
end

function M.toggle()
  if state.state.is_open and state.is_valid() then
    M.close()
  else
    M.open()
  end
end

return M
