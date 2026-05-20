-- Headless test harness for vm_smart_paste.
-- Run with:
--   nvim --headless -u init.lua -c "luafile sundb/test_vm_smart_paste.lua" -c "qa!"
--
-- Each scenario writes a buffer, sets up VM regions, calls smart paste,
-- and compares the resulting buffer text against the expected text.

local results = {}

local function fail(name, msg)
  table.insert(results, { name = name, ok = false, msg = msg })
end

local function pass(name)
  table.insert(results, { name = name, ok = true })
end

local function buf_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function reset_buffer(lines)
  vim.cmd("enew!")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local function enter_vm_and_make_line_cursors(line_count)
  -- Visually select first `line_count` lines, then trigger VM-Visual-Cursors
  -- which places one cursor at the start of each selected line.
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("normal! V" .. (line_count - 1) .. "j")
  vim.cmd([[execute "normal \<Plug>(VM-Visual-Cursors)"]])
end

local function region_count()
  if vim.fn.exists("b:VM_Selection") == 0 then return 0 end
  local sel = vim.b.VM_Selection
  if not sel or not sel.Regions then return 0 end
  return #sel.Regions
end

local function exit_vm()
  if vim.fn.exists("b:visual_multi") == 1 then
    vim.cmd([[execute "normal \<Plug>(VM-Exit)"]])
  end
end

-- Force-load vim-visual-multi (it is lazy-loaded via keys in normal use).
pcall(function() require("lazy").load({ plugins = { "vim-visual-multi" } }) end)
vim.g._vm_smart_paste_debug = true
-- VM's mappings install on first invocation in the buffer.

local smart = require("config.vm_smart_paste")

-- ---------------------------------------------------------------------------
-- Scenario 1: 5 cursors, 5 lines in clipboard -- expect distribution.
-- ---------------------------------------------------------------------------
do
  local name = "equal counts distribute one line per cursor"
  reset_buffer({
    "A",
    "B",
    "C",
    "D",
    "E",
    "X1",
    "X2",
    "X3",
    "X4",
    "X5",
  })

  -- Cut lines 6..10 into '+' register (linewise, like dd does).
  vim.fn.setreg("+", "X1\nX2\nX3\nX4\nX5\n", "V")
  vim.api.nvim_buf_set_lines(0, 5, 10, false, {})

  enter_vm_and_make_line_cursors(5)
  if region_count() ~= 5 then
    fail(name, "expected 5 regions, got " .. region_count())
  else
    smart.paste({ before = false, register = "+" })
    exit_vm()
    local got = buf_lines()
    local expected = { "AX1", "BX2", "CX3", "DX4", "EX5" }
    if vim.deep_equal(got, expected) then
      pass(name)
    else
      fail(name, "got=" .. vim.inspect(got) .. " expected=" .. vim.inspect(expected))
    end
  end
end

-- ---------------------------------------------------------------------------
-- Scenario 2: 5 cursors, 3 lines in clipboard -- expect VM default
-- (full clipboard pasted at every cursor).
-- ---------------------------------------------------------------------------
do
  local name = "mismatched (clipboard < cursors) falls back to VM default"
  reset_buffer({ "A", "B", "C", "D", "E" })
  vim.fn.setreg("+", "X1\nX2\nX3\n", "V")
  enter_vm_and_make_line_cursors(5)
  if region_count() ~= 5 then
    fail(name, "expected 5 regions, got " .. region_count())
  else
    smart.paste({ before = false, register = "+" })
    exit_vm()
    local got = buf_lines()
    -- VM's default linewise paste runs ":<reg>p" at each cursor, which
    -- inserts the full clipboard below each cursor's line. We just check
    -- the buffer has grown and is not "distribute" output.
    local distributed_shape = { "AX1", "BX2", "CX3", "DX4", "EX5" }
    if not vim.deep_equal(got, distributed_shape) and #got > 5 then
      pass(name)
    else
      fail(name, "did not fall back to default; got=" .. vim.inspect(got))
    end
  end
end

-- ---------------------------------------------------------------------------
-- Scenario 3: 3 cursors, 5 lines in clipboard -- expect VM default.
-- ---------------------------------------------------------------------------
do
  local name = "mismatched (clipboard > cursors) falls back to VM default"
  reset_buffer({ "A", "B", "C", "D", "E" })
  vim.fn.setreg("+", "X1\nX2\nX3\nX4\nX5\n", "V")
  enter_vm_and_make_line_cursors(3)
  if region_count() ~= 3 then
    fail(name, "expected 3 regions, got " .. region_count())
  else
    smart.paste({ before = false, register = "+" })
    exit_vm()
    local got = buf_lines()
    local distributed_shape = { "AX1", "BX2", "CX3", "D", "E" }
    if not vim.deep_equal(got, distributed_shape) and #got > 5 then
      pass(name)
    else
      fail(name, "did not fall back to default; got=" .. vim.inspect(got))
    end
  end
end

-- ---------------------------------------------------------------------------
-- Scenario 4: Not in VM mode -- plain "+p paste at cursor only.
-- ---------------------------------------------------------------------------
do
  local name = "outside VM mode behaves like plain paste"
  reset_buffer({ "A", "B", "C" })
  vim.fn.setreg("+", "X1\nX2\n", "V")
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  smart.paste({ before = false, register = "+" })
  local got = buf_lines()
  local expected = { "A", "X1", "X2", "B", "C" }
  if vim.deep_equal(got, expected) then
    pass(name)
  else
    fail(name, "got=" .. vim.inspect(got) .. " expected=" .. vim.inspect(expected))
  end
end

-- ---------------------------------------------------------------------------
-- Scenario 5: equal counts, charwise clipboard (yanked text without \n).
-- Mimics yanking 5 single-line items into a single string -- treat as 1 line.
-- ---------------------------------------------------------------------------
do
  local name = "charwise single-line clipboard with 5 cursors falls back"
  reset_buffer({ "A", "B", "C", "D", "E" })
  vim.fn.setreg("+", "XYZ", "v")
  enter_vm_and_make_line_cursors(5)
  smart.paste({ before = false, register = "+" })
  exit_vm()
  local got = buf_lines()
  -- Should NOT distribute (only 1 clipboard line vs 5 cursors).
  if not vim.deep_equal(got, { "AXYZ", "BXYZ", "CXYZ", "DXYZ", "EXYZ" }) then
    -- VM's default behaviour for charwise puts the same text at each cursor.
    -- That matches the "AXYZ..." shape above, so passing this case actually
    -- means VM default ran. Re-evaluate: this IS the expected shape.
    fail(name, "unexpected: got=" .. vim.inspect(got))
  else
    pass(name)
  end
end

-- ---------------------------------------------------------------------------
-- Scenario 6: exact user flow -- cut 5 lines with "+dd, visual-select 5 lines,
-- gC to place cursors, then smart-paste from + register.
-- ---------------------------------------------------------------------------
do
  local name = "end-to-end: dd into + then distribute back to 5 cursors"
  reset_buffer({
    "L1",
    "L2",
    "L3",
    "L4",
    "L5",
    "A",
    "B",
    "C",
    "D",
    "E",
  })
  -- Cut lines 1..5 into '+' (linewise, mirrors the user's <D-x> binding).
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd('normal! "+5dd')
  -- Now buffer is L1=A..L5=E, clipboard '+' holds L1..L5 linewise.
  enter_vm_and_make_line_cursors(5)
  if region_count() ~= 5 then
    fail(name, "expected 5 regions, got " .. region_count())
  else
    smart.paste({ before = false, register = "+" })
    exit_vm()
    local got = buf_lines()
    local expected = { "AL1", "BL2", "CL3", "DL4", "EL5" }
    if vim.deep_equal(got, expected) then
      pass(name)
    else
      fail(name, "got=" .. vim.inspect(got) .. " expected=" .. vim.inspect(expected))
    end
  end
end

-- ---------------------------------------------------------------------------
-- Scenario 7: distribute through unnamed register (the path that "p" takes).
-- ---------------------------------------------------------------------------
do
  local name = "distribute via unnamed register (p keymap path)"
  reset_buffer({
    "a",
    "b",
    "c",
    "X1",
    "X2",
    "X3",
  })
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  vim.cmd("normal! 3dd")
  -- '"' now holds X1..X3 linewise; buffer is a, b, c.
  enter_vm_and_make_line_cursors(3)
  if region_count() ~= 3 then
    fail(name, "expected 3 regions, got " .. region_count())
  else
    smart.paste({ before = false, register = '"' })
    exit_vm()
    local got = buf_lines()
    local expected = { "aX1", "bX2", "cX3" }
    if vim.deep_equal(got, expected) then
      pass(name)
    else
      fail(name, "got=" .. vim.inspect(got) .. " expected=" .. vim.inspect(expected))
    end
  end
end

-- ---------------------------------------------------------------------------
-- Report
-- ---------------------------------------------------------------------------
local total = #results
local passed = 0
for _, r in ipairs(results) do
  if r.ok then
    passed = passed + 1
    io.write(string.format("[PASS] %s\n", r.name))
  else
    io.write(string.format("[FAIL] %s -- %s\n", r.name, r.msg))
  end
end
io.write(string.format("\n%d/%d tests passed\n", passed, total))

if passed ~= total then
  vim.cmd("cquit 1")
end
