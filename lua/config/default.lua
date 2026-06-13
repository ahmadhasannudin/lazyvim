-- Or add blank lines in the buffer
vim.o.scrolloff = 8 -- vertical padding when moving cursor
vim.opt.cmdheight = 2 -- more space at the bottom
vim.g.autoformat = false

-- Hide tabline (0 = never, 1 = when 2+ tabs, 2 = always)
vim.opt.showtabline = 0

-- Increase timeout for key combinations (default is 1000ms)
vim.opt.timeoutlen = 2000 -- 2 seconds to complete key combinations like tD, td, te, etc.

-- Tab settings
vim.opt.tabstop = 2 -- number of spaces that a <Tab> in the file counts for
vim.opt.shiftwidth = 2 -- number of spaces to use for each step of (auto)indent
vim.opt.softtabstop = 2 -- number of spaces that a <Tab> counts for while editing
vim.opt.expandtab = true -- use spaces instead of tabs

-- Indentation settings
vim.opt.autoindent = true -- copy indent from current line when starting new line
vim.opt.smartindent = true -- smart autoindenting when starting a new line
vim.opt.copyindent = true -- copy the structure of existing lines indent

vim.opt.wrap = true
-- vim.opt.clipboard = "" -- don't use system clipboard by default

-- Suppress default save messages
vim.opt.shortmess:append("WF")

-- Enable true color support
vim.opt.termguicolors = true

-- Cursor settings
vim.opt.guicursor = "n-v-c:block-blinkwait700-blinkoff400-blinkon250,i-ci-ve:ver25-blinkwait700-blinkoff400-blinkon250,r-cr:hor20-blinkwait700-blinkoff400-blinkon250"
vim.opt.cursorline = true

-- Don't render tab/trail/nbsp markers (the default `tab:> ` makes Go tabs ugly).
vim.opt.list = false

-- Folding: treesitter-based (syntactically correct) with foldcolumn shown.
-- foldlevel=99 means files open fully expanded; you fold what you want with za.
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
-- foldcolumn=0 hides the separate left column; the fold marker is rendered
-- next to the signs via _G.fold_marker() in the statuscolumn instead.
vim.opt.foldcolumn = "0"
vim.opt.fillchars:append({ foldopen = "▾", foldclose = "▸", fold = " ", foldsep = " " })

-- Returns the fold indicator for a given line:
--   ▸ if this line is the start of a closed fold
--   ▾ if this line is the start of an open fold
--   "" otherwise (so non-fold lines don't get extra spacing)
function _G.fold_marker(lnum)
  if vim.fn.foldclosed(lnum) == lnum then return "▸" end
  local cur = vim.fn.foldlevel(lnum)
  local prev = lnum > 1 and vim.fn.foldlevel(lnum - 1) or 0
  if cur > prev then return "▾" end
  return ""
end

-- Disable all animations
-- vim.g.snacks_animate = false




-- coloer highlights for git conflicts
vim.api.nvim_set_hl(0, "GitConflictCurrent", { bg = "#283848" })
vim.api.nvim_set_hl(0, "GitConflictIncoming", { bg = "#3a2a3a" })
vim.api.nvim_set_hl(0, "GitConflictAncestor", { bg = "#303030" })
vim.api.nvim_set_hl(0, "GitConflictSeparator", { fg = "#666666" })
