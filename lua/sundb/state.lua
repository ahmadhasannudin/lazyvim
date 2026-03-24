-- Sundb shared state

local M = {}

M.state = {
  is_open = false,
  tab = nil,
  sidebar = { win = nil, buf = nil, tree = {} },
  editor = { win = nil, buf = nil },
  results = {},
  log = { win = nil, buf = nil, entries = {} },
  active_env = nil,
  active_db = nil,
  auto_commit = false,
  auto_limit = true,
  config = nil,
}

function M.valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

function M.valid_buf(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

function M.is_valid()
  return M.state.is_open
    and M.valid_win(M.state.sidebar.win)
    and M.valid_win(M.state.editor.win)
    and M.valid_win(M.state.log.win)
end

function M.reset()
  M.state.is_open = false
  M.state.tab = nil
  M.state.sidebar = { win = nil, buf = nil, tree = {} }
  M.state.editor = { win = nil, buf = nil }
  M.state.results = {}
  M.state.log = { win = nil, buf = nil, entries = M.state.log.entries }
  M.state.active_env = nil
  M.state.active_db = nil
end

return M
