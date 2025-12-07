return {
  {
    "numToStr/Comment.nvim",
    enabled = false,
  },
  {
    "nvim-mini/mini.comment",
    event = "VeryLazy",
    opts = {
      options = {
        custom_commentstring = function()
          -- Get the current filetype
          local ft = vim.bo.filetype
          
          -- For blade files, use blade comment syntax
          if ft == "blade" then
            return "{{-- %s --}}"
          end
          
          -- For php in blade context, check if we're in a blade directive
          if ft == "php" then
            local line = vim.api.nvim_get_current_line()
            if line:match("@") or line:match("{{") then
              return "{{-- %s --}}"
            end
          end
          
          -- Default to treesitter/built-in commentstring
          return require("ts_context_commentstring.internal").calculate_commentstring()
            or vim.bo.commentstring
        end,
      },
    },
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = {
      enable_autocmd = false,
    },
  },
}
