-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Last Buffer
vim.keymap.set("i", "jk", "<Esc>", { desc = "Escape from Insert mode" })
vim.keymap.del("n", "<leader><leader>")
vim.keymap.set("n", "<leader><leader>", "<C-^>", { desc = "Switch to last buffer" })
-- select all
vim.keymap.set("n", "<D-a>", "gg<S-v>G", { desc = "Select all" })
--[[ leader w to save  ]]
--[[ vim.keymap.set("n", "<leader>w", ":w<C-R>", { desc = "Save file" }) ]]
vim.opt.mouse = ""
-- vim.opt.clipboard = "unnamedplus"

-- Custom save function that suppresses messages
local function save_file()
  vim.cmd("silent! write")
  vim.api.nvim_command("redraw")
end

-- Cmd+S to save
vim.keymap.set("n", "<D-s>", save_file, { desc = "Save file" })
vim.keymap.set("i", "<D-s>", function()
  save_file()
end, { desc = "Save file" })
vim.keymap.set("v", "<D-s>", function()
  vim.cmd("normal! gv")
  save_file()
end, { desc = "Save file and restore selection" })

-- make selection then cmd+c to copy to system clipboard
vim.keymap.set("v", "<D-c>", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<D-v>", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("v", "<D-v>", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("i", "<D-v>", "<C-R>+", { desc = "Paste from system clipboard" })

-- Copy full path
vim.keymap.set("n", "<leader>yfp", function()
  local full_path = vim.fn.expand("%:p")
  vim.fn.setreg("+", full_path)
  vim.notify("Copied full path: " .. full_path)
end, { desc = "Copy full file path" })

-- Copy relative path
--[[ vim.keymap.set("n", "<leader>yrp", function()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  local file_path = vim.fn.expand("%:p")
  local relative_path = file_path:sub(#git_root + 2) -- remove git root + '/'
  vim.fn.setreg("+", relative_path)
  vim.notify("Copied relative path (git root): " .. relative_path)
end, { desc = "Copy relative file path from git root" }) ]]

vim.keymap.set("n", "<leader>yrp", function()
  local relative_path = vim.fn.fnamemodify(vim.fn.expand("%"), ":.")
  vim.fn.setreg("+", relative_path)
  vim.notify("Copied relative path: " .. relative_path)
end, { desc = "Copy relative file path" })

-- Custom <Esc> behavior for dismissing Copilot/cmp suggestions without leaving insert mode
-- This was moved to lua/plugins/cmp.lua to ensure cmp is loaded.

-- Keymaps for commenting
vim.keymap.set("n", "<D-/>", function()
  vim.cmd("normal gcc")
end, { noremap = true, silent = true, desc = "Toggle line comment" })
vim.keymap.set("v", "<D-/>", function()
  vim.cmd("normal gc")
end, { noremap = true, silent = true, desc = "Toggle line comment" })

-- Navigate to symbols (like Cmd+Shift+O in VSCode)
vim.keymap.set("n", "<D-S-o>", function()
  require("snacks.picker").lsp_symbols()
end, { desc = "Go to Symbol" })

-- PHP-specific keybinding: - to add semicolon at end of line
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "php", "blade" },
  callback = function()
    vim.keymap.set("n", "-", "A;<Esc>", {
      buffer = true,
      desc = "Add semicolon at end of line",
    })
  end,
})
-- Theme Selector (like NvChad)
vim.keymap.set("n", "<leader>th", function()
  require("config.themes").theme_selector_simple()
end, { desc = "Theme Selector" })

-- Insert mode navigation with Ctrl+hjkl
vim.keymap.set("i", "<C-h>", "<Left>", { desc = "Move left in insert mode" })
vim.keymap.set("i", "<C-l>", "<Right>", { desc = "Move right in insert mode" })
vim.keymap.set("i", "<C-j>", "<Down>", { desc = "Move down in insert mode" })
vim.keymap.set("i", "<C-k>", "<Up>", { desc = "Move up in insert mode" })

-- Visual mode keymaps
vim.keymap.set("v", "<Tab>", ">gv", { desc = "Indent and reselect" })
vim.keymap.set("v", "<S-Tab>", "<gv", { desc = "Unindent and reselect" })
vim.keymap.set("v", "y", "ygv<Esc>", { desc = "Yank and reselect" })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Normal mode keymaps
-- vim.keymap.set("n", "<leader>h", "^", { desc = "Go to first non-blank character" })
-- vim.keymap.set("n", "<leader>l", "$", { desc = "Go to end of line" })
vim.keymap.set("n", "J", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "K", ":m .-2<CR>==", { noremap = true, silent = true, desc = "Move line up" })

-- Override K mapping after LSP attaches
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.keymap.set(
      "n",
      "K",
      ":m .-2<CR>==",
      { buffer = args.buf, noremap = true, silent = true, desc = "Move line up" }
    )
  end,
})

-- SFTP Commands
local sftp = require("config.sftp")

-- Leader f -> Upload folder (with prompt)
vim.keymap.set("n", "<leader>fU", function()
  sftp.upload_folder_prompt()
end, { desc = "SFTP: Upload Folder" })

-- Leader d -> Download current buffer
vim.keymap.set("n", "<leader>fd", function()
  sftp.download_current_buffer()
end, { desc = "SFTP: Download Current File" })

-- Leader D -> Download folder (with prompt)
vim.keymap.set("n", "<leader>fD", function()
  sftp.download_folder_prompt()
end, { desc = "SFTP: Download Folder" })

-- SFTP Listener Controls
vim.keymap.set("n", "<leader>fs", function()
  sftp.start()
end, { desc = "SFTP: Start Listener" })

vim.keymap.set("n", "<leader>fS", function()
  sftp.stop()
end, { desc = "SFTP: Stop Listener" })

vim.keymap.set("n", "<leader>ft", function()
  if sftp.is_running() then
    sftp.stop()
    vim.notify("SFTP Listener is running. Stopping it now.")
  else
    sftp.start()
    vim.notify("SFTP Listener is not running. Starting it now.")
  end
end, { desc = "SFTP: Toggle Listener" })

-- Ctrl+Q to toggle hover (editor.action.showHover in VSCode)
vim.keymap.set("n", "<C-q>", function()
  -- Check if there's a floating window open (hover)
  local has_float = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    -- Use pcall to safely check window config
    local ok, config = pcall(vim.api.nvim_win_get_config, win)
    if ok and config.relative ~= "" then
      has_float = true
      pcall(vim.api.nvim_win_close, win, false)
    end
  end
  
  -- If no float was open, show hover
  if not has_float then
    vim.lsp.buf.hover()
  end
end, { desc = "Toggle hover (editor.action.showHover)" })

-- Clear highlight
vim.keymap.set("n", "<leader>Q", function()
  vim.cmd("match none")
end, { desc = "Clear word highlight" })

-- Cmd+X to cut line
vim.keymap.set("n", "<D-x>", '"+dd', { desc = "Cut line to system clipboard" })
vim.keymap.set("v", "<D-x>", '"+d', { desc = "Cut selection to system clipboard" })

-- Visual Multi: Add cursors at start of each selected line
vim.keymap.set("v", "<leader>gC", function()
  vim.cmd([[execute "normal! \<Plug>(VM-Visual-Cursors)"]])
  vim.cmd([[execute "normal! I"]])
end, { desc = "Add cursors at start of lines" })

-- Option+Delete (Alt+Backspace) - Delete word backward (token by token)
vim.keymap.set("i", "<M-BS>", "<C-w>", { desc = "Delete word backward" })
vim.keymap.set("i", "<A-BS>", "<C-w>", { desc = "Delete word backward" })
vim.keymap.set("i", "<D-BS>", "<C-o>d0", { desc = "Delete word backward" })

-- Noice Telescope Picker
vim.keymap.set("n", "<leader>n", function()
  require("noice").cmd("telescope")
end, { desc = "Noice Picker (Telescope)" })

-- Delete all buffers except current
vim.keymap.set("n", "<leader>bD", function()
  local current_buf = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current_buf and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype ~= "terminal" then
      vim.api.nvim_buf_delete(buf, { force = false })
    end
  end
  vim.notify("✓ Deleted all buffers except current", vim.log.levels.INFO)
end, { desc = "Delete all buffers except current" })

-- Delete all buffers
vim.keymap.set("n", "<leader>bX", function()
  vim.ui.select({ "Yes", "No" }, {
    prompt = "Delete all buffers?",
  }, function(choice)
    if choice == "Yes" then
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype ~= "terminal" then
          vim.api.nvim_buf_delete(buf, { force = false })
        end
      end
      vim.notify("✓ Deleted all buffers", vim.log.levels.INFO)
    end
  end)
end, { desc = "Delete all buffers" })

-- Fold all functions only (not classes)
vim.keymap.set("n", "<leader>zF", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then
    vim.notify("✗ Treesitter parser not available", vim.log.levels.WARN)
    return
  end

  local tree = parser:parse()[1]
  local root = tree:root()
  local lang = parser:lang()

  -- Define function node types for different languages
  local function_types = {
    javascript = { "function_declaration", "method_definition", "arrow_function" },
    typescript = { "function_declaration", "method_definition", "arrow_function" },
    python = { "function_definition" },
    lua = { "function_declaration", "function_definition" },
    go = { "function_declaration", "method_declaration" },
    php = { "function_definition", "method_declaration", "anonymous_function" },
    rust = { "function_item" },
    java = { "method_declaration" },
    c = { "function_definition" },
    cpp = { "function_definition" },
  }

  local types = function_types[lang]
  if not types then
    vim.notify("✗ Language not supported for function folding: " .. lang, vim.log.levels.WARN)
    return
  end

  -- Save current fold settings
  local saved_foldmethod = vim.wo.foldmethod
  
  -- Set foldmethod to manual to allow manual fold creation
  vim.wo.foldmethod = "manual"
  
  -- First, unfold everything and delete all folds
  vim.cmd("normal! zE")
  vim.cmd("normal! zR")

  local count = 0
  local query_str = "(" .. table.concat(types, ") @func (") .. ") @func"
  local ok, query = pcall(vim.treesitter.query.parse, lang, query_str)
  
  if not ok then
    vim.notify("✗ Failed to create query", vim.log.levels.ERROR)
    vim.wo.foldmethod = saved_foldmethod
    return
  end

  -- Collect all function nodes first
  local function_nodes = {}
  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    table.insert(function_nodes, node)
  end

  -- Sort by line number (reverse order to avoid cursor position issues)
  table.sort(function_nodes, function(a, b)
    local a_start = a:range()
    local b_start = b:range()
    return a_start > b_start
  end)

  -- Create folds for each function
  for _, node in ipairs(function_nodes) do
    local start_row, _, end_row, _ = node:range()
    vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
    vim.cmd(string.format("%d,%dfold", start_row + 1, end_row + 1))
    count = count + 1
  end

  vim.notify("✓ Folded " .. count .. " function(s)", vim.log.levels.INFO)
end, { desc = "Fold all functions only" })

-- Unfold all
vim.keymap.set("n", "<leader>zU", function()
  vim.cmd("normal! zR")
  vim.notify("✓ Unfolded all", vim.log.levels.INFO)
end, { desc = "Unfold all" })
