return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      return {
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          lsp_doc_border = true,
        },
        cmdline = {
          enabled = true,
          view = "cmdline_popup",
        },
        messages = {
          enabled = true,
          view = "mini",
          view_error = "mini",
          view_warn = "mini",
        },
        notify = {
          enabled = true,
          view = "mini",
        },
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
          progress = {
            enabled = false,
          },
          message = {
            enabled = true,
            view = "mini",
          },
        },
        routes = {
          {
            filter = {
              event = "notify",
            },
            view = "mini",
          },
          {
            filter = {
              event = "msg_show",
              kind = "",
            },
            view = "mini",
          },
          {
            filter = {
              event = "msg_show",
              kind = "echo",
            },
            view = "mini",
          },
          {
            filter = {
              event = "msg_show",
              kind = "echomsg",
            },
            view = "mini",
          },
        },
        views = {
          mini = {
            backend = "mini",
            relative = "editor",
            align = "message-right",
            timeout = 3000,
            reverse = true,
            position = {
              row = -2,
              col = "100%",
            },
            size = {
              width = "auto",
              height = "auto",
              max_height = 15,
            },
            border = {
              style = "rounded",
            },
            zindex = 60,
            win_options = {
              winblend = 0,
              winhighlight = {
                Normal = "NoicePopupmenu",
                FloatBorder = "NoicePopupmenuBorder",
              },
            },
          },
        },
      }
    end,
    keys = {
      { "<leader>sn", "", desc = "+noice" },
      {
        "<leader>snl",
        function()
          require("noice").cmd("last")
        end,
        desc = "Noice Last Message",
      },
      {
        "<leader>snh",
        function()
          require("noice").cmd("history")
        end,
        desc = "Noice History",
      },
      {
        "<leader>n",
        function()
          require("noice").cmd("telescope")
        end,
        desc = "Noice Picker (Telescope)",
      },
      {
        "<leader>sna",
        function()
          require("noice").cmd("all")
        end,
        desc = "Noice All",
      },
      {
        "<leader>snd",
        function()
          require("noice").cmd("dismiss")
        end,
        desc = "Dismiss All",
      },
    },
  },
  {
    "rcarriga/nvim-notify",
    enabled = false,
  },
}
