return {
  "mluders/comfy-line-numbers.nvim",
  opts = {},
  config = function(_, opts)
    require("comfy-line-numbers").setup(opts)

    -- Snacks' picker list uses the "minimal" window style, which sets
    -- number=false / relativenumber=false / statuscolumn="". On top of that,
    -- comfy-line-numbers' own autocmd reclears statuscolumn for every
    -- nofile buftype on BufEnter / WinEnter / InsertEnter / InsertLeave,
    -- so any one-shot fix gets wiped the moment focus moves. Replace
    -- comfy's autocmd group (same name + clear=true wipes its handlers)
    -- with one that treats snacks_picker_list as a special case.
    local PICKER_LIST = "snacks_picker_list"
    local STATUSCOLUMN = '%=%s%=%{v:virtnum > 0 ? "" : v:lua.get_label(v:lnum, v:relnum)} '

    local function apply_for_picker_list(win, buf)
      vim.api.nvim_win_call(win, function()
        vim.wo.number = true
        vim.wo.relativenumber = true
        vim.wo.numberwidth = math.max(4, #tostring(vim.api.nvim_buf_line_count(buf)))
        vim.wo.statuscolumn = STATUSCOLUMN
      end)
    end

    local function apply_default(win, buf)
      vim.api.nvim_win_call(win, function()
        vim.wo.numberwidth = math.max(4, #tostring(vim.api.nvim_buf_line_count(buf)))
        vim.wo.statuscolumn = STATUSCOLUMN
      end)
    end

    local function clear(win)
      vim.api.nvim_win_call(win, function()
        vim.wo.statuscolumn = ""
      end)
    end

    local function update()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].filetype
        local bt = vim.bo[buf].buftype
        if ft == PICKER_LIST then
          apply_for_picker_list(win, buf)
        elseif bt == "terminal" or bt == "nofile" or ft == "undotree" then
          clear(win)
        else
          apply_default(win, buf)
        end
      end
    end

    -- Reuse the same group name so this REPLACES comfy's handlers rather
    -- than racing with them.
    local grp = vim.api.nvim_create_augroup("ComfyLineNumbers", { clear = true })
    vim.api.nvim_create_autocmd(
      { "WinNew", "BufWinEnter", "BufEnter", "TermOpen", "InsertEnter", "InsertLeave", "FileType" },
      { group = grp, callback = update }
    )
  end,
}
