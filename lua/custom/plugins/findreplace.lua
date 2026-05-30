-- Project-wide find & replace: grug-far (https://github.com/MagicDuck/grug-far.nvim)
-- Opens a buffer where you type a search + replacement and apply it across the
-- whole project (ripgrep-backed). For single-file replace, just use `:%s/old/new/g`.

vim.pack.add { 'https://github.com/MagicDuck/grug-far.nvim' }

require('grug-far').setup {}

-- Open the find/replace panel. In visual mode it seeds the search with your selection.
vim.keymap.set({ 'n', 'v' }, '<leader>R', function()
  require('grug-far').open { transient = true }
end, { desc = 'Find & [R]eplace (project-wide)' })
