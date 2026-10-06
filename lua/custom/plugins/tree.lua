-- File explorer: neo-tree (https://github.com/nvim-neo-tree/neo-tree.nvim)
-- Shows ALL files (including dotfiles like .env and gitignored files) and
-- supports create / delete / rename / move / copy directly in the tree.

local plugins = {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}
if vim.g.have_nerd_font then
  table.insert(plugins, 'https://github.com/nvim-tree/nvim-web-devicons')
end
vim.pack.add(plugins)

require('neo-tree').setup {
  close_if_last_window = true,
  filesystem = {
    bind_to_cwd = false,
    follow_current_file = { enabled = true }, -- highlight the file you're editing
    use_libuv_file_watcher = true, -- auto-refresh tree on external changes
    filtered_items = {
      visible = true, -- show filtered items by default (no need to toggle)
      hide_dotfiles = false, -- show .env, .gitignore, etc.
      hide_gitignored = false, -- show node_modules, build dirs, etc.
      hide_hidden = false, -- (Windows) show hidden files
    },
  },
  window = {
    -- In-tree file management keys (these are neo-tree defaults, listed for reference):
    --   a = add file/dir (end name with / for a dir)   A = add directory
    --   d = delete    r = rename    m = move    c = copy    y/x = copy/cut    p = paste
    --   H = toggle hidden-file filter    R = refresh    ? = show all mappings
    mappings = {
      ['\\'] = 'close_window',
    },
  },
}

local function open_tree(opts)
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].markdown_table_wrap_reader == true then
    -- Reveal the backing file without switching out of Reader. Never fall back
    -- to its virtual URI if the source has been deleted or is unnamed.
    opts.reveal = false
    local source = vim.b[buf].markdown_table_wrap_source
    if type(source) == 'number' and vim.api.nvim_buf_is_valid(source) then
      local path = vim.api.nvim_buf_get_name(source)
      if path ~= '' then opts.reveal_file = path end
    end
  end
  require('neo-tree.command').execute(opts)
end

-- Toggle the tree (reveals current file's location); press again to close.
vim.keymap.set('n', '<leader>e', function() open_tree { toggle = true, reveal = true, position = 'left' } end, {
  desc = 'File [E]xplorer toggle',
  silent = true,
})
-- Jump focus into the tree without toggling it.
vim.keymap.set('n', '<leader>o', function() open_tree { action = 'focus' } end, { desc = 'Focus file explorer', silent = true })
