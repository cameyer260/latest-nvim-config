-- Terminal: toggleterm (https://github.com/akinsho/toggleterm.nvim)
-- A floating terminal you can pop open and dismiss without leaving Neovim.

vim.pack.add { 'https://github.com/akinsho/toggleterm.nvim' }

require('toggleterm').setup {
  open_mapping = [[<C-\>]], -- Ctrl-\ toggles the terminal in any mode
  direction = 'float',
  float_opts = { border = 'rounded' },
  start_in_insert = true,
}

-- Leader alias for the same toggle (handy if your terminal eats Ctrl-\).
vim.keymap.set('n', '<leader>tt', '<Cmd>ToggleTerm<CR>', { desc = '[T]oggle [T]erminal' })

-- While inside the floating terminal:
--   <Esc><Esc>  -> leave terminal-insert mode (set in init.lua)
--   <C-\>       -> hide the terminal
