-- ============================================
-- GLOBAL SETTINGS - Configure everything here
-- ============================================
local SETTINGS = {
  auto_format_on_save = false, -- Set to true to enable auto-format on save
  follow_existing_indentation = true, -- Set to false to use smart indentation instead of copying line above when using 'o' or 'O'
}
-- ============================================

-- Apply settings IMMEDIATELY
vim.g.autoformat = SETTINGS.auto_format_on_save
vim.b.autoformat = SETTINGS.auto_format_on_save
vim.g.editorconfig = SETTINGS.auto_format_on_save
vim.g.SETTINGS = SETTINGS -- Make available globally

-- Configure indentation behavior for 'o' and 'O' commands
if SETTINGS.follow_existing_indentation then
  vim.opt.copyindent = true -- Copy the structure of existing lines
  vim.opt.preserveindent = true -- Preserve existing indentation structure
  vim.opt.autoindent = true -- Enable autoindent
  vim.opt.smartindent = false -- Disable smartindent to truly follow existing indent
  vim.opt.cindent = false -- Disable cindent
  vim.opt.indentexpr = "" -- Disable indent expressions globally
  
  -- Ensure settings persist after ALL plugins load (including LazyVim treesitter)
  vim.api.nvim_create_autocmd({"FileType", "BufEnter", "BufWinEnter", "BufReadPost"}, {
    pattern = "*",
    callback = function()
      -- Delay to ensure this runs AFTER LazyVim's indentexpr is set
      vim.schedule(function()
        vim.opt_local.copyindent = true
        vim.opt_local.preserveindent = true
        vim.opt_local.autoindent = true
        vim.opt_local.smartindent = false
        vim.opt_local.cindent = false
        vim.opt_local.indentexpr = "" -- Clear LazyVim's treesitter indentexpr
        vim.opt_local.lisp = false
      end)
    end,
  })
else
  vim.opt.copyindent = false
  vim.opt.preserveindent = false
  vim.opt.smartindent = true -- Enable smart indenting
end

-- Block LSP formatting on save if disabled
if not SETTINGS.auto_format_on_save then
  vim.g.disable_autoformat = true
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Ensure autoformat respects settings after lazy loads
vim.schedule(function()
  vim.g.autoformat = SETTINGS.auto_format_on_save
end)

-- Load default settings
require("config.default")

-- Load saved theme
require("config.themes").load_theme()

-- Load custom highlights
require("config.highlights")

-- SFTP Upload on Save
local sftp = require("config.sftp")

-- Auto-start SFTP listener (will restart if already running)
sftp.auto_start()

-- Suppress write messages
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("suppress_write_msg", { clear = true }),
  pattern = "*",
  callback = function()
    vim.opt_local.shortmess:append("W")
  end,
})

-- Create an autocommand group
local group = vim.api.nvim_create_augroup("SFTPUpload", { clear = true })

-- Trigger on BufWritePost (after file is saved) for ALL files
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = "*",
  callback = function()
    local filepath = vim.fn.expand("%:p")
    local filename = vim.fn.expand("%:t")
    
    -- Clear command line and show custom save message
    vim.schedule(function()
      vim.api.nvim_command("redraw")
      if filename ~= "" then
        vim.notify("💾 " .. filename, vim.log.levels.INFO)
      end
    end)
    
    sftp.upload(filepath)
  end,
})

vim.notify("✓ SFTP upload on save enabled (auto-detect projects)")
