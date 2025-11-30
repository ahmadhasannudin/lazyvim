# Neovim Configuration

A modern Neovim configuration based on LazyVim with custom plugins and keymaps.

## Fresh Installation
```bash
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim && echo "Neovim directories removed" && brew reinstall neovim
```

## Features

- 🚀 **LazyVim** - Fast and modular Neovim configuration
- 📦 **Package Manager** - lazy.nvim for plugin management
- 🎨 **Multiple Themes** - Theme selector with preview
- 💻 **Floating Terminal** - nvzone/floaterm with workspace-based naming
- 🔍 **Search & Replace** - nvim-spectre for project-wide find/replace
- 📂 **Workspace Management** - Multiple project workspaces with sessions
- 🌳 **Git Integration** - Diffview, gitsigns, and git commands
- 📡 **SFTP Sync** - Automatic file upload to remote servers
- 🔥 **AI Assistance** - GitHub Copilot integration
- 📊 **Scrollbar** - satellite.nvim with diagnostics and git signs
- 📏 **Indent Guides** - hlchunk.nvim for visual indentation
- 🔍 **Code Folding** - nvim-ufo with treesitter support

---

## Keymaps Overview

### General
| Keymap | Mode | Description |
|--------|------|-------------|
| `jk` | Insert | Exit insert mode |
| `<leader><leader>` | Normal | Switch to last buffer |
| `<Cmd-a>` | Normal | Select all |
| `<Cmd-s>` | Normal/Insert/Visual | Save file (silent) |
| `<Cmd-c>` | Visual | Copy to system clipboard |
| `<Cmd-v>` | Normal/Visual/Insert | Paste from system clipboard |
| `<Cmd-x>` | Normal/Visual | Cut to system clipboard |

### File Operations
| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>fn` | Normal | Create new file |
| `<leader>fN` | Normal | Create new file here (current dir) |
| `<leader>yfp` | Normal | Copy full file path |
| `<leader>yrp` | Normal | Copy relative file path |

### Navigation
| Keymap | Mode | Description |
|--------|------|-------------|
| `<Cmd-Shift-o>` | Normal | Go to symbol (like VSCode) |
| `<C-q>` | Normal | Toggle hover documentation |
| `<C-h/j/k/l>` | Insert | Navigate in insert mode |

### Editing
| Keymap | Mode | Description |
|--------|------|-------------|
| `<Cmd-/>` | Normal/Visual | Toggle line comment |
| `J` | Normal | Move line down |
| `K` | Normal | Move line up |
| `J` | Visual | Move selection down |
| `K` | Visual | Move selection up |
| `<Tab>` | Visual | Indent and reselect |
| `<Shift-Tab>` | Visual | Unindent and reselect |
| `<M-BS>` / `<A-BS>` | Insert | Delete word backward |
| `<Cmd-BS>` | Insert | Delete to line start |
| `-` | Normal (PHP) | Add semicolon at end of line |

### Multiple Cursors
| Keymap | Mode | Description |
|--------|------|-------------|
| `<Cmd-d>` | Normal/Visual | Add cursor to next match |
| `<Cmd-Shift-l>` | Normal/Visual | Select all occurrences |
| `<leader>gC` | Visual | Add cursors at start of lines |

### Buffer Management
| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>bD` | Normal | Delete all buffers except current |
| `<leader>bX` | Normal | Delete all buffers (with confirm) |

### Terminal (Floaterm)
| Keymap | Mode | Description |
|--------|------|-------------|
| `<C-\>` / `<Cmd-t>` | Normal/Terminal | Toggle floating terminal |
| `<leader>tt` | Normal | Toggle terminal |
| `<C-n>` / `<C-p>` | Terminal | Cycle next/prev terminal |
| `<C-t>` | Terminal | Create new terminal |
| `jk` | Terminal | Exit terminal mode |
| `<Esc>` | Terminal | Minimize terminal |
| `q` | Terminal (Normal) | Minimize terminal |
| `ta` | Terminal | Add new terminal |
| `te` | Terminal | Edit terminal name |
| `td` | Terminal | Delete terminal (with confirm) |
| `tq` | Terminal | Quick delete terminal |
| `tQ` | Terminal | Delete all terminals |

### Search & Replace (Spectre)
| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>sr` | Normal | Replace in files (project-wide) |
| `<leader>sw` | Normal | Replace current word |
| `<leader>sw` | Visual | Replace selection |
| `<leader>sf` | Normal | Replace in current file |

### Git (Diffview)
| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>gv` | Normal | Open diffview (git changes) |
| `<leader>gV` | Normal | Close diffview |
| `<leader>gfh` | Normal | File history (current file) |
| `<leader>gbh` | Normal | Branch history (all files) |

### Workspace & Sessions
| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>pw` | Normal | Open workspace picker |
| `<leader>pa` | Normal | Add current dir as workspace |
| `<leader>qs` | Normal | Restore session |
| `<leader>qS` | Normal | Save session |
| `<leader>ql` | Normal | Restore last session |
| `<leader>qd` | Normal | Don't save current session |

### Code Folding (UFO)
| Keymap | Mode | Description |
|--------|------|-------------|
| `zR` | Normal | Open all folds |
| `zM` | Normal | Close all folds |
| `zr` | Normal | Open folds except kinds |
| `zm` | Normal | Close folds with |
| `zp` | Normal | Peek folded lines |
| `<leader>zF` | Normal | Fold all functions only (not classes) |
| `<leader>zU` | Normal | Unfold all |

### Theme
| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>th` | Normal | Theme selector |

### Misc
| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>n` | Normal | Noice message picker |
| `<leader>Q` | Normal | Clear word highlight |
| `<leader>ut` | Normal | Toggle treesitter context |
| `<leader>fp` | Normal | Find plugin file |

---

## SFTP Listener Configuration

### Overview
The SFTP listener automatically uploads files to remote SFTP servers when you save them in Neovim. Everything is now contained within your nvim config folder.

### SFTP Keymaps
| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>fU` | Normal | Upload folder (with prompt) |
| `<leader>fd` | Normal | Download current file |
| `<leader>fD` | Normal | Download folder (with prompt) |
| `<leader>fs` | Normal | Start SFTP listener |
| `<leader>fS` | Normal | Stop SFTP listener |
| `<leader>ft` | Normal | Toggle SFTP listener |

### File Locations
- **Binary**: `~/.config/nvim/sftp-listener/sftp-listener`
- **Source code**: `~/.config/nvim/sftp-listener/main.go`
- **Config file**: `~/.config/nvim/sftp-listener.json`
- **PID file**: `~/.config/nvim/.sftp-listener.pid`
- **Log file**: `~/.config/nvim/sftp-listener.log`

## Configuration

### Global Settings

Edit the `SETTINGS` table at the top of `init.lua` to customize behavior:

```lua
local SETTINGS = {
  auto_format_on_save = false, -- Set to true to enable auto-format on save
  follow_existing_indentation = true, -- Set to false to use smart indentation instead of copying line above when using 'o' or 'O'
}
```

#### Settings Explained

- **`auto_format_on_save`** (default: `false`)
  - When `true`: Automatically formats files on save using LSP/formatters
  - When `false`: Files are saved without automatic formatting

- **`follow_existing_indentation`** (default: `true`)
  - When `true`: Pressing `o` or `O` copies the exact indentation from the line above, even if incorrect
  - When `false`: Uses smart indentation based on treesitter/syntax rules
  - Useful when working with legacy code that has inconsistent indentation

### Auto-start Setting
Edit `lua/config/sftp.lua` and change the `auto_start` setting:

```lua
M.config = {
  auto_start = true,  -- Set to false to disable auto-start
  ...
}
```

- `true`: Listener starts automatically when you open Neovim
- `false`: You need to manually start the listener

### SFTP Keymaps
See the **SFTP Keymaps** section above for all available commands.

### Multiple Neovim Instances
The PID file (`~/.config/nvim/.sftp-listener.pid`) ensures only one listener runs at a time:
- First nvim instance starts the listener
- Additional nvim instances detect it's already running
- No conflicts occur

## Project Configuration

Edit `~/.config/nvim/sftp-listener.json` to add/modify projects:

```json
{
  "server_port": "8765",
  "registered_projects": {
    "project_name": {
      "local_base_path": "/path/to/local/project",
      "sftp_host": "example.com",
      "sftp_port": "22",
      "sftp_user": "username",
      "sftp_password": "password",
      "sftp_base_path": "/remote/path"
    }
  }
}
```

## Troubleshooting

### Rebuild the binary (if needed)
```bash
cd ~/.config/nvim/sftp-listener
go build -o sftp-listener main.go
```

### Check if listener is running
```bash
cat ~/.config/nvim/.sftp-listener.pid
ps -p <PID>
```

### View logs
```bash
tail -f ~/.config/nvim/sftp-listener.log
```

### Manually stop listener
```bash
kill $(cat ~/.config/nvim/.sftp-listener.pid)
rm ~/.config/nvim/.sftp-listener.pid
```

### Reset everything
```bash
pkill sftp-listener
rm ~/.config/nvim/.sftp-listener.pid
```

## How It Works

1. When you save a file in Neovim, the autocmd triggers
2. SFTP module sends HTTP request to listener (localhost:8765)
3. Listener validates project and uploads file to SFTP server
4. File maintains directory structure on remote server
