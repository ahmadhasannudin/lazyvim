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
          -- Blade parser returns "blade" for ALL positions via language_for_range,
          -- so we walk the treesitter node ancestor chain to detect the real context.
          --
          -- Key discriminators (tested against EmranMR/tree-sitter-blade):
          --   @php...@endphp  → php_statement WITH directive_start child  → // %s
          --   {{ $var }}, @if → php_statement WITHOUT directive_start child → {{-- %s --}}
          --   <script>        → script_element ancestor                      → // %s
          --   everything else → blade/html fallback                          → {{-- %s --}}
          local buf = vim.api.nvim_get_current_buf()
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local ok, parser = pcall(vim.treesitter.get_parser, buf)
          if ok and parser then
            parser:parse()
            local trees = parser:trees()
            if trees and trees[1] then
              local node = trees[1]:root():named_descendant_for_range(row - 1, col, row - 1, col)
              local n = node
              while n do
                local t = n:type()
                -- JS: <script>...</script>
                if t == "script_element" then
                  return "// %s"
                end
                -- PHP: only @php...@endphp blocks (have directive_start child)
                -- NOT blade echo {{ }} or @if/@foreach (no directive_start child)
                if t == "php_statement" then
                  for child in n:iter_children() do
                    if child:type() == "directive_start" then
                      return "// %s"
                    end
                  end
                  break -- blade echo/directive → fall through to {{-- %s --}}
                end
                n = n:parent()
              end
            end
          end

          -- Fallback: ts_context_commentstring handles plain php/js/html/etc. files
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
      languages = {
        -- Blade template context (outside PHP/HTML/JS blocks)
        blade = "{{-- %s --}}",
      },
    },
  },
}
