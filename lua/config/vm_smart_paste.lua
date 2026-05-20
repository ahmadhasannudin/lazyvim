-- VSCode-style "distribute paste" for vim-visual-multi.
-- When the clipboard has the same number of lines as there are VM cursors,
-- each line is pasted at its matching cursor (cursor 1 -> line 1, etc.).
-- Otherwise the standard VM paste (full content at every cursor) is used.

local M = {}

local function in_vm_mode()
  if vim.fn.exists("b:VM_Selection") == 0 then
    return false
  end
  local sel = vim.b.VM_Selection
  return type(sel) == "table" and sel.Regions and #sel.Regions > 0
end

local function clipboard_lines(register)
  local regtype = vim.fn.getregtype(register)
  local content = vim.fn.getreg(register)
  local lines = vim.split(content, "\n", { plain = true })
  -- Linewise registers ('V') have a trailing empty entry from the final \n.
  if regtype:sub(1, 1) == "V" and #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
  end
  return lines, regtype, content
end

local function fallback_vm_paste(register, before)
  -- Call VM's own Edit.paste without an override list so VM applies its
  -- standard behaviour (linewise: ":<reg>p" at each cursor; charwise:
  -- the full text inserted at each cursor) but driven by the register
  -- the user actually invoked paste with -- not v:register.
  vim.cmd(string.format(
    'call b:VM_Selection.Edit.paste(%d, 0, 0, %s)',
    before and 1 or 0,
    vim.fn.string(register)
  ))
end

local function fallback_plain_paste(register, before)
  local key = before and "P" or "p"
  vim.cmd(string.format('normal! "%s%s', register, key))
end

-- Distribute the lines list across VM regions by calling VM's own
-- Edit.paste(..., text_list) entry point. VM's block_paste then walks
-- the regions and pastes one list element at each one.
--
-- VM's Edit.paste short-circuits to a plain ":<reg>p" when the source
-- register is linewise (regtype == 'V'). For the system clipboard ('+'),
-- Neovim re-derives the type from content on every getregtype(), so a
-- temporary setreg('+', ..., 'v') is ignored. Work around this by copying
-- the content into a scratch named register ('z') as charwise and using
-- that as the source register for the VM call. After paste, both the
-- scratch and the original source register are restored.
local SCRATCH_REG = "z"

local function distribute(register, before, lines)
  local saved_src_content = vim.fn.getreg(register)
  local saved_src_type = vim.fn.getregtype(register)
  local saved_scratch_content = vim.fn.getreg(SCRATCH_REG)
  local saved_scratch_type = vim.fn.getregtype(SCRATCH_REG)

  -- Joined content is only consulted by VM if our override list were
  -- ignored; the actual per-region text comes from `lines`.
  vim.fn.setreg(SCRATCH_REG, table.concat(lines, "\n"), "v")

  vim.g._vm_smart_paste_lines = lines
  local ok, err = pcall(function()
    vim.cmd(
      string.format(
        'call b:VM_Selection.Edit.paste(%d, 0, 0, %s, g:_vm_smart_paste_lines)',
        before and 1 or 0,
        vim.fn.string(SCRATCH_REG)
      )
    )
  end)
  vim.g._vm_smart_paste_lines = nil

  vim.fn.setreg(SCRATCH_REG, saved_scratch_content, saved_scratch_type)
  vim.fn.setreg(register, saved_src_content, saved_src_type)

  if not ok then
    vim.notify("vm_smart_paste: " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.paste(opts)
  opts = opts or {}
  local before = opts.before == true
  local register = opts.register
  if not register or register == "" then
    register = vim.v.register
    if not register or register == "" then
      register = '"'
    end
  end

  if not in_vm_mode() then
    fallback_plain_paste(register, before)
    return
  end

  local sel = vim.b.VM_Selection
  local region_count = #sel.Regions
  local lines = clipboard_lines(register)

  if #lines == region_count and region_count > 1 then
    distribute(register, before, lines)
  else
    fallback_vm_paste(register, before)
  end
end

return M
