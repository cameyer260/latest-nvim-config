-- Markdown prose keeps its styling; table-bearing documents use a real-text Reader.
-- Rendering never rewrites the source Markdown or requires horizontal-scroll keys.
vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }

-- This local fork is versioned with the config, outside vim.pack's downloads.
-- Plugin updates cannot overwrite its Reader performance fixes.
local table_wrap_path = vim.fs.joinpath(vim.fn.stdpath 'config', 'vendor', 'markdown-table-wrap.nvim')
vim.opt.runtimepath:prepend(table_wrap_path)

-- Avoid two plugins drawing the same table. Use the default cursor-line reveal
-- behavior in Source instead of making native motions traverse invisible URLs.
require('render-markdown').setup { pipe_table = { enabled = false } }

local function attach_keymaps(buf)
  vim.keymap.set('n', '<leader>mr', '<cmd>MarkdownTableToggleReader<CR>', {
    buffer = buf,
    desc = 'Toggle Markdown [R]eader/source',
  })
  vim.keymap.set('n', '<leader>me', '<cmd>MarkdownTableEditSource<CR>', {
    buffer = buf,
    desc = 'Markdown: [E]dit source',
  })
  require('which-key').add {
    { '<leader>m', group = '[M]arkdown', buffer = buf },
  }
end

-- Reader retains the Markdown filetype, so these mappings work in both views.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('custom-markdown-keymaps', { clear = true }),
  pattern = 'markdown',
  callback = function(args) attach_keymaps(args.buf) end,
})
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.bo[buf].filetype == 'markdown' then attach_keymaps(buf) end
end

require('markdown-table-wrap').setup {
  preview_mode = 'reader',
  max_width_ratio = 0.95,
  min_col_width = 6,
  max_col_width = 50,
  highlight_preset = 'auto',
  reader = {
    -- Let the cursor track the Reader's actual text, not its highlighting overlay.
    concealcursor = '',
  },
  mappings = {
    reader = {
      edit = '<leader>me', -- Preserve native e (end of word).
      passthrough = {
        H = 'previous_buffer',
        L = 'next_buffer',
        ['<leader><leader>'] = 'alternate_buffer',
        ['<leader>f'] = { policy = 'source' },
      },
    },
  },
}
