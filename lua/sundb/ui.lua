-- Sundb 3-panel layout management

local state   = require("sundb.state")
local sidebar = require("sundb.sidebar")
local log     = require("sundb.log")

local M = {}

local SIDEBAR_WIDTH = 35
local LOG_HEIGHT    = 8

local function apply_sidebar_win_opts(win)
  vim.api.nvim_win_set_option(win, "number",         false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)
  vim.api.nvim_win_set_option(win, "signcolumn",     "no")
  vim.api.nvim_win_set_option(win, "winfixwidth",    true)
end

local function apply_log_win_opts(win)
  vim.api.nvim_win_set_option(win, "number",         false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)
  vim.api.nvim_win_set_option(win, "signcolumn",     "no")
  vim.api.nvim_win_set_option(win, "wrap",           false)
  vim.api.nvim_win_set_option(win, "winfixheight",   true)
end

function M.open()
  if state.state.is_open and state.is_valid() then
    if state.state.tab and vim.api.nvim_tabpage_is_valid(state.state.tab) then
      vim.api.nvim_set_current_tabpage(state.state.tab)
    end
    return
  end

  state.reset()

  -- New nvim tab for sundb
  vim.cmd("tabnew")
  state.state.tab = vim.api.nvim_get_current_tabpage()

  -- Editor window (the one tabnew created)
  local editor_win = vim.api.nvim_get_current_win()
  state.state.editor.win = editor_win

  -- Sidebar (left vsplit)
  vim.cmd("topleft vsplit")
  local sidebar_win = vim.api.nvim_get_current_win()
  local sidebar_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(sidebar_win, sidebar_buf)
  vim.api.nvim_win_set_width(sidebar_win, SIDEBAR_WIDTH)
  state.state.sidebar.win = sidebar_win
  state.state.sidebar.buf = sidebar_buf
  sidebar.setup_buf(sidebar_buf)
  apply_sidebar_win_opts(sidebar_win)

  -- Log (bottom split spanning full width)
  vim.api.nvim_set_current_win(editor_win)
  vim.cmd("botright split")
  local log_win = vim.api.nvim_get_current_win()
  local log_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(log_win, log_buf)
  vim.api.nvim_win_set_height(log_win, LOG_HEIGHT)
  state.state.log.win = log_win
  state.state.log.buf = log_buf
  log.setup_buf(log_buf)
  apply_log_win_opts(log_win)

  state.state.is_open       = true
  state.state.sidebar_visible = true
  state.state.log_visible     = true

  -- Load config, build tree, create first tab
  local connection = require("sundb.connection")
  connection.load_config()
  sidebar.build_tree()
  log.render()

  -- Create initial editor tab (file-based)
  vim.api.nvim_set_current_win(editor_win)
  require("sundb.tabs").new()

  -- Prefetch schema for the active env/db in background
  vim.schedule(function()
    local env = state.state.active_env
    local db  = state.state.active_db
    if env and db then
      require("sundb.connection").fetch_schema(env, db)
    end
  end)

  -- Detect when sundb nvim-tab is closed externally
  vim.api.nvim_create_autocmd("TabClosed", {
    group = vim.api.nvim_create_augroup("sundb_tab_close", { clear = true }),
    callback = function()
      if state.state.is_open
        and state.state.tab
        and not vim.api.nvim_tabpage_is_valid(state.state.tab)
      then
        require("sundb.results").close_all()
        state.reset()
      end
    end,
  })
end

function M.close()
  if not state.state.is_open then return end

  require("sundb.results").close_all()

  for _, key in ipairs({ "sidebar", "editor", "log" }) do
    local win = state.state[key].win
    if state.valid_win(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

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

-- ── Panel toggles ──────────────────────────────────────────────────────────

function M.toggle_sidebar()
  if not state.state.is_open then return end
  local s = state.state.sidebar

  if state.state.sidebar_visible and state.valid_win(s.win) then
    -- Hide
    pcall(vim.api.nvim_win_close, s.win, false)
    state.state.sidebar.win = nil
    state.state.sidebar_visible = false
  else
    -- Show: create a new vsplit to the left of editor
    local editor_win = state.state.editor.win
    if not state.valid_win(editor_win) then return end
    vim.api.nvim_set_current_win(editor_win)
    vim.cmd("topleft vsplit")
    local new_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(new_win, s.buf)
    vim.api.nvim_win_set_width(new_win, SIDEBAR_WIDTH)
    apply_sidebar_win_opts(new_win)
    state.state.sidebar.win = new_win
    state.state.sidebar_visible = true
    vim.api.nvim_set_current_win(editor_win)
  end
end

function M.toggle_log()
  if not state.state.is_open then return end
  local l = state.state.log

  if state.state.log_visible and state.valid_win(l.win) then
    -- Hide
    pcall(vim.api.nvim_win_close, l.win, false)
    state.state.log.win = nil
    state.state.log_visible = false
  else
    -- Show: create a new split at the bottom
    local editor_win = state.state.editor.win
    if not state.valid_win(editor_win) then return end
    vim.api.nvim_set_current_win(editor_win)
    vim.cmd("botright split")
    local new_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(new_win, l.buf)
    vim.api.nvim_win_set_height(new_win, LOG_HEIGHT)
    apply_log_win_opts(new_win)
    state.state.log.win = new_win
    state.state.log_visible = true
    log.render()
    vim.api.nvim_set_current_win(editor_win)
  end
end

return M
