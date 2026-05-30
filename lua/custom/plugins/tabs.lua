-- Tabs: bufferline (https://github.com/akinsho/bufferline.nvim)
-- A row of tabs across the top, one per open file (like Chrome tabs).
-- In Vim terms each "tab" here is a *buffer*; bufferline just renders them as tabs.

local plugins = { 'https://github.com/akinsho/bufferline.nvim' }
if vim.g.have_nerd_font then
  table.insert(plugins, 'https://github.com/nvim-tree/nvim-web-devicons')
end
vim.pack.add(plugins)

require('bufferline').setup {
  options = {
    diagnostics = 'nvim_lsp', -- show LSP error/warning counts on each tab
    show_buffer_close_icons = true,
    show_close_icon = false,
    separator_style = 'thin',
    offsets = {
      { filetype = 'neo-tree', text = 'File Explorer', highlight = 'Directory', separator = true },
    },
  },
}

local map = vim.keymap.set

-- Move left / right through tabs (replaces default H/L screen-motion).
map('n', '<S-l>', '<Cmd>BufferLineCycleNext<CR>', { desc = 'Next tab' })
map('n', '<S-h>', '<Cmd>BufferLineCyclePrev<CR>', { desc = 'Previous tab' })

-- Reorder the current tab left / right.
map('n', '<leader>b<', '<Cmd>BufferLineMovePrev<CR>', { desc = 'Move tab left' })
map('n', '<leader>b>', '<Cmd>BufferLineMoveNext<CR>', { desc = 'Move tab right' })

-- Close the current tab (keeps your window layout intact).
map('n', '<leader>bd', '<Cmd>bdelete<CR>', { desc = 'Close tab (buffer)' })
-- Close every tab except the current one.
map('n', '<leader>bo', '<Cmd>BufferLineCloseOthers<CR>', { desc = 'Close other tabs' })
-- New empty tab; then `:w name.ext` to name + create the file on disk.
map('n', '<leader>bn', '<Cmd>enew<CR>', { desc = 'New (untitled) tab' })
-- Jump to a tab by its letter (pick mode).
map('n', '<leader>bp', '<Cmd>BufferLinePick<CR>', { desc = 'Pick tab by letter' })

-- Jump directly to tab 1-9 with <leader>1 .. <leader>9
for i = 1, 9 do
  map('n', '<leader>' .. i, function() require('bufferline').go_to(i, true) end, { desc = 'Go to tab ' .. i })
end
