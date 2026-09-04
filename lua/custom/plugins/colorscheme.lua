-- Colorscheme: Kanagawa (https://github.com/rebelot/kanagawa.nvim)
-- Warm, muted, low-contrast theme. Hardcoded — no toggle needed.
--
-- Variants you can swap into the colorscheme line below:
--   kanagawa-wave  (default, balanced)
--   kanagawa-dragon (darker)
--   kanagawa-lotus  (light)

vim.pack.add { 'https://github.com/rebelot/kanagawa.nvim' }

require('kanagawa').setup {
  commentStyle = { italic = false },
  keywordStyle = { italic = false },
  -- Don't remap ANSI colors 0-15 to Kanagawa's muted palette inside :terminal.
  -- Without this, the zsh prompt's green/magenta look washed-out grey.
  terminalColors = false,
}

vim.cmd.colorscheme 'kanagawa-wave'
