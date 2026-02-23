local M = {}

function M.get_title()
  -- Try to get workspace name first
  local ok, workspaces = pcall(require, "workspaces")
  if ok then
    local workspace_name = workspaces.name()
    if workspace_name and workspace_name ~= "" then
      return "NVIM - " .. workspace_name
    end
  end
  
  -- Fallback to project root detection
  local project_root = vim.fs.root(0, { ".git", "package.json", ".project-root" })
  if project_root then
    local root_name = vim.fn.fnamemodify(project_root, ":t")
    return "NVIM - " .. root_name
  end
  
  -- Final fallback
  return "NVIM"
end

return M
