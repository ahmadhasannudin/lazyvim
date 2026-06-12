return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- TypeScript/JavaScript
        ts_ls = {},
        -- Svelte
        svelte = {},
        -- ESLint
        eslint = {},
        -- Tailwind CSS
        tailwindcss = {},
        -- PHP
        intelephense = {
          -- Per-project exclude: when editing pintro_ng, skip these portal subprojects
          -- so intelephense doesn't index them (saves a lot of RAM/CPU).
          on_new_config = function(new_config, new_root_dir)
            if new_root_dir and new_root_dir:match("pintro_ng$") then
              new_config.settings = vim.tbl_deep_extend("force", new_config.settings or {}, {
                intelephense = {
                  files = {
                    exclude = {
                      "**/pmb-all/**",
                      "**/portal-absence/**",
                      "**/portal-aquatic/**",
                      "**/portal-lms/**",
                      "**/portal-opac/**",
                      "**/portal-payment/**",
                      "**/portal-school/**",
                      "**/portal-sosial/**",
                      "**/portal-visitor/**",
                      "**/vendor/**",
                      "**/public/**",
                      "**/resources/**",
                      "**/storage/**",
                    },
                  },
                },
              })
            end
          end,
          on_attach = function(client, bufnr)
            local settings = vim.g.SETTINGS or { auto_format_on_save = false }
            -- Control formatting based on settings
            if settings.auto_format_on_save then
              -- Ensure formatting is enabled
              client.server_capabilities.documentFormattingProvider = true
              client.server_capabilities.documentRangeFormattingProvider = true
            else
              -- Disable formatting on save only
              client.server_capabilities.documentFormattingProvider = false
              client.server_capabilities.documentRangeFormattingProvider = false
            end
          end,
          settings = {
            intelephense = {
              format = {
                enable = true,
              },
              stubs = {
                "bcmath",
                "bz2",
                "calendar",
                "Core",
                "curl",
                "date",
                "dba",
                "dom",
                "enchant",
                "fileinfo",
                "filter",
                "ftp",
                "gd",
                "gettext",
                "hash",
                "iconv",
                "imap",
                "intl",
                "json",
                "ldap",
                "libxml",
                "mbstring",
                "mcrypt",
                "mysql",
                "mysqli",
                "password",
                "pcntl",
                "pcre",
                "PDO",
                "pdo_mysql",
                "Phar",
                "readline",
                "recode",
                "Reflection",
                "regex",
                "session",
                "SimpleXML",
                "soap",
                "sockets",
                "sodium",
                "SPL",
                "standard",
                "superglobals",
                "sysvsem",
                "sysvshm",
                "tokenizer",
                "xml",
                "xdebug",
                "xmlreader",
                "xmlwriter",
                "yaml",
                "zip",
                "zlib",
                "wordpress",
                "woocommerce",
                "acf-pro",
                "wordpress-globals",
                "wp-cli",
                "genesis",
                "polylang",
              },
              diagnostics = {
                enable = true,
              },
              telemetry = {
                enabled = false,
              },
              files = {
                maxSize = 5000000,
              },
            },
          },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "intelephense",
        "typescript-language-server",
        "svelte-language-server",
        "eslint-lsp",
        "tailwindcss-language-server",
        "prettier",
        "sqls",
      },
    },
  },
}
