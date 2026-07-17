# Neovim quick reference

Your leader key is **Space**. In Normal mode, press `Space` and pause to open the
which-key menu. This reference covers the custom and configured shortcuts in this
Neovim setup; use `<leader>sk` to search every currently active mapping.

Notation: `<leader>` = `Space`; `Ctrl` means hold Control; `Shift+K` means uppercase `K`.

## Documentation and help

| Key / command | Action |
|---|---|
| `K` | Show documentation for the symbol under the cursor (when an LSP is attached). |
| `<leader>sh` | Search Neovim help. |
| `<leader>sk` | Search active keymaps. |
| `<leader>sc` | Search Ex commands. |
| `:help {topic}` | Open built-in help, e.g. `:help :w` or `:help lsp`. |
| `:Tutor` | Open Neovim’s interactive tutorial. |

## Files, buffers, and explorer

| Key / command | Action |
|---|---|
| `<leader>e` | Toggle the file explorer; reveal the current file. |
| `<leader>o` | Focus the file explorer. |
| `<leader>sf` | Find files, including hidden files. |
| `<leader>sn` | Find files in this Neovim configuration. |
| `<leader>s.` | Search recently opened files. |
| `:e path/to/file` | Open a file (Tab completes paths). |
| `Shift+L` / `Shift+H` | Next / previous buffer tab. |
| `<leader>1`–`<leader>9` | Jump to buffer tab 1–9. |
| `<leader>bp` | Pick a buffer tab by letter. |
| `<leader>bd` | Close the current buffer tab. |
| `<leader>bo` | Close all other buffer tabs. |
| `<leader>bn` | New unnamed buffer; use `:w name.ext` to save it. |
| `<leader>b<` / `<leader>b>` | Move current buffer tab left / right. |
| `<leader><leader>` | Switch between open buffers. |

Inside the file explorer: `a` add file (end the name with `/` for a folder), `A` add
folder, `d` delete, `r` rename, `m` move, `c` copy, `x` cut, `p` paste, `H` toggle
hidden-file filtering, `R` refresh, and `?` shows all explorer mappings.

## CSV and TSV tables

CSV and TSV files automatically open in a bordered, spreadsheet-style table view with
a sticky header. The original file contents remain unchanged.

| Key / command | Action |
|---|---|
| `Tab` / `Shift+Tab` | Move to the next / previous field. |
| `Enter` / `Shift+Enter` | Move to the next / previous row. |
| `:CsvViewToggle` | Toggle the table display for the current buffer. |
| `:CsvViewEnable` / `:CsvViewDisable` | Explicitly show / hide the table display. |

## Search and replace

| Key / command | Action |
|---|---|
| `<leader>sg` | Live grep in the project, including hidden files. |
| `<leader>sw` | Search the word under the cursor or the visual selection. |
| `<leader>s/` | Live grep only in open files. |
| `<leader>/` | Fuzzy-search the current file. |
| `<leader>ss` | Choose a Telescope search picker. |
| `<leader>sd` | Search diagnostics. |
| `<leader>sr` | Resume the last Telescope search. |
| `:%s/old/new/g` | Replace every `old` with `new` in the current file; add `c` to confirm each replacement. |
| `<leader>R` | Open project-wide find and replace; visual mode seeds it with the selection. |
| `:Telescope help_tags` | Example direct Telescope command. In any Telescope picker, use `?` (Normal) or `Ctrl+/` (Insert) to see its mappings. |

## Code intelligence (LSP)

These work only when a language server is attached to the current file.

| Key | Action |
|---|---|
| `K` | Hover documentation for the symbol under the cursor. |
| `grd` | Go to definition (`Ctrl+t` jumps back). |
| `grr` | Find references. |
| `gri` | Go to implementation. |
| `grt` | Go to type definition. |
| `grD` | Go to declaration. |
| `grn` | Rename symbol across files. |
| `gra` | Code action. |
| `gO` / `gW` | Document symbols / workspace symbols. |
| `[d` / `]d` | Previous / next diagnostic. |
| `<leader>q` | Put diagnostics in the location list. |
| `<leader>th` | Toggle inlay hints, if supported. |
| `<leader>f` | Format the current buffer. |

## Git changes

These are available in files inside a Git repository. The gutter uses `+` for added,
`~` for changed, and `_` / `‾` for deleted lines.

| Key | Action |
|---|---|
| `]c` / `[c` | Next / previous changed hunk. |
| `<leader>hp` | Preview a hunk. |
| `<leader>hi` | Preview a hunk inline. |
| `<leader>hb` | Blame the current line. |
| `<leader>hd` | Diff the current file against the index. |
| `<leader>hs` / `<leader>hr` | Stage / reset the current hunk (also in Visual mode). |
| `<leader>tb` | Toggle persistent inline blame. |

## Terminal, windows, and editing

| Key / command | Action |
|---|---|
| `Ctrl+\` / `<leader>tt` | Toggle the floating terminal. |
| `Esc Esc` | Leave terminal-insert mode. |
| `Ctrl+h` / `Ctrl+j` / `Ctrl+k` / `Ctrl+l` | Focus left / lower / upper / right split. |
| `:split` / `:vsplit` | Create a horizontal / vertical split. |
| `Esc` | Clear search highlighting. |
| `gc` (Visual) / `gcc` | Toggle comment for selection / line. |
| `saiw)` / `sd'` / `sr)'` | Add / delete / replace surrounding delimiters. |

The system clipboard is enabled, so normal `y` and `p` use the macOS clipboard.

## Completion and snippets (Insert mode)

| Key | Action |
|---|---|
| `Ctrl+y` | Accept the selected completion. |
| `Ctrl+Space` | Open the completion menu or toggle its documentation. |
| `Ctrl+n` / `Ctrl+p` | Select the next / previous completion. |
| `Ctrl+e` | Dismiss the completion menu. |
| `Ctrl+k` | Toggle signature help. |
| `Tab` / `Shift+Tab` | Move forward / backward through snippet placeholders. |

## Setup and maintenance commands

| Command | Action |
|---|---|
| `:checkhealth` | Diagnose Neovim and plugin health. |
| `:Mason` | View or manage installed language servers and tools (`g?` for help). |
| `:lua vim.pack.update(nil, { offline = true })` | Inspect plugin state without fetching updates. |
| `:lua vim.pack.update()` | Update plugins. |
