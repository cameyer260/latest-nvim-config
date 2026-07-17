-- CSV/TSV table display: aligns fields visually without changing file contents.
vim.pack.add { 'https://github.com/hat0uma/csvview.nvim' }

require('csvview').setup {
  view = {
    display_mode = 'border',
    sticky_header = { enabled = true },
  },
  keymaps = {
    -- Spreadsheet-style navigation while CSV view is active.
    jump_next_field_end = { '<Tab>', mode = { 'n', 'v' } },
    jump_prev_field_end = { '<S-Tab>', mode = { 'n', 'v' } },
    jump_next_row = { '<Enter>', mode = { 'n', 'v' } },
    jump_prev_row = { '<S-Enter>', mode = { 'n', 'v' } },
  },
}

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'csv', 'tsv' },
  callback = function()
    vim.cmd 'CsvViewEnable'
  end,
})
