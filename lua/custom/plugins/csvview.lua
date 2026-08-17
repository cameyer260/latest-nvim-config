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

-- Sticky header mirrors the gutter via nvim_eval_statusline({ use_statuscol_lnum = vim.v.lnum }).
-- Neovim rejects lnum < 1 (and past EOF). During float open/close/scroll races, statuscolumn
-- can run with vim.v.lnum == 0 and error. Skip those frames; keep sticky headers enabled.
local sticky_header = require 'csvview.sticky_header'
local eval_statuscolumn = sticky_header.statuscolumn
function sticky_header.statuscolumn(winid)
  local lnum = vim.v.lnum
  if type(lnum) ~= 'number' or lnum < 1 then
    return ''
  end
  if vim.api.nvim_win_is_valid(winid) then
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if lnum > vim.api.nvim_buf_line_count(bufnr) then
      return ''
    end
  end
  return eval_statuscolumn(winid)
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'csv', 'tsv' },
  callback = function()
    vim.cmd 'CsvViewEnable'
  end,
})
