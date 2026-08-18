# My Neovim setup

A lean, self-owned config built on **kickstart.nvim**. The goal: a real IDE in the
terminal, staying on the keyboard, with only the plugins I actually use — and every
line readable/editable by me.

- **Base:** kickstart.nvim (the heavily-commented `init.lua`)
- **Plugin manager:** `vim.pack` — Neovim's *built-in* manager. No lazy.nvim. Plugins
  are declared with `vim.pack.add { 'https://github.com/owner/repo' }` and bootstrap on
  first launch.
- **Theme:** Kanagawa (hardcoded, `kanagawa-wave`)

---

## 1. Prerequisites

Neovim **0.12+** is required (that's where `vim.pack` lives). Check with
`nvim --version`. Distro/package-manager versions are often older than that — see
the notes below.

### Core dependencies (every OS)

| Tool | Why |
|---|---|
| `git` | `vim.pack` clones plugins with it |
| `make` + C compiler (`gcc`/`clang`) | builds `telescope-fzf-native` and compiles treesitter parsers |
| `unzip` | Mason unpacks packages |
| `ripgrep` (`rg`) | Telescope file finding + live grep |
| Node.js 18+ (`node`) | runtime for most language servers — see §5 |

Notes:

- `fd` and `fzf` are **not** needed — Telescope is configured to use `rg` directly.
- `tree-sitter-cli` is optional: parser *installs* compile with your C compiler; the
  CLI is only needed to develop/generate parsers from grammars.
- Language toolchains (Ruby, Rust, C++, Python) are only needed if you work in those
  languages — see §5 for which server needs what on the host.

### macOS (Homebrew)

```bash
xcode-select --install          # make + clang (fzf-native build, treesitter parsers)
brew install neovim git ripgrep node
brew install ruby               # for ruby_lsp / rubocop (system ruby is too old/locked down)

# Optional, per language:
brew install rustup-init && rustup-init -y   # Rust toolchain (rust_analyzer needs it)
brew install python                          # so pyright can resolve your envs
brew install --cask font-jetbrains-mono-nerd-font   # Nerd Font (see below)
```

Then point your terminal at the Nerd Font — for Ghostty, in `~/.config/ghostty/config`:

```
font-family = JetBrainsMono Nerd Font
```

### Ubuntu / Debian

Distro Neovim is usually too old for `vim.pack`; use the stable PPA (or the release
tarball from neovim/neovim if you can't add PPAs):

```bash
sudo add-apt-repository ppa:neovim-ppa/stable -y
sudo apt update
sudo apt install neovim git make gcc unzip ripgrep nodejs npm
sudo apt install ruby-full        # for ruby_lsp / rubocop

# Optional: Rust toolchain (apt's rustc is often too old for rust_analyzer)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Check `node --version` — on older releases (e.g. 22.04) apt ships Node 12, which is
too old for most language servers; use [NodeSource](https://github.com/nodesource/distributions)
or `nvm` in that case.

### Other Linux

Same package set as Ubuntu: `neovim git make gcc unzip ripgrep nodejs ruby`
(via `dnf`, `pacman`, etc.). On Arch, `ripgrep`/`fd`-style naming quirks don't apply
here since only `rg` is used.

### Windows

Least-tested path — WSL with the Ubuntu steps above works best. Native option:
`choco install neovim git ripgrep unzip make mingw nodejs ruby`.

### Nerd Font (optional but recommended)

Icons in the tree/tabs come from a Nerd Font, and it only matters on the machine
**where your terminal runs** — a headless VPS needs nothing here. macOS: the brew
cask above. Linux desktop: install any Nerd Font (nerdfonts.com → `~/.local/share/fonts`)
and select it in your terminal emulator. The config assumes one
(`vim.g.have_nerd_font = true` in `init.lua`); set it `false` if you don't have one.

Verify everything: `nvim --version` (≥ 0.12), then inside nvim run `:checkhealth`.

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
├── init.lua                      # kickstart core, edited (see "What I changed")
├── README.md                     # overview + install
├── SETUP.md                      # this file
├── KEYBINDINGS.md                # shortcut & command reference
├── nvim-pack-lock.json           # pinned plugin versions (tracked on purpose)
└── lua/
    ├── kickstart/
    │   └── health.lua            # powers `:checkhealth` for this config
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
- Filled in the **LSP `servers`** table with my languages (see §5)
- Added **prettierd** to Mason + wired up `conform` formatters per filetype
- Expanded the **treesitter** parser list
- Telescope `find_files`/`live_grep` now include **hidden files** (skip `.git`)
- Added **gitsigns** keymaps (`on_attach`) to the `init.lua` setup — gutter signs were
  already on; this adds hunk preview/navigation/staging (see keybinding reference)
- Enabled `require 'custom.plugins'` to load my extra files
- Added **csvview.nvim** for an automatic, bordered table view of CSV and TSV files,
  including sticky headers and spreadsheet-style navigation

## 5. Language servers & host dependencies

Mason downloads each server itself on first launch — but a server is often just a
wrapper around tooling that must exist **on the host, in `$PATH`**. Without the host
dependency the server installs fine but won't start (check `:checkhealth` / `:Mason`).

| Language(s)            | Server(s)                          | Host requirement |
|------------------------|------------------------------------|------------------|
| JS / TS / JSX / TSX    | `ts_ls`, `eslint`                  | Node 18+ (`eslint` also wants eslint in the project: `npm i -D eslint`) |
| HTML + Emmet           | `html`, `emmet_language_server`    | Node |
| CSS / SCSS             | `cssls`                            | Node |
| Tailwind               | `tailwindcss`                      | Node |
| Astro                  | `astro`                            | Node |
| JSON                   | `jsonls`                           | Node |
| YAML                   | `yamlls`                           | Node |
| Python                 | `pyright`, `ruff`                  | Node (pyright is written in TS); `ruff` is standalone; `python3` recommended so pyright resolves your env |
| Rust                   | `rust_analyzer`                    | Rust toolchain (`rustup`) — server binary is standalone, but needs `cargo`/`rustc` to be useful |
| C / C++                | `clangd`                           | None (standalone binary); a compiler + `compile_commands.json` in the project makes it useful |
| Ruby                   | `ruby_lsp`, `rubocop`              | **Ruby 3.0+ with `gem`** — Mason installs the servers as gems into its own dir, but runs them with your host ruby |
| Bash                   | `bashls`                           | Node |
| Markdown               | `marksman`                         | None (standalone) |
| Lua (this config)      | `lua_ls`                           | None (standalone) |

Extra Mason tools: `prettierd` (needs Node) and `stylua` (standalone).

Formatting via `conform` (`<leader>f`): `prettierd` for the web stack, `ruff` for Python,
`rustfmt` for Rust, `rubocop` for Ruby, `stylua` for Lua. LSP formatting is the fallback.

---

# 6. Keybinding and command quick reference

See [KEYBINDINGS.md](KEYBINDINGS.md) for the consolidated shortcut and command reference.

---

## 7. Notes & gotchas

- **Clipboard:** the config sets `clipboard = unnamedplus`. On a desktop that needs a
  provider (`pbcopy` on macOS, `xclip`/`xsel` on X11, `wl-copy` on Wayland,
  `win32yank` on Windows). On a headless server there's nothing to copy to — Neovim
  just falls back, which is fine; yank/paste inside nvim still works.

---

## 8. Dump LSP diagnostics for an AI to fix

LSP **diagnostics** (errors/warnings about your code) only exist for *open* files,
since language servers attach per buffer. The script below grabs them for the whole
repo at once: it opens every tracked file headlessly, waits for the servers to
attach, and produces a plain-text dump of every diagnostic — hand that to your AI
harness and have it address the issues.

### The `nvim-diag` script

The output is copied to the clipboard (whatever the platform provides; prints to
stdout if none), so you can just paste it into the harness. Nothing is left on
disk: it routes through a temp file that's deleted on exit. Save as
`~/.local/bin/nvim-diag` and `chmod +x` it:

```bash
#!/usr/bin/env bash
# nvim-diag — copy Neovim LSP diagnostics to the clipboard for an AI to fix.
#   nvim-diag                  # all git-tracked files in the current repo
#   nvim-diag src/**/*.astro   # just these files/globs
set -euo pipefail

# Opening a whole repo + spawning language servers can exceed the default
# open-file limit (EMFILE). Raise it as high as the shell allows.
for n in 10240 8192 4096 2048; do ulimit -n "$n" 2>/dev/null && break; done

if [[ $# -gt 0 ]]; then
  files=("$@")
else
  files=()
  while IFS= read -r f; do files+=("$f"); done < <(git ls-files)   # portable: no `mapfile` (macOS ships Bash 3.2)
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

# Copy with whatever clipboard tool the platform provides; print if none.
if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$NVIM_DIAG_OUT"
elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
  wl-copy < "$NVIM_DIAG_OUT"
elif [[ -n "${DISPLAY:-}" ]] && command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard < "$NVIM_DIAG_OUT"
elif command -v clip.exe >/dev/null 2>&1; then
  clip.exe < "$NVIM_DIAG_OUT"   # WSL
else
  cat "$NVIM_DIAG_OUT"
  echo "$(grep -c . "$NVIM_DIAG_OUT") diagnostics printed above (no clipboard tool found)"
  exit 0
fi
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
