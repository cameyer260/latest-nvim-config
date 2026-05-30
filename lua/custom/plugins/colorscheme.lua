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
}

vim.cmd.colorscheme 'kanagawa-wave'
