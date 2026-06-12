-- ============================================================
-- DEBUGGER (nvim-dap) — Go + JavaScript/TypeScript
-- ============================================================
-- Fully lazy: NOTHING loads at startup. The plugin (and its UI)
-- only load the first time you press a debug key or run :DapNew.
-- The debug adapters (delve / js-debug) are separate processes
-- that spawn when a session starts and exit when it ends —
-- zero CPU cost while you're just editing.
--
-- Full documentation: ~/.config/nvim/DEBUGGER.md
-- ============================================================

return {
  {
    "mfussenegger/nvim-dap",
    lazy = true, -- explicit: never load at startup (your lazy.nvim defaults.lazy = false)

    dependencies = {
      -- UI panels (scopes, breakpoints, stack, repl, console)
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
      },
      -- show variable values inline next to the code
      "theHamsta/nvim-dap-virtual-text",
      -- auto-install the adapters via mason
      "jay-babu/mason-nvim-dap.nvim",
      -- Go: delve config + debug-nearest-test helper
      "leoluz/nvim-dap-go",
    },

    -- ── Lazy triggers: the plugin loads ONLY on these ─────────
    cmd = { "DapNew", "DapContinue", "DapToggleBreakpoint" },
    keys = {
      -- Core stepping (replaces F5/F9/F10/F11/F12). <leader>db is reserved by sundb,
      -- so the toggle-breakpoint key is <leader>dp (breakPoint).
      { "<leader>dd", function() require("dap").continue() end, desc = "Start / Continue" },
      { "<leader>dp", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>dO", function() require("dap").step_out() end,  desc = "Step out" },
      { "<leader>dB", function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end, desc = "Conditional breakpoint" },
      { "<leader>dL", function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input("Log message: "))
        end, desc = "Logpoint" },
      { "<leader>dx", function() require("dap").clear_breakpoints() end, desc = "Clear all breakpoints" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle debug UI" },
      { "<leader>de", function() require("dapui").eval() end, mode = { "n", "v" }, desc = "Eval under cursor / selection" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate session" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>dj", function() require("dap").down() end, desc = "Down one stack frame" },
      { "<leader>dk", function() require("dap").up() end, desc = "Up one stack frame" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Re-run last session" },
      -- Go-specific: debug the test under the cursor
      { "<leader>dg", function() require("dap-go").debug_test() end, desc = "Debug nearest Go test", ft = "go" },
    },

    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- ── Install adapters automatically (one-time, via mason) ──
      require("mason-nvim-dap").setup({
        ensure_installed = { "delve", "js" }, -- js => js-debug-adapter
        automatic_installation = false,
        handlers = nil, -- we configure adapters manually below
      })

      -- ── UI ────────────────────────────────────────────────────
      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes",      size = 0.45 }, -- variables
              { id = "watches",     size = 0.20 },
              { id = "breakpoints", size = 0.15 },
              { id = "stacks",      size = 0.20 }, -- call stack
            },
            size = 42,
            position = "left",
          },
          {
            elements = {
              { id = "repl",    size = 0.55 },
              { id = "console", size = 0.45 }, -- program stdout
            },
            size = 12,
            position = "bottom",
          },
        },
        floating = { border = "rounded" },
      })

      -- inline variable values next to your code
      require("nvim-dap-virtual-text").setup({
        commented = true, -- prefix with comment chars so it reads as annotation
        virt_text_pos = "eol",
      })

      -- open/close the UI with the session automatically
      dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui"]     = function() dapui.close() end

      -- ── Signs (gutter icons) ─────────────────────────────────
      vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapLogPoint",            { text = "◉", texthl = "DiagnosticInfo" })
      vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DiagnosticHint" })
      vim.fn.sign_define("DapStopped", {
        text = "▶",
        texthl = "DiagnosticOk",
        linehl = "Visual",
        numhl = "DiagnosticOk",
      })

      -- ════════════════════════════════════════════════════════
      -- GO (delve) — via nvim-dap-go
      -- ════════════════════════════════════════════════════════
      require("dap-go").setup({
        delve = {
          -- build flags etc. can go here if a project needs them
          detached = vim.fn.has("win32") == 0,
        },
      })
      -- dap-go registers these configurations for ft=go:
      --   • Debug                 (current file/package)
      --   • Debug (Arguments)     (prompts for CLI args)
      --   • Debug Package         (whole package)
      --   • Debug test            (current _test.go file)
      --   • Attach                (pick a running process)
      -- plus <leader>dg = debug the test function under the cursor.

      -- ════════════════════════════════════════════════════════
      -- JAVASCRIPT / TYPESCRIPT (vscode-js-debug via mason)
      -- ════════════════════════════════════════════════════════
      for _, adapter in ipairs({ "pwa-node", "pwa-chrome" }) do
        dap.adapters[adapter] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "js-debug-adapter", -- installed by mason ("js")
            args = { "${port}" },
          },
        }
      end

      local js_filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact", "svelte" }

      for _, ft in ipairs(js_filetypes) do
        dap.configurations[ft] = {
          -- 1. run the current file with node
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch current file (node)",
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            skipFiles = { "<node_internals>/**", "**/node_modules/**" },
            console = "integratedTerminal",
          },
          -- 2. run the current file with tsx (TypeScript without compiling)
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch current file (tsx)",
            runtimeExecutable = "npx",
            runtimeArgs = { "tsx" },
            program = "${file}",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            skipFiles = { "<node_internals>/**", "**/node_modules/**" },
            console = "integratedTerminal",
          },
          -- 3. attach to an already-running node process (started with --inspect)
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process (pick)",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          },
          -- 4. attach to the default inspector port (node --inspect = :9229)
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to :9229 (node --inspect)",
            address = "localhost",
            port = 9229,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            restart = true,
            skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          },
          -- 5. debug client-side JS in Chrome (Astro/Vite dev server)
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Chrome against dev server",
            url = function()
              return vim.fn.input("Dev server URL: ", "http://localhost:4321")
            end,
            webRoot = "${workspaceFolder}",
            sourceMaps = true,
            userDataDir = false,
          },
        }
      end
    end,
  },
}
