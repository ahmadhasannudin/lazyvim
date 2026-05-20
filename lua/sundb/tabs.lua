-- Sundb tab management: each tab = one SQL file + its own connection

local state = require("sundb.state")

local M = {}

local QUERIES_DIR = vim.fn.stdpath("config") .. "/sundb/queries"

local function queries_dir()
  vim.fn.mkdir(QUERIES_DIR, "p")
  return QUERIES_DIR
end

local function escape_wb(s)
  -- Escape % for use in winbar/statusline strings
  return tostring(s or ""):gsub("%%", "%%%%")
end

-- ── Tabline rendering (via editor winbar) ──────────────────────────────────

function M.render()
  local editor_win = state.state.editor.win
  if not state.valid_win(editor_win) then return end

  local tabs = state.state.tabs
  if #tabs == 0 then
    pcall(vim.api.nvim_win_set_option, editor_win, "winbar", "")
    return
  end

  local parts = {}
  for i, tab in ipairs(tabs) do
    -- escape_wb handles literal % in filenames → %% so nvim doesn't misinterpret them
    local name = escape_wb(tab.name or "untitled")
    local ok, modified = pcall(vim.api.nvim_buf_get_option, tab.buf, "modified")
    local dot = (ok and modified) and "●" or ""
    if i == state.state.active_tab_idx then
      -- %#HlGroup# (single %) sets highlight; the name is already %%-escaped
      table.insert(parts, "%#TabLineSel# " .. name .. dot .. " %#TabLine#")
    else
      table.insert(parts, " " .. name .. dot .. " ")
    end
  end

  local env = escape_wb(state.state.active_env or "—")
  local db  = escape_wb(state.state.active_db  or "—")
  -- %= right-aligns; %#Comment# sets highlight
  local right = "%=%#Comment# " .. env .. "/" .. db .. " "

  pcall(vim.api.nvim_win_set_option, editor_win, "winbar",
    table.concat(parts, "│") .. right)
end

-- ── Buffer setup ──────────────────────────────────────────────────────────

local function apply_buf_options(buf)
  vim.bo[buf].filetype  = "sql"
  vim.bo[buf].swapfile  = false
  vim.bo[buf].buflisted = false

  -- Re-render tabline when buffer modified state changes
  vim.api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = function() vim.schedule(M.render) end,
  })
end

-- ── Tab CRUD ──────────────────────────────────────────────────────────────

-- Delete any buffer that already holds `name` (so we can claim it).
local function free_buf_name(name)
  local existing = vim.fn.bufnr(name)
  if existing ~= -1 then
    -- Only wipe it when it's not already one of our managed tabs
    local owned = false
    for _, t in ipairs(state.state.tabs) do
      if t.buf == existing then owned = true; break end
    end
    if not owned then
      pcall(vim.api.nvim_buf_delete, existing, { force = true })
    end
  end
end

function M.new(file_path)
  local buf, resolved_path, name

  if file_path then
    file_path = vim.fn.fnamemodify(vim.fn.expand(file_path), ":p")
  end

  if file_path and vim.fn.filereadable(file_path) == 1 then
    -- Open existing file – reuse buffer if already loaded, else create fresh
    local existing = vim.fn.bufnr(file_path)
    if existing ~= -1 and vim.api.nvim_buf_is_valid(existing) then
      buf = existing
    else
      buf = vim.fn.bufadd(file_path)
      vim.bo[buf].swapfile = false
      vim.fn.bufload(buf)
    end
    name          = vim.fn.fnamemodify(file_path, ":t")
    resolved_path = file_path
  else
    -- New unnamed buffer: find a free query_N.sql slot
    local dir = queries_dir()
    local n   = #state.state.tabs + 1
    resolved_path = dir .. "/query_" .. n .. ".sql"
    while vim.fn.filereadable(resolved_path) == 1
       or vim.fn.bufnr(resolved_path) ~= -1 do
      n = n + 1
      resolved_path = dir .. "/query_" .. n .. ".sql"
    end
    name = vim.fn.fnamemodify(resolved_path, ":t")

    buf = vim.api.nvim_create_buf(false, false)
    vim.bo[buf].swapfile = false
    -- Release any stale buffer that holds the name, then claim it
    free_buf_name(resolved_path)
    local ok, err = pcall(vim.api.nvim_buf_set_name, buf, resolved_path)
    if not ok then
      vim.notify("sundb: could not name buffer: " .. tostring(err), vim.log.levels.WARN)
    end
  end

  apply_buf_options(buf)

  -- Setup editor keymaps on this buffer
  local editor = require("sundb.editor")
  editor.setup_keymaps(buf)
  M.setup_tab_keymaps(buf)

  -- Start sqls LSP for this buffer (no-op if sqls not installed)
  vim.schedule(function() editor.start_lsp(buf) end)

  local entry = {
    buf  = buf,
    file = resolved_path,
    name = name,
    env  = state.state.active_env,
    db   = state.state.active_db,
  }
  table.insert(state.state.tabs, entry)
  M.switch(#state.state.tabs)
  return entry
end

function M.open_file()
  local dir = queries_dir()
  -- Collect .sql files: queries dir first, then cwd
  local seen, files = {}, {}
  local function add(list)
    for _, f in ipairs(list) do
      local abs = vim.fn.fnamemodify(f, ":p")
      if not seen[abs] then seen[abs] = true; table.insert(files, abs) end
    end
  end
  add(vim.fn.globpath(dir, "*.sql", false, true))
  add(vim.fn.globpath(vim.fn.getcwd(), "**/*.sql", false, true))

  if #files == 0 then
    vim.notify("sundb: no SQL files found", vim.log.levels.INFO)
    return
  end

  vim.ui.select(files, {
    prompt = "Open SQL file:",
    format_item = function(f) return vim.fn.fnamemodify(f, ":.") end,
  }, function(choice)
    if not choice then return end
    vim.schedule(function() M.new(choice) end)
  end)
end

function M.save(idx)
  idx = idx or state.state.active_tab_idx
  local tabs = state.state.tabs
  if not tabs[idx] then return end
  local tab = tabs[idx]

  local do_write = function()
    local path = tab.file
    if not path then return end
    -- Try :write first; fall back to writefile so save works even before
    -- the buffer has been displayed in a window (e.g. right after M.new).
    local editor_win = state.state.editor.win
    local wrote = false
    if state.valid_win(editor_win) then
      local ok = pcall(vim.api.nvim_win_call, editor_win, function()
        vim.cmd("silent! write")
      end)
      wrote = ok and not vim.api.nvim_buf_get_option(tab.buf, "modified")
    end
    if not wrote then
      local lines = vim.api.nvim_buf_get_lines(tab.buf, 0, -1, false)
      local ok, err = pcall(vim.fn.writefile, lines, path)
      if ok then
        -- Mark buffer unmodified through a window context (the only reliable way)
        local wins = vim.fn.win_findbuf(tab.buf)
        if #wins > 0 then
          vim.api.nvim_win_call(wins[1], function()
            vim.cmd("noautocmd setlocal nomodified")
          end)
        end
      else
        vim.notify("sundb save failed: " .. tostring(err), vim.log.levels.ERROR)
      end
    end
    M.render()
  end

  if not tab.file then
    vim.ui.input({
      prompt     = "Save as: ",
      default    = queries_dir() .. "/" .. tab.name,
      completion = "file",
    }, function(path)
      if not path or path == "" then return end
      path = vim.fn.expand(path)
      tab.file = path
      tab.name = vim.fn.fnamemodify(path, ":t")
      pcall(vim.api.nvim_buf_set_name, tab.buf, path)
      do_write()
    end)
  else
    do_write()
  end
end

function M.close(idx)
  idx = idx or state.state.active_tab_idx
  local tabs = state.state.tabs
  if #tabs == 0 then return end
  idx = math.max(1, math.min(idx, #tabs))
  local tab = tabs[idx]

  if tab and state.valid_buf(tab.buf) then
    local ok, modified = pcall(vim.api.nvim_buf_get_option, tab.buf, "modified")
    if ok and modified then
      vim.ui.select({ "Save and close", "Close without saving", "Cancel" }, {
        prompt = "Unsaved changes in " .. (tab.name or "buffer") .. ":",
      }, function(choice)
        if choice == "Save and close" then
          M.save(idx)
          vim.schedule(function() M._do_close(idx) end)
        elseif choice == "Close without saving" then
          M._do_close(idx)
        end
      end)
      return
    end
  end
  M._do_close(idx)
end

function M._do_close(idx)
  local tabs = state.state.tabs
  local tab  = tabs[idx]
  if tab and state.valid_buf(tab.buf) then
    pcall(vim.api.nvim_buf_delete, tab.buf, { force = true })
  end
  table.remove(tabs, idx)

  if #tabs == 0 then
    M.new()
    return
  end
  M.switch(math.min(idx, #tabs))
end

-- ── Switch / navigation ───────────────────────────────────────────────────

function M.switch(idx)
  local tabs = state.state.tabs
  if #tabs == 0 then return end
  idx = math.max(1, math.min(idx, #tabs))

  -- Persist current tab's connection before leaving
  local cur = state.state.active_tab_idx
  if cur > 0 and tabs[cur] then
    tabs[cur].env = state.state.active_env
    tabs[cur].db  = state.state.active_db
  end

  state.state.active_tab_idx = idx
  local tab = tabs[idx]

  -- Restore connection
  state.state.active_env = tab.env
  state.state.active_db  = tab.db

  -- Load buffer into editor window
  local editor_win = state.state.editor.win
  if state.valid_win(editor_win) and state.valid_buf(tab.buf) then
    vim.api.nvim_win_set_buf(editor_win, tab.buf)
    state.state.editor.buf = tab.buf
  end

  -- Close stale result floats (tied to old buffer's extmarks)
  require("sundb.results").close_all()

  M.render()
end

function M.next()
  local n = #state.state.tabs
  if n == 0 then return end
  M.switch((state.state.active_tab_idx % n) + 1)
end

function M.prev()
  local n = #state.state.tabs
  if n == 0 then return end
  M.switch(((state.state.active_tab_idx - 2) % n) + 1)
end

-- ── Per-buffer tab keymaps ────────────────────────────────────────────────

function M.setup_tab_keymaps(buf)
  local o = function(desc) return { buffer = buf, desc = desc } end
  vim.keymap.set("n", "gt",          M.next,                      o("Next tab"))
  vim.keymap.set("n", "gT",          M.prev,                      o("Prev tab"))
  vim.keymap.set("n", "<leader>tn",  M.new,                       o("New tab"))
  vim.keymap.set("n", "<leader>to",  M.open_file,                 o("Open SQL file"))
  vim.keymap.set("n", "<leader>tc",  M.close,                     o("Close tab"))
  vim.keymap.set("n", "<C-s>",       M.save,                      o("Save"))
  vim.keymap.set("i", "<C-s>",       function()
    vim.cmd("stopinsert"); M.save()
  end, o("Save"))
  vim.keymap.set("n", "<leader>ts",  function()
    require("sundb.ui").toggle_sidebar()
  end, o("Toggle sidebar"))
  vim.keymap.set("n", "<leader>tl",  function()
    require("sundb.ui").toggle_log()
  end, o("Toggle log"))
  vim.keymap.set("n", "<leader>te",  function()
    local s = state.state.sidebar
    if state.valid_win(s.win) then
      vim.api.nvim_set_current_win(s.win)
    end
  end, o("Focus sidebar"))
end

return M
