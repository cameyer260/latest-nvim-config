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
        ├── findreplace.lua       # grug-far (project-wide find & replace)
        └── csvview.lua           # spreadsheet-style CSV/TSV display
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
- Added **gitsigns** keymaps (`on_attach`) to the `init.lua` setup — gutter signs were
  already on; this adds hunk preview/navigation/staging (see keybinding reference)
- Enabled `require 'custom.plugins'` to load my extra files
- Added **csvview.nvim** for an automatic, bordered table view of CSV and TSV files,
  including sticky headers and spreadsheet-style navigation

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

# 6. Keybinding and command quick reference

See [KEYBINDINGS.md](KEYBINDINGS.md) for the consolidated shortcut and command reference.

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

---

## 8. Dump LSP diagnostics for an AI to fix

The orange underlines and `W`/`E` markers in the gutter are LSP **diagnostics** (warnings/
errors about the *code*) — not git changes and not "unsaved edits". When they pile up, you can
export them all to a plain file and hand it to an AI agent ("read this file and fix every
issue"). They're the merged output of every attached server (`ts_ls`, `tailwindcss`, `astro`,
`eslint`, …); there's no single CLI that reproduces them (notably, tailwind's class warnings
**only** exist in the language server), so the trick is to let Neovim itself produce them.

### The `nvim-diag` script

Launches Neovim headlessly with *this* config, opens the files so every server attaches, waits
for them to report, collects the diagnostics, and copies them to the clipboard (via `pbcopy`) —
then you just paste into the AI. Nothing is left on disk: it routes through a temp file that's
deleted on exit. Save as `~/.local/bin/nvim-diag` and `chmod +x` it:

```bash
#!/usr/bin/env bash
# nvim-diag — copy Neovim LSP diagnostics to the clipboard for an AI to fix.
#   nvim-diag                  # all git-tracked files in the current repo
#   nvim-diag src/**/*.astro   # just these files/globs
set -euo pipefail

# macOS defaults to a 256 open-file limit; opening a whole repo + spawning the
# language servers blows past it (EMFILE). Raise it as high as the shell allows.
for n in 10240 8192 4096 2048; do ulimit -n "$n" 2>/dev/null && break; done

if [[ $# -gt 0 ]]; then
  files=("$@")
else
  files=()
  while IFS= read -r f; do files+=("$f"); done < <(git ls-files)   # macOS Bash 3.2 has no `mapfile`
fi
[[ ${#files[@]} -eq 0 ]] && { echo "no files to scan"; exit 1; }

# Ephemeral scratch file: written by nvim, copied to the clipboard, then removed.
tmpdir="${TMPDIR:-/tmp}"; export NVIM_DIAG_OUT="${tmpdir%/}/nvim-diag-$$.txt"
trap 'rm -f "$NVIM_DIAG_OUT"' EXIT

nvim --headless -n "${files[@]}" \
  -c 'set shortmess+=A' \
  -c 'silent! argdo edit' \
  -c 'lua vim.wait(15000, function() return #vim.lsp.get_clients() > 0 end, 200); vim.wait(5000)' \
  -c 'lua local o=os.getenv("NVIM_DIAG_OUT"); local L={}; for _,d in ipairs(vim.diagnostic.get(nil)) do if d.severity<=vim.diagnostic.severity.WARN then local f=vim.fn.fnamemodify(vim.api.nvim_buf_get_name(d.bufnr),":."); L[#L+1]=string.format("%s:%d:%d: [%s] %s (%s)",f,d.lnum+1,d.col+1,vim.diagnostic.severity[d.severity],d.message:gsub("%s+"," "),d.source or "") end end; table.sort(L); vim.fn.writefile(L,o); io.stderr:write(#L.." diagnostics\n")' \
  -c 'qa!' || true   # nvim may exit nonzero on LSP noise; we still want the output

[[ -f "$NVIM_DIAG_OUT" ]] || { echo "no output produced"; exit 1; }
pbcopy < "$NVIM_DIAG_OUT"   # macOS clipboard; swap for wl-copy/xclip on Linux
echo "$(grep -c . "$NVIM_DIAG_OUT") diagnostics copied to clipboard"
```

Run it from inside any project, then just **paste** into the AI ("fix every warning/error"):

```bash
nvim-diag        # scans tracked files → copies to clipboard, prints the count
```

Each clipboard line is `file:line:col: [SEVERITY] message (source)`:

```
src/pages/index.astro:142:18: [WARN] 'p-4' applies the same properties as 'px-2' (tailwindcss)
src/lib/util.ts:9:7: [ERROR] 'foo' is declared but never used (typescript)
```

- It only reports the files you pass in (LSPs analyze open buffers only) — the default
  `git ls-files` covers the repo; a single arg gives just that file.
- `d.severity<=WARN` keeps errors + warnings; remove that check to include hints/info.
- First run in a new project pauses while Mason's servers attach — that's the `vim.wait`.
- `pbcopy` is macOS-only; on Linux swap it for `wl-copy` (Wayland) or `xclip -selection clipboard`.
