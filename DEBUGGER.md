# Debugging in Neovim — Go & JavaScript/TypeScript

> Config lives in `lua/plugins/dap.lua`. This document explains how the whole
> thing works, every keymap, and the exact workflows for Go and JS — including
> debugging the apps from your Go/Astro tutorials.

---

## Table of Contents

1. [How it works (the architecture)](#1-how-it-works)
2. [Why it costs zero CPU until you use it](#2-performance--lazy-loading)
3. [First-time setup](#3-first-time-setup)
4. [Keymaps reference](#4-keymaps)
5. [The UI tour](#5-the-ui-tour)
6. [Debugging Go](#6-debugging-go)
7. [Debugging JavaScript / TypeScript](#7-debugging-javascript--typescript)
8. [Breakpoint superpowers (conditional, logpoints, watch)](#8-breakpoint-superpowers)
9. [The senior-dev workflows](#9-the-senior-dev-workflows)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. How It Works

Debugging in Neovim uses **DAP — the Debug Adapter Protocol**, the same
protocol VS Code uses. Three pieces talk to each other:

```
┌─────────────┐   DAP (JSON-RPC)   ┌──────────────────┐   native protocol   ┌──────────────┐
│   nvim-dap   │ ◄───────────────► │  debug adapter    │ ◄────────────────► │ your program │
│  (the client │                   │  delve (Go)       │                    │  paused at a │
│   inside     │                   │  js-debug (JS/TS) │                    │  breakpoint  │
│   neovim)    │                   │  (separate proc)  │                    │              │
└─────────────┘                   └──────────────────┘                    └──────────────┘
```

- **nvim-dap** is the client: it draws breakpoints, sends "step over",
  receives variable values. It knows nothing about Go or JS specifically.
- **The adapter** is a separate process that speaks DAP on one side and the
  language's real debugging machinery on the other:
  - **delve (`dlv`)** for Go — compiles your program with optimizations off
    and controls it natively.
  - **js-debug-adapter** (Microsoft's `vscode-js-debug`, the exact engine VS
    Code uses) for Node and Chrome.
- **Your program** runs as its own process, started (or attached to) by the
  adapter.

Because the adapter is the same one VS Code uses, capabilities are identical —
conditional breakpoints, logpoints, hot-eval, source maps, remote attach.
The editor is just the front end.

### The pieces installed

| Plugin | Job |
|---|---|
| `mfussenegger/nvim-dap` | The DAP client |
| `rcarriga/nvim-dap-ui` | Variables / watches / stack / breakpoints / console panels |
| `theHamsta/nvim-dap-virtual-text` | Shows `x = 42` inline next to your code while paused |
| `leoluz/nvim-dap-go` | Delve wiring + "debug the test under my cursor" |
| `jay-babu/mason-nvim-dap.nvim` | Auto-installs `delve` and `js-debug-adapter` via Mason |

---

## 2. Performance — Lazy Loading

You asked for the debugger to cost nothing until you want it. Three layers
guarantee that:

1. **Plugin load** — the spec uses `keys` + `cmd` triggers only. At nvim
   startup, lazy.nvim registers the keymaps and *nothing else*. The ~5 plugins
   are not read from disk until the first time you press a `<leader>d…` key.
   Check it yourself: `:Lazy` → `nvim-dap` shows as **not loaded** after startup.

2. **Adapter processes** — `dlv` and `js-debug-adapter` are external binaries
   that **spawn when a session starts and exit when it ends**. No daemon, no
   background watcher. While you edit, they don't exist as processes.

3. **UI** — dap-ui windows open automatically when a session initializes and
   close when it terminates. No hidden buffers idling around between sessions.

So the steady-state cost of this entire setup while coding is: a few keymap
registrations. That's it.

---

## 3. First-Time Setup

```vim
:Lazy sync          " install the 5 plugins (one time)
```

Then trigger the debugger once (e.g. press `<leader>dp` on any line) — this loads the
plugin, and mason-nvim-dap will install the two adapters. Or install them
explicitly:

```vim
:MasonInstall delve js-debug-adapter
```

Requirements on your system:

| Tool | Needed for | Check |
|---|---|---|
| `go` | building what delve debugs | `go version` |
| `dlv` | Go debugging (mason installs it) | `:Mason` → delve ✓ |
| `node` | running JS, and the js adapter itself | `node --version` |
| `js-debug-adapter` | JS/TS debugging (mason installs it) | `:Mason` → js-debug-adapter ✓ |
| `tsx` (optional) | "Launch current file (tsx)" config | `npx tsx --version` |

> Mason puts binaries in `~/.local/share/nvim/mason/bin`, which nvim adds to
> `PATH` for its child processes — no shell config needed.

---

## 4. Keymaps

### Core stepping

| Key | Action |
|---|---|
| `<leader>dd` | Start debugging / Continue to next breakpoint |
| `<leader>dp` | Toggle breakpoint on current line (`p` = breakPoint; `db` is reserved by sundb) |
| `<leader>do` | Step **over** (run this line, don't enter functions) |
| `<leader>di` | Step **into** (descend into the function call) |
| `<leader>dO` | Step **out** (finish this function, pause in caller) |

### `<leader>d` group (extras)

| Key | Action |
|---|---|
| `<leader>dB` | **Conditional** breakpoint (prompts for an expression) |
| `<leader>dL` | **Logpoint** (prints a message instead of pausing) |
| `<leader>dx` | Clear all breakpoints |
| `<leader>du` | Toggle the debug UI panels manually |
| `<leader>de` | Evaluate expression under cursor / visual selection |
| `<leader>dr` | Toggle the REPL |
| `<leader>dC` | Run to cursor (temporary breakpoint here) |
| `<leader>dk` / `<leader>dj` | Up / down the call stack |
| `<leader>dl` | Re-run the last session (same config, no menu) |
| `<leader>dt` | Terminate the session |
| `<leader>dg` | **Go only:** debug the test function under the cursor |

> `<leader>db` is deliberately **not** used — it belongs to your sundb plugin.

### Gutter signs

| Sign | Meaning |
|---|---|
| `●` red | Breakpoint |
| `◆` yellow | Conditional breakpoint |
| `◉` blue | Logpoint |
| `○` dim | Rejected breakpoint (adapter couldn't bind it — see Troubleshooting) |
| `▶` + highlighted line | Execution is paused here |

---

## 5. The UI Tour

When a session starts, the UI opens automatically:

```
┌──────────────┬────────────────────────────────────────┐
│ SCOPES       │                                        │
│  locals,     │         your code                      │
│  args —      │         ▶ paused line highlighted      │
│  expandable  │         x = 42  ← virtual text         │
│  tree        │                                        │
├──────────────┤                                        │
│ WATCHES      │                                        │
│  expressions │                                        │
│  you pinned  │                                        │
├──────────────┼────────────────────────────────────────┤
│ BREAKPOINTS  │  REPL              │  CONSOLE          │
├──────────────┤  eval expressions  │  program stdout/  │
│ STACKS       │  in the paused     │  stderr lives     │
│  call stack, │  context           │  here             │
│  click=jump  │                    │                   │
└──────────────┴────────────────────┴───────────────────┘
```

- **Scopes**: every local/argument at the paused position. `<CR>` on a struct/
  object expands it. Values that changed since the last pause are highlighted.
- **Watches**: press `a` inside the watches panel to add an expression — it
  re-evaluates at every pause (`len(items)`, `user.ID`, `req.headers`…).
- **Stacks**: the call chain. `<CR>` on any frame jumps your editor there and
  switches Scopes to *that frame's* variables. This is how you answer "who
  called this with bad data?"
- **REPL** (`<leader>dr`): type any expression in the language being debugged,
  evaluated in the paused context. In Go: `len(tasks)`, `task.Done`. In JS:
  `JSON.stringify(req.body)`, `user?.email`.
- **Console**: your program's output (because configs use
  `console = "integratedTerminal"` for launches).

---

## 6. Debugging Go

`nvim-dap-go` registers these configurations — `<leader>dd` in any `.go` file shows
the menu:

| Config | What it does |
|---|---|
| **Debug** | Build & debug the current file's package (`dlv debug`) |
| **Debug (Arguments)** | Same, but prompts for CLI args first |
| **Debug Package** | Debug the whole package of the current dir |
| **Debug test** | Debug all tests in the current `_test.go` file |
| **Attach** | Pick an already-running process to attach to |

### Workflow 1 — debug your API server (e.g. the tutorial's `taskapi`)

1. Open `cmd/api/main.go` (or any file in the package).
2. `<leader>dp` on a line inside a handler — say inside `CreateTask`.
3. `<leader>dd` → choose **Debug**. Delve builds (optimizations off) and starts the
   server; the Console panel shows the "listening" log line.
4. Trigger the code path: `curl -X POST localhost:8080/api/v1/tasks -d '{…}'`.
5. nvim pauses at your breakpoint:
   - Scopes shows `in` (your decoded input struct), `w`, `r`, …
   - hover any variable with `<leader>de`
   - `<leader>do` through the validation, `<leader>di` into the service call.
6. `<leader>dd` to let the request complete. `curl` receives the response.
7. `<leader>dt` to stop the server when done.

### Workflow 2 — debug a single test (the one you'll use most)

Cursor anywhere inside `func TestCreateTask(t *testing.T)`:

```
<leader>dg        → runs ONLY this test under delve
```

Breakpoints work in the test *and* in all the code it calls. This is the
fastest way to understand why an assertion fails: break on the assert line,
inspect the actual value, walk up the stack to see where it went wrong.

For table-driven tests, set a **conditional breakpoint** inside the loop:

```
<leader>dB   condition:  tt.name == "unicode"
```

…and the debugger skips every case except the one that fails.

### Workflow 3 — attach to a running process

When something is misbehaving *right now* and you don't want to restart:

1. `<leader>dd` → **Attach** → pick the process from the list.
2. Set breakpoints, inspect, then `<leader>dt` — delve detaches and the
   process keeps running.

> Note: attaching needs the binary to have debug info. Your `air` dev builds
> do (default `go build`). Production builds with `-ldflags="-s -w"` don't.

### Go-specific inspection tips

- Goroutines: in the REPL, delve commands work via `dap> goroutines` style
  evaluation isn't exposed — instead use the **Stacks** panel's thread
  dropdown; every goroutine appears as a thread.
- `ctx context.Context` contents are opaque by design; put values you need to
  see into locals before debugging, or watch the typed getter call.
- Slices/maps expand natively in Scopes, including nested structs.

---

## 7. Debugging JavaScript / TypeScript

`<leader>dd` in any js/ts/jsx/tsx/svelte file offers:

| Config | What it does |
|---|---|
| **Launch current file (node)** | Runs the open file under node with the debugger |
| **Launch current file (tsx)** | Same but through `npx tsx` — debug TS directly, no build |
| **Attach to process (pick)** | Lists node processes started with `--inspect`, attach to one |
| **Attach to :9229** | Attach to the default inspector port |
| **Chrome against dev server** | Launches Chrome, debugs client-side code (default URL `:4321`) |

### Workflow 1 — debug a script

Open `scripts/migrate-data.ts`, `<leader>dp` somewhere, `<leader>dd` → **Launch current file
(tsx)**. Source maps mean breakpoints land in your `.ts` lines, not compiled
output.

### Workflow 2 — debug a Node server (Astro SSR, Express, anything)

Servers should run normally and be **attached to** — that way nvim isn't in
the restart loop:

```bash
# start your dev server with the inspector enabled:
NODE_OPTIONS="--inspect" npm run dev        # Astro/Vite
# or: node --inspect dist/server/entry.mjs  # built Astro SSR
```

Then in nvim: `<leader>dd` → **Attach to :9229**.

- Breakpoints in your Astro frontmatter, Actions, middleware, endpoints —
  all work (Vite serves source maps in dev).
- `restart = true` in the config means if the dev server restarts, the
  debugger re-attaches by itself.
- Trigger the route in the browser; nvim pauses mid-request, exactly like the
  Go flow.

### Workflow 3 — debug client-side code (islands)

`<leader>dd` → **Chrome against dev server** → accept `http://localhost:4321`.

A Chrome instance launches wired to the adapter. Breakpoints in your island
components (`SearchBox.tsx`, cart islands, …) hit when you interact with the
page. You get the browser's debugging power with nvim as the UI.

> Tip: for full-stack debugging of an Astro+Go app, run **two sessions**:
> attach to node (:9229) for SSR code, and keep Go running under delve in
> another nvim tab. Each session gets its own UI; `:DapNew` starts a second
> session without killing the first.

### Source maps — the thing that makes TS debugging work

`sourceMaps = true` is set in every config. The adapter reads `.map` files (or
inline maps from Vite/tsx) and translates between the JS that runs and the TS
you wrote. If breakpoints turn hollow (`○`), the map chain is broken — see
Troubleshooting.

---

## 8. Breakpoint Superpowers

These are the features that separate "I use a debugger" from "the debugger is
my microscope":

### Conditional breakpoints — `<leader>dB`

Pause only when an expression is true:

```
Go:  task.UserID != currentUser        JS:  res.status >= 500
Go:  len(items) == 0                   JS:  user?.email == null
```

The 500th iteration of a loop with bad data? Condition on the bad data, not
on your patience.

### Logpoints — `<leader>dL`

Print without pausing — `console.log`/`fmt.Println` you can add **without
editing the file or restarting**:

```
Log message:  order {order.ID} total={order.Total}
```

Output appears in the REPL. Interpolate with `{expr}`. This is the cure for
"add print, rebuild, reproduce, remove print" loops.

### Run to cursor — `<leader>dC`

Don't litter breakpoints: pause once, then "just get me to this line".

### Watch expressions

In the Watches panel press `a`:
`len(h.rooms)`, `cart.items.length`, `string(body)` — re-evaluated at every
pause, your live dashboard of the values you care about.

### Hot eval — `<leader>de`

Cursor on any variable (or visual-select an expression) → evaluates in the
current frame, shows in a float. Fastest inspection there is.

---

## 9. The Senior-Dev Workflows

The debugger habits worth building deliberately:

1. **Reproduce → break → walk up.** Don't read code guessing where it breaks.
   Break where the *symptom* is (the error return, the wrong response), then
   walk **up the stack** (`<leader>dk`) asking "which caller handed me this?"

2. **Debug the test, not the app.** Failing test? `<leader>dg` (Go) or launch
   the test file (JS) takes you straight into the failing context in seconds —
   no clicking through the UI to reach the state.

3. **Condition on the anomaly.** A bug in 1-of-N items means a conditional
   breakpoint on the anomaly's signature (`item.ID == 4521`), not stepping N
   times.

4. **Logpoints in running services.** Attached to a live dev server, sprinkle
   logpoints to trace flow *without restarting* — then remove them all with
   `<leader>dx`.

5. **Watch the invariant.** Debugging state corruption? Watch the invariant
   (`len(queue)`, `balance >= 0`) and step until it lies.

6. **Read the paused state before stepping.** Each pause shows the complete
   truth of the moment. Most "step step step where did it go" sessions are
   answered by actually reading Scopes at the first pause.

---

## 10. Troubleshooting

| Symptom | Cause → Fix |
|---|---|
| `<leader>dd` says "no configuration" | Filetype not go/js/ts/jsx/tsx/svelte. Check `:set ft?` |
| "Couldn't find executable js-debug-adapter / dlv" | Mason didn't install yet → `:MasonInstall delve js-debug-adapter`, restart |
| Breakpoints show `○` (hollow) in Go | Binary built without debug info — don't debug `-s -w` builds; let delve do the build (`Debug` config) |
| Breakpoints `○` in TS | Broken source maps → for files run with plain `node`, ensure `"sourceMap": true` in tsconfig; or use the tsx config |
| Attach to :9229 fails | Server not started with `--inspect`, or another debugger (Chrome DevTools) already attached — only one client per inspector |
| Go: "could not launch process: fork/exec" on mac | macOS dev tools permission → run `dlv` once in a terminal and accept, or `xcode-select --install` |
| UI opens but variables empty | You're paused in a frame with no source (e.g. runtime internals) — pick *your* frame in Stacks |
| Session ends instantly, console shows exit 0 | No breakpoint hit — the code path never executed. Breakpoint the entry point first to confirm |
| Port 9229 already in use | Old node process holding it: `lsof -i :9229` → kill it |
| Everything is slow while debugging Go | Normal: delve disables optimizations. Only the *debug* build is slower; your normal `air` builds are untouched |

### Sanity check, end to end (2 minutes)

```bash
# Go
mkdir /tmp/dbg && cd /tmp/dbg && go mod init dbg
cat > main.go <<'EOF'
package main
import "fmt"
func main() {
    sum := 0
    for i := 1; i <= 5; i++ {
        sum += i
    }
    fmt.Println(sum)
}
EOF
nvim main.go    # <leader>dp on "sum += i", <leader>dd → Debug, watch sum grow with <leader>dd <leader>dd <leader>dd
```

```bash
# JS
echo 'let s=0; for (let i=1;i<=5;i++){ s+=i }; console.log(s)' > /tmp/t.js
nvim /tmp/t.js  # <leader>dp on the loop body, <leader>dd → Launch current file (node)
```

If both pause and show variables: you're armed. Go break things on purpose.
