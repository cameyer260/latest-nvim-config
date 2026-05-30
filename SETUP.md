# My Neovim setup

A lean, self-owned config built on **kickstart.nvim**. The goal: a real IDE in the
terminal (Ghostty), staying on the keyboard, with only the plugins I actually use —
and every line readable/editable by me.

- **Base:** kickstart.nvim (the heavily-commented `init.lua`)
- **Plugin manager:** `vim.pack` — Neovim's *built-in* manager. No lazy.nvim. Plugins
  are declared with `vim.pack.add { 'https://github.com/owner/repo' }` and bootstrap on
  first launch.
- **Theme:** Kanagawa (hardcoded, `kanagawa-wave`)
- **Runs:** natively on macOS inside Ghostty.

---

## 1. Prerequisites (one-time, on the Mac)

Neovim **0.12+** is required (that's where `vim.pack` lives — current `stable` is fine).

```bash
# Core
brew install neovim ripgrep fd fzf git
brew install tree-sitter-cli # CLI used to compile treesitter parsers (REQUIRED by the main branch).
                             # NOTE: the `tree-sitter` formula is only the library now — you need `tree-sitter-cli`.
brew install node            # runtime for the web / JSON / YAML language servers
brew install --cask font-jetbrains-mono-nerd-font   # icons for the tree + tabs

# For the compiled-language servers (C/C++/Rust):
xcode-select --install                       # clang/clangd toolchain (skip if already installed)
brew install rustup-init && rustup-init -y   # gives rust_analyzer a real toolchain
```

Then point Ghostty at the Nerd Font — add to `~/.config/ghostty/config`:

```
font-family = JetBrainsMono Nerd Font
```

Check the version: `nvim --version` → should report **v0.12** or newer.

## 2. First launch

Run `nvim`. On the first start:

1. `vim.pack` downloads every plugin (you'll see it fetch repos — wait for it).
2. **Mason** auto-installs all the language servers + `prettierd` (watch the bottom of the
   screen; or open `:Mason` to see progress).
3. **Treesitter** installs the parsers for our languages.

Restart `nvim` once it's done. Useful health/status commands:

- `:checkhealth` — diagnose anything missing
- `:Mason` — view/manage installed LSP servers & tools (`g?` for help)
- `:lua vim.pack.update(nil, { offline = true })` — inspect plugin state
- `:lua vim.pack.update()` — update plugins

## 3. Layout

```
~/.config/nvim/
├── init.lua                      # kickstart core, lightly edited (see "What I changed")
├── SETUP.md                      # this file
└── lua/
    ├── kickstart/                # kickstart's own modules (mostly untouched)
    └── custom/plugins/           # my additions — each file auto-loaded by init.lua
        ├── init.lua              # loader: requires every other file in this dir
        ├── colorscheme.lua       # Kanagawa
        ├── tree.lua              # neo-tree file explorer (shows hidden files)
        ├── tabs.lua              # bufferline (Chrome-style tabs)
        ├── terminal.lua          # toggleterm (floating terminal)
        └── findreplace.lua       # grug-far (project-wide find & replace)
```

**To add a plugin:** drop a new `lua/custom/plugins/whatever.lua` that calls
`vim.pack.add { 'https://github.com/owner/repo' }` and then `require('repo').setup{}`.
It's picked up automatically on next launch.

## 4. What I changed vs. stock kickstart

- `vim.g.have_nerd_font = true`
- Replaced tokyonight with **Kanagawa** (`custom/plugins/colorscheme.lua`)
- Filled in the **LSP `servers`** table with my languages (see below)
- Added **prettierd** to Mason + wired up `conform` formatters per filetype
- Expanded the **treesitter** parser list
- Telescope `find_files`/`live_grep` now include **hidden files** (skip `.git`)
- Enabled `require 'custom.plugins'` to load my extra files

## 5. Language servers (auto-installed by Mason)

| Language(s)            | Server(s)                          |
|------------------------|------------------------------------|
| JS / TS / JSX / TSX    | `ts_ls`, `eslint`                  |
| HTML + Emmet           | `html`, `emmet_language_server`    |
| CSS / SCSS             | `cssls`                            |
| Tailwind               | `tailwindcss`                      |
| Astro                  | `astro`                            |
| JSON                   | `jsonls`                           |
| YAML                   | `yamlls`                           |
| Python                 | `pyright`, `ruff`                  |
| Rust                   | `rust_analyzer`                    |
| C / C++                | `clangd`                           |
| Bash                   | `bashls`                           |
| Markdown               | `marksman`                         |
| Lua (this config)      | `lua_ls`                           |

Formatting via `conform` (`<leader>f`): `prettierd` for the web stack, `ruff` for Python,
`rustfmt` for Rust, `stylua` for Lua. LSP formatting is the fallback.

---

# 6. Keybinding quick reference

> Leader = **Space**. Press `<Space>` and wait — **which-key** pops up showing what's
> available, so you don't have to memorize. In any Telescope window press `?` (normal) or
> `<C-/>` (insert) to see its keys.

### Files & explorer
| Key | Action |
|-----|--------|
| `<leader>e` | Toggle file explorer (reveals current file) |
| `<leader>o` | Jump focus into the explorer |
| `<leader>sf` | **Find files** (fuzzy; includes hidden like `.env`) |
| `<leader>sn` | Find files in the Neovim config |
| `<leader>s.` | Recent files |

**Inside the tree** (neo-tree): `a` add file (`name/` = folder) · `A` add dir · `d` delete ·
`r` rename · `m` move · `c` copy · `x` cut · `p` paste · `H` toggle hidden filter · `R` refresh · `?` all keys

### Tabs (open files)
| Key | Action |
|-----|--------|
| `Shift+L` | Next tab (move right) |
| `Shift+H` | Previous tab (move left) |
| `<leader>1`…`<leader>9` | Jump to tab N |
| `<leader>bp` | Pick a tab by letter |
| `<leader>bd` | Close current tab |
| `<leader>bo` | Close all other tabs |
| `<leader>bn` | New untitled tab (then `:w name.ext` to create the file) |
| `<leader>b<` / `<leader>b>` | Move current tab left / right |

> `Shift+H`/`Shift+L` replace Vim's default H/L (screen top/bottom). If you miss those, use
> `gg`/`G`, `Ctrl+u`/`Ctrl+d`, or `zt`/`zz`/`zb`.

### Open a specific file
- `<leader>sf` then type the name, **or** `:e path/to/file` (Tab-completes) — opens into a new tab.

### Search & grep
| Key | Action |
|-----|--------|
| `<leader>sg` | **Live grep** across the project (includes hidden) |
| `<leader>sw` | Grep the word under cursor (also works on a visual selection) |
| `<leader>s/` | Live grep only within open files |
| `<leader>/` | Fuzzy-find within the current file |
| `<leader><leader>` | Switch between open buffers |
| `<leader>sh` | Search help docs |
| `<leader>sk` | Search keymaps |
| `<leader>sd` | Search diagnostics |
| `<leader>sr` | Resume last search |

### Find & replace
| Key | Action |
|-----|--------|
| `:%s/old/new/g` | Replace in current file (live-previewed; add `c` flag to confirm each) |
| `<leader>R` | **Project-wide** find & replace panel (grug-far) |

### LSP (active when a language server attaches)
| Key | Action |
|-----|--------|
| `K` | Hover docs |
| `grd` | Go to definition (`Ctrl+t` / `Ctrl+o` to jump back) |
| `grr` | References |
| `gri` | Implementation |
| `grt` | Type definition |
| `grD` | Declaration |
| `grn` | Rename symbol (across files) |
| `gra` | Code action |
| `gO` | Document symbols |
| `gW` | Workspace symbols |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>q` | Diagnostics → location list |
| `<leader>th` | Toggle inlay hints |
| `<leader>f` | Format buffer |

### Terminal
| Key | Action |
|-----|--------|
| `Ctrl+\` | Toggle floating terminal (works from anywhere) |
| `<leader>tt` | Same toggle (leader alias) |
| `<Esc><Esc>` | Leave terminal-insert mode (back to normal) |

### Completion (insert mode — blink.cmp)
| Key | Action |
|-----|--------|
| `Ctrl+y` | Accept completion (auto-imports if supported) |
| `Ctrl+Space` | Open menu / toggle docs |
| `Ctrl+n` / `Ctrl+p` | Next / previous item |
| `Ctrl+e` | Dismiss menu |
| `Ctrl+k` | Toggle signature help |
| `Tab` / `Shift+Tab` | Jump forward/back through snippet placeholders |

### Windows / splits
| Key | Action |
|-----|--------|
| `Ctrl+h/j/k/l` | Move focus between splits |
| `:split` / `:vsplit` | Horizontal / vertical split |

### Editing niceties
- `gc` (visual) / `gcc` (line) — toggle comment
- `saiw)` add surround · `sd'` delete surround · `sr)'` replace surround (mini.surround)
- `<Esc>` — clear search highlight
- System clipboard is synced (`clipboard=unnamedplus`), so `y`/`p` share the macOS clipboard.

---

## 7. Notes & gotchas

- **Cmd keys don't reach Neovim** in a terminal (Ghostty owns `Cmd`), which is why tab
  navigation uses `Shift+H/L` and leader chords instead of `Cmd+T`/`Cmd+W`. To revisit this
  later you'd configure Ghostty `keybind` entries to forward escape sequences — not done here.
- `rust_analyzer` and `clangd` need their toolchains (step 1) to be fully useful. The
  web/JSON/YAML servers just need `node`.
- If icons look like boxes, the Nerd Font isn't active in Ghostty — recheck step 1.
- This is a git repo (`git init` was run, kickstart's history removed). Commit it so it's
  yours: `cd ~/.config/nvim && git add -A && git commit -m "initial setup"`.
- Run `:Tutor` once if you want a Neovim motions refresher.
