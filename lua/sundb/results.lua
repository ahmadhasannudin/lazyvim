-- Sundb floating inline results

local state = require("sundb.state")
local M = {}

local MAX_COL_WIDTH = 30
local MAX_DATA_ROWS  = 12
local ns = vim.api.nvim_create_namespace("sundb_results")

local floats = {}
local reposition_group = nil

-- ── Display-width helpers ──────────────────────────────────────────────────

local function dw(str)
  return vim.fn.strdisplaywidth(tostring(str or ""))
end

local function compute_col_widths(headers, rows)
  local widths = {}
  for i, h in ipairs(headers) do widths[i] = dw(h) end
  for _, row in ipairs(rows) do
    for i, col in ipairs(row) do
      local w = dw(tostring(col))
      if not widths[i] or w > widths[i] then widths[i] = w end
    end
  end
  for i, w in ipairs(widths) do widths[i] = math.min(w, MAX_COL_WIDTH) end
  return widths
end

local function pad(str, width)
  str = tostring(str or "")
  str = str:gsub("\r\n", "↵"):gsub("\n", "↵"):gsub("\r", "↵")
  local w = dw(str)
  if w > width then
    local result = ""
    for _, code in ipairs(vim.fn.str2list(str)) do
      local ch = vim.fn.nr2char(code)
      if dw(result .. ch) > width - 1 then
        result = result .. "…"
        break
      end
      result = result .. ch
    end
    local rw = dw(result)
    return result .. string.rep(" ", math.max(0, width - rw))
  end
  return str .. string.rep(" ", width - w)
end

local function render_border(widths, l, m, r)
  local parts = {}
  for _, w in ipairs(widths) do table.insert(parts, string.rep("─", w + 2)) end
  return l .. table.concat(parts, m) .. r
end

local function render_row(values, widths)
  local parts = {}
  for i, w in ipairs(widths) do
    table.insert(parts, " " .. pad(values[i] or "", w) .. " ")
  end
  return "│" .. table.concat(parts, "│") .. "│"
end

-- Build the top border line with title embedded: ╭─ title ───────╮
local function render_top_border(widths, title)
  -- inner_w = total dashes between ╭ and ╮ (matching separator line width minus 2)
  local inner_w = 0
  for _, w in ipairs(widths) do inner_w = inner_w + w + 2 end
  inner_w = inner_w + #widths - 1  -- for the separators between columns

  if not title or title == "" then
    return "╭" .. string.rep("─", inner_w) .. "╮"
  end

  local t = " " .. title .. " "
  local tw = dw(t)
  if tw >= inner_w - 1 then
    -- title longer than available space: just dashes
    return "╭" .. string.rep("─", inner_w) .. "╮"
  end
  -- ╭─ title ────...────╮  (1 dash before, rest after)
  local after = inner_w - tw - 1
  return "╭─" .. t .. string.rep("─", after) .. "╮"
end

-- ── Float repositioning ────────────────────────────────────────────────────

local function get_win_row(editor_win, stmt_line)
  local sp = vim.fn.screenpos(editor_win, stmt_line, 1)
  if sp.row == 0 then return nil end
  local wpos = vim.api.nvim_win_get_position(editor_win)
  return sp.row - wpos[1] - 1
end

local function reposition_floats()
  local editor_win = state.state.editor.win
  if not state.valid_win(editor_win) then return end
  local win_height = vim.api.nvim_win_get_height(editor_win)
  local editor_pos = vim.api.nvim_win_get_position(editor_win)

  local function screen_to_win(screen_row)
    if screen_row == 0 then return nil end
    local r = screen_row - editor_pos[1] - 1
    if r < 0 or r >= win_height then return nil end
    return r
  end

  for _, f in ipairs(floats) do
    local header_h = f.header_h or 0
    local data_h   = f.data_h   or 1

    -- Where is the SQL line on screen?
    local editor_buf  = state.state.editor.buf
    local line_count  = state.valid_buf(editor_buf) and vim.api.nvim_buf_line_count(editor_buf) or 0
    local sp          = vim.fn.screenpos(editor_win, f.stmt_line, 1)
    local sp_next     = (f.stmt_line < line_count)
                        and vim.fn.screenpos(editor_win, f.stmt_line + 1, 1)
                        or  { row = 0 }
    local win_row      = screen_to_win(sp.row)
    local next_win_row = screen_to_win(sp_next.row)

    local show     = false
    local h_row, d_row
    local h_height = header_h
    local d_height = data_h

    if win_row then
      -- SQL line is fully visible: normal positioning
      show  = true
      h_row = win_row + 1
      d_row = win_row + 1 + header_h
    elseif next_win_row and next_win_row > 0 then
      -- SQL line scrolled off the top, but the line after the virt_lines is
      -- still visible at next_win_row → we are inside the reserved virt_lines.
      -- Pin the float to row 0 and clip its height to the available space.
      local available = next_win_row   -- rows 0 .. next_win_row-1
      h_height = math.min(header_h, available)
      d_height = math.min(data_h,   available - h_height)
      if h_height + d_height > 0 then
        show  = true
        h_row = 0
        d_row = h_height
      end
    end

    -- Apply config to header float (may be nil for simple/error floats)
    if f.header_win and vim.api.nvim_win_is_valid(f.header_win) then
      if show and h_height > 0 then
        pcall(vim.api.nvim_win_set_config, f.header_win, {
          hide     = false,
          relative = "win",
          win      = editor_win,
          row      = h_row,
          col      = 1,
          height   = h_height,
        })
      else
        pcall(vim.api.nvim_win_set_config, f.header_win, { hide = true })
      end
    end

    -- Apply config to data / main float
    if f.win and vim.api.nvim_win_is_valid(f.win) then
      if show and d_height > 0 then
        pcall(vim.api.nvim_win_set_config, f.win, {
          hide     = false,
          relative = "win",
          win      = editor_win,
          row      = d_row,
          col      = 1,
          height   = d_height,
        })
      else
        pcall(vim.api.nvim_win_set_config, f.win, { hide = true })
      end
    end
  end
end

local function ensure_reposition_autocmds(editor_buf, editor_win)
  if reposition_group then return end

  reposition_group = vim.api.nvim_create_augroup("sundb_reposition", { clear = true })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = editor_buf,
    group = reposition_group,
    callback = function() vim.schedule(reposition_floats) end,
  })

  vim.api.nvim_create_autocmd("WinScrolled", {
    group = reposition_group,
    callback = function() reposition_floats() end,
  })
end

-- ── Cell detection ─────────────────────────────────────────────────────────
-- data_buf layout:
--   lines 1..visible_rows  : data rows
--   line  visible_rows+1   : bottom border ╰─┴─╯

local function get_col_at_virtcol(widths, virtcol)
  local pos = 1
  for i, w in ipairs(widths) do
    if virtcol >= pos + 1 and virtcol <= pos + w + 2 then return i end
    pos = pos + w + 3
  end
  return nil
end

local function get_cell_at_cursor(float_entry)
  local data = float_entry.data
  if not data then return nil end
  local win = float_entry.win
  if not win or not vim.api.nvim_win_is_valid(win) then return nil end

  local cursor = vim.api.nvim_win_get_cursor(win)
  local line_idx = cursor[1]

  if not (data.rows and line_idx >= 1 and line_idx <= #data.rows) then
    return nil
  end

  local col_idx = data.widths and get_col_at_virtcol(data.widths, vim.fn.virtcol(".")) or 1
  col_idx = col_idx or 1

  return {
    row    = line_idx,
    col    = col_idx,
    value  = (data.rows[line_idx] and data.rows[line_idx][col_idx]) or "",
    header = (data.headers and data.headers[col_idx]) or "",
    all_data = data,
  }
end

-- ── Cell actions ───────────────────────────────────────────────────────────

local function expand_cell(float_entry)
  local cell = get_cell_at_cursor(float_entry)
  if not cell then return end

  local content = tostring(cell.value)
  local content_lines = vim.split(content, "\n", { plain = true })
  table.insert(content_lines, 1, "")
  table.insert(content_lines, 2, " " .. cell.header)
  table.insert(content_lines, 3, string.rep("─", math.max(dw(cell.header) + 2, 20)))
  table.insert(content_lines, 4, "")

  local popup_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, content_lines)
  vim.api.nvim_buf_set_option(popup_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(popup_buf, "modifiable", false)

  local max_w = 40
  for _, l in ipairs(content_lines) do max_w = math.max(max_w, dw(l)) end

  local float_win = float_entry.win
  local popup_h = math.min(#content_lines, 30)
  local popup_w = math.min(max_w + 4, math.floor(vim.o.columns * 0.6))

  local float_screen_row = vim.api.nvim_win_get_position(float_win)[1]
  local float_screen_col = vim.api.nvim_win_get_position(float_win)[2]
  local popup_row = float_screen_row - popup_h - 2
  if popup_row < 0 then popup_row = 0 end

  local popup_win = vim.api.nvim_open_win(popup_buf, true, {
    relative = "editor",
    row = popup_row,
    col = float_screen_col,
    width = popup_w,
    height = popup_h,
    style = "minimal",
    border = "rounded",
    focusable = true,
    zindex = 100,
  })

  vim.api.nvim_win_set_option(popup_win, "wrap", true)
  vim.api.nvim_win_set_option(popup_win, "linebreak", true)

  local hl = vim.api.nvim_create_namespace("sundb_expand")
  vim.api.nvim_buf_add_highlight(popup_buf, hl, "Title", 1, 0, -1)

  local function close_popup()
    if vim.api.nvim_win_is_valid(popup_win) then vim.api.nvim_win_close(popup_win, true) end
    if vim.api.nvim_win_is_valid(float_win) then vim.api.nvim_set_current_win(float_win) end
  end
  vim.keymap.set("n", "q",     close_popup, { buffer = popup_buf })
  vim.keymap.set("n", "<Esc>", close_popup, { buffer = popup_buf })
  vim.keymap.set("n", "yy", function()
    vim.fn.setreg("+", content)
    vim.notify("Copied to clipboard", vim.log.levels.INFO)
    close_popup()
  end, { buffer = popup_buf })
end

local function copy_row_csv(float_entry)
  local data = float_entry.data
  if not data then return end
  local win = float_entry.win
  if not win or not vim.api.nvim_win_is_valid(win) then return end

  local line_idx = vim.api.nvim_win_get_cursor(win)[1]
  local values
  if data.rows and line_idx >= 1 and line_idx <= #data.rows then
    values = data.rows[line_idx]
  end
  if not values then return end

  local parts = {}
  for _, v in ipairs(values) do
    local s = tostring(v)
    if s:find('[,"\n\r]') then s = '"' .. s:gsub('"', '""') .. '"' end
    table.insert(parts, s)
  end
  vim.fn.setreg("+", table.concat(parts, ","))
  vim.notify("Row copied as CSV", vim.log.levels.INFO)
end

local function copy_cell(float_entry)
  local cell = get_cell_at_cursor(float_entry)
  if not cell then return end
  vim.fn.setreg("+", tostring(cell.value))
  vim.notify("Copied: " .. cell.header, vim.log.levels.INFO)
end

-- ── Float close helpers ────────────────────────────────────────────────────

local function close_float_entry(f, editor_buf)
  if f.float_group then
    pcall(vim.api.nvim_del_augroup_by_id, f.float_group)
  end
  if f.header_win and vim.api.nvim_win_is_valid(f.header_win) then
    pcall(vim.api.nvim_win_close, f.header_win, true)
  end
  if f.header_buf and vim.api.nvim_buf_is_valid(f.header_buf) then
    pcall(vim.api.nvim_buf_delete, f.header_buf, { force = true })
  end
  if f.win and vim.api.nvim_win_is_valid(f.win) then
    pcall(vim.api.nvim_win_close, f.win, true)
  end
  if f.buf and vim.api.nvim_buf_is_valid(f.buf) then
    pcall(vim.api.nvim_buf_delete, f.buf, { force = true })
  end
  if f.extmark_id and editor_buf and state.valid_buf(editor_buf) then
    pcall(vim.api.nvim_buf_del_extmark, editor_buf, ns, f.extmark_id)
  end
end

local function close_float_at(stmt_line)
  local editor_buf = state.state.editor.buf
  for i = #floats, 1, -1 do
    if floats[i].stmt_line == stmt_line then
      close_float_entry(floats[i], editor_buf)
      table.remove(floats, i)
    end
  end
end

-- ── Keymaps ────────────────────────────────────────────────────────────────

function M.set_keymaps(buf, float_entry)
  local function back()
    local ew = state.state.editor.win
    if state.valid_win(ew) then vim.api.nvim_set_current_win(ew) end
  end

  vim.keymap.set("n", "q", function()
    back(); close_float_at(float_entry.stmt_line)
  end, { buffer = buf, desc = "Close results" })

  vim.keymap.set("n", "<Esc>", back, { buffer = buf, desc = "Back to editor" })

  vim.keymap.set("n", "<CR>", function() expand_cell(float_entry) end, { buffer = buf })
  vim.keymap.set("n", "e",   function() expand_cell(float_entry) end, { buffer = buf })
  vim.keymap.set("n", "yr",  function() copy_row_csv(float_entry) end, { buffer = buf })
  vim.keymap.set("n", "yc",  function() copy_cell(float_entry) end,    { buffer = buf })
end

-- ── make_win_minimal: set standard minimal options on a float ──────────────

local function make_win_minimal(win)
  vim.api.nvim_win_set_option(win, "number",         false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)
  vim.api.nvim_win_set_option(win, "signcolumn",     "no")
  vim.api.nvim_win_set_option(win, "foldcolumn",     "0")
  vim.api.nvim_win_set_option(win, "colorcolumn",    "")
  vim.api.nvim_win_set_option(win, "wrap",           false)
  vim.api.nvim_win_set_option(win, "list",           false)
end

-- ── Public API ─────────────────────────────────────────────────────────────

function M.show_inline(result, env, db, stmt_end_line)
  local editor_buf = state.state.editor.buf
  local editor_win = state.state.editor.win
  if not state.valid_buf(editor_buf) or not state.valid_win(editor_win) then return end

  close_float_at(stmt_end_line)

  -- No column data: simple single float
  if not result.headers or #result.headers == 0 then
    local title = string.format(" 0 rows │ %.2fs │ %s/%s ", result.elapsed or 0, env or "?", db or "?")
    local content = { " (no results)" }
    M._open_simple(editor_buf, editor_win, stmt_end_line, content, title, false)
    return
  end

  local widths = compute_col_widths(result.headers, result.rows)
  local title = string.format(" %d rows │ %.2fs │ %s/%s ",
    result.row_count or 0, result.elapsed or 0, env or "?", db or "?")

  -- Header float buffer: 3 lines
  local header_lines = {
    render_top_border(widths, title),
    render_row(result.headers, widths),
    render_border(widths, "├", "┼", "┤"),
  }

  -- Data float buffer: ALL data rows + bottom border (window height is capped separately)
  local data_lines = {}
  for i = 1, #result.rows do
    table.insert(data_lines, render_row(result.rows[i], widths))
  end
  table.insert(data_lines, render_border(widths, "╰", "┴", "╯"))

  -- Width = longest line, capped to editor width
  local max_w = 0
  for _, l in ipairs(header_lines) do max_w = math.max(max_w, dw(l)) end
  for _, l in ipairs(data_lines)  do max_w = math.max(max_w, dw(l)) end
  local editor_width = vim.api.nvim_win_get_width(editor_win)
  local width = math.min(max_w, editor_width - 4)

  local HEADER_H = 3
  -- Window height capped at MAX_DATA_ROWS; buffer has all rows for scrolling
  local data_win_h = math.min(#result.rows, MAX_DATA_ROWS) + 1  -- +1 for bottom border

  -- Virtual lines to reserve editor space for both floats
  local virt_count = HEADER_H + data_win_h
  local virt_lines = {}
  for _ = 1, virt_count do table.insert(virt_lines, { { " ", "Normal" } }) end
  local extmark_id = vim.api.nvim_buf_set_extmark(editor_buf, ns, stmt_end_line - 1, 0, {
    virt_lines = virt_lines,
    virt_lines_above = false,
  })

  local win_row = get_win_row(editor_win, stmt_end_line) or 0

  -- ── Header float (non-focusable, no border) ────────────────────────────
  local header_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(header_buf, 0, -1, false, header_lines)
  vim.api.nvim_buf_set_option(header_buf, "buftype",   "nofile")
  vim.api.nvim_buf_set_option(header_buf, "modifiable", false)
  vim.api.nvim_buf_set_option(header_buf, "buflisted",  false)
  vim.api.nvim_buf_set_option(header_buf, "swapfile",   false)

  local header_win = vim.api.nvim_open_win(header_buf, false, {
    relative   = "win",
    win        = editor_win,
    row        = win_row + 1,
    col        = 1,
    width      = width,
    height     = HEADER_H,
    style      = "minimal",
    focusable  = false,
    zindex     = 50,
  })
  make_win_minimal(header_win)
  -- Header row highlight
  local hhl = vim.api.nvim_create_namespace("sundb_hdr_" .. stmt_end_line)
  vim.api.nvim_buf_add_highlight(header_buf, hhl, "Title",   0, 0, -1)  -- top border
  vim.api.nvim_buf_add_highlight(header_buf, hhl, "Title",   1, 0, -1)  -- header row
  vim.api.nvim_buf_add_highlight(header_buf, hhl, "NonText", 2, 0, -1)  -- separator

  -- ── Data float (focusable, no border) ─────────────────────────────────
  local data_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(data_buf, 0, -1, false, data_lines)
  vim.api.nvim_buf_set_option(data_buf, "buftype",   "nofile")
  vim.api.nvim_buf_set_option(data_buf, "modifiable", false)
  vim.api.nvim_buf_set_option(data_buf, "buflisted",  false)
  vim.api.nvim_buf_set_option(data_buf, "swapfile",   false)

  local data_win = vim.api.nvim_open_win(data_buf, false, {
    relative  = "win",
    win       = editor_win,
    row       = win_row + 1 + HEADER_H,
    col       = 1,
    width     = width,
    height    = data_win_h,
    style     = "minimal",
    focusable = true,
    zindex    = 50,
  })
  make_win_minimal(data_win)
  vim.api.nvim_win_set_option(data_win, "cursorline", true)

  -- Highlight borders in data buf
  local dhl = vim.api.nvim_create_namespace("sundb_dat_" .. stmt_end_line)
  vim.api.nvim_buf_add_highlight(data_buf, dhl, "NonText", #data_lines - 1, 0, -1)  -- bottom border

  -- ── Horizontal scroll: h/l on data_buf, synced to header_win ──────────
  local float_group = vim.api.nvim_create_augroup("sundb_float_" .. data_win, { clear = true })

  -- Sync header leftcol whenever data_win scrolls horizontally
  vim.api.nvim_create_autocmd("WinScrolled", {
    group    = float_group,
    callback = function(ev)
      if tonumber(ev.match) ~= data_win then return end
      if not vim.api.nvim_win_is_valid(data_win) then return end
      if not vim.api.nvim_win_is_valid(header_win) then return end
      local leftcol = vim.api.nvim_win_call(data_win, function()
        return vim.fn.winsaveview().leftcol
      end)
      vim.api.nvim_win_call(header_win, function()
        vim.fn.winrestview({ leftcol = leftcol })
      end)
    end,
  })

  local function hscroll(n, dir)
    vim.api.nvim_win_call(data_win, function()
      vim.cmd("normal! " .. n .. dir)
    end)
  end

  vim.keymap.set("n", "h", function() hscroll(3,  "zh") end, { buffer = data_buf, desc = "Scroll left" })
  vim.keymap.set("n", "l", function() hscroll(3,  "zl") end, { buffer = data_buf, desc = "Scroll right" })
  vim.keymap.set("n", "H", function() hscroll(15, "zh") end, { buffer = data_buf, desc = "Scroll left fast" })
  vim.keymap.set("n", "L", function() hscroll(15, "zl") end, { buffer = data_buf, desc = "Scroll right fast" })
  vim.keymap.set("n", "0", function()
    vim.api.nvim_win_call(data_win, function() vim.cmd("normal! 0zs") end)
    -- WinScrolled will sync header
  end, { buffer = data_buf, desc = "Scroll to start" })

  local float_entry = {
    win        = data_win,
    buf        = data_buf,
    header_win = header_win,
    header_buf = header_buf,
    header_h   = HEADER_H,
    data_h     = data_win_h,
    extmark_id = extmark_id,
    stmt_line  = stmt_end_line,
    float_group = float_group,
    data       = { headers = result.headers, rows = result.rows, widths = widths },
  }
  table.insert(floats, float_entry)
  M.set_keymaps(data_buf, float_entry)

  ensure_reposition_autocmds(editor_buf, editor_win)
end

function M.show_error_inline(err_msg, env, db, elapsed, stmt_end_line)
  local editor_buf = state.state.editor.buf
  local editor_win = state.state.editor.win
  if not state.valid_buf(editor_buf) or not state.valid_win(editor_win) then return end

  close_float_at(stmt_end_line)

  local title = string.format(" ERROR │ %.2fs │ %s/%s ", elapsed or 0, env or "?", db or "?")
  local content = { "", "  " .. err_msg:gsub("\n", "\n  ") }
  M._open_simple(editor_buf, editor_win, stmt_end_line, content, title, true)
end

-- Single-float fallback (errors / no-result messages)
function M._open_simple(editor_buf, editor_win, stmt_end_line, content, title, is_error)
  local max_w = 0
  for _, line in ipairs(content) do max_w = math.max(max_w, dw(line)) end
  local editor_width = vim.api.nvim_win_get_width(editor_win)
  local width = math.min(max_w + 4, editor_width - 4)
  local height = math.min(#content, MAX_DATA_ROWS + 2)

  local virt_count = height + 2
  local virt_lines = {}
  for _ = 1, virt_count do table.insert(virt_lines, { { " ", "Normal" } }) end
  local extmark_id = vim.api.nvim_buf_set_extmark(editor_buf, ns, stmt_end_line - 1, 0, {
    virt_lines = virt_lines,
    virt_lines_above = false,
  })

  local win_row = get_win_row(editor_win, stmt_end_line) or 0
  local result_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(result_buf, "buftype",    "nofile")
  vim.api.nvim_buf_set_option(result_buf, "modifiable", false)
  vim.api.nvim_buf_set_option(result_buf, "buflisted",  false)
  vim.api.nvim_buf_set_option(result_buf, "swapfile",   false)

  local safe_title = title and title:gsub("%%", "%%%%") or ""
  local float_win = vim.api.nvim_open_win(result_buf, false, {
    relative   = "win",
    win        = editor_win,
    row        = win_row + 1,
    col        = 1,
    width      = width,
    height     = height,
    border     = "rounded",
    title      = safe_title,
    title_pos  = "left",
    focusable  = true,
    zindex     = 50,
  })
  make_win_minimal(float_win)

  if is_error then
    vim.api.nvim_win_set_option(float_win, "winhl",
      "Normal:DiagnosticError,FloatBorder:DiagnosticError")
  end

  local float_group = vim.api.nvim_create_augroup("sundb_float_" .. float_win, { clear = true })
  local float_entry = {
    win        = float_win,
    buf        = result_buf,
    data_h     = height,
    extmark_id = extmark_id,
    stmt_line  = stmt_end_line,
    float_group = float_group,
    data       = nil,
  }
  table.insert(floats, float_entry)
  M.set_keymaps(result_buf, float_entry)

  ensure_reposition_autocmds(editor_buf, editor_win)
end

function M.focus_nearest(cursor_line)
  local best, best_dist = nil, math.huge
  for _, f in ipairs(floats) do
    if f.win and vim.api.nvim_win_is_valid(f.win) then
      local dist = cursor_line - f.stmt_line
      if dist >= 0 and dist < best_dist then best, best_dist = f, dist end
    end
  end
  if best then vim.api.nvim_set_current_win(best.win); return true end
  return false
end

function M.close_all()
  local editor_buf = state.state.editor.buf
  for i = #floats, 1, -1 do close_float_entry(floats[i], editor_buf) end
  floats = {}
  if reposition_group then
    pcall(vim.api.nvim_del_augroup_by_id, reposition_group)
    reposition_group = nil
  end
end

return M
