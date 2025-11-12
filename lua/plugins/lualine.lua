return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function()
    local function get_project_root()
      local file_path = vim.api.nvim_buf_get_name(0)
      
      -- Try to get workspace name first
      local ok, workspaces = pcall(require, "workspaces")
      if ok then
        local workspace_name = workspaces.name()
        if workspace_name and workspace_name ~= "" then
          return " " .. workspace_name .. "/" .. vim.fn.pathshorten(vim.fn.fnamemodify(file_path, ":."))
        end
      end
      
      -- Fallback to project root detection
      local project_root = vim.fs.root(0, { ".git", "package.json", ".project-root" })
      if project_root then
        return " " .. vim.fn.fnamemodify(project_root, ":t") .. "/" .. vim.fn.pathshorten(vim.fn.fnamemodify(file_path, ":."))
      end
      return ""
    end

    local function get_time()
      return os.date("%H:%M")
    end

    local function copilot_status()
      local ok, copilot_api = pcall(require, "copilot.api")
      if not ok then
        return ""
      end
      
      local status = copilot_api.status.data
      if not status then
        return "󰚩 "
      end
      
      if status.status == "InProgress" then
        return "󰚩 ..."
      elseif status.status == "Normal" then
        return "󰚩 "
      elseif status.status == "Warning" then
        return "󰚩 "
      else
        return "󰚩 "
      end
    end

    return {
      options = {
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { get_project_root },
        lualine_x = { copilot_status, "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { get_time, "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
    }
  end,
}
