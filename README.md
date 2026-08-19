# Neovim config

My personal Neovim configuration, built on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim).
Uses Neovim's built-in plugin manager (`vim.pack`) with all language servers auto-installed by Mason.

## Highlights

- **Neovim 0.12+** required — uses the built-in `vim.pack` plugin manager (no bootstrap code)
- LSP + completion (blink.cmp), Telescope, treesitter, conform formatting
- Kanagawa theme, neo-tree explorer, bufferline tabs, toggleterm, grug-far, csvview
- First launch installs every plugin, server, and parser automatically

## Install

Requires Neovim **0.12+**, `git`, `make`, a C compiler, `unzip`, `ripgrep`, and — for
most language servers — Node.js. See [SETUP.md](SETUP.md#1-prerequisites) for
per-OS install commands and the full dependency breakdown.

Back up any existing config first (`~/.config/nvim`, `~/.local/share/nvim`), then:

```sh
git clone https://github.com/cameyer260/latest-nvim-config.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
nvim   # plugins + servers install on first launch; restart when done
```

On Windows clone to `%localappdata%\nvim` instead.

## Docs

- [SETUP.md](SETUP.md) — prerequisites per OS, language-server host dependencies, gotchas
- [KEYBINDINGS.md](KEYBINDINGS.md) — every keymap and useful command

## License

MIT — derived from kickstart.nvim (TJ DeVries), see [LICENSE.md](LICENSE.md).
