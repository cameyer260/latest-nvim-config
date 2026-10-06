-- Keep Bufferline selection and close actions on the same logical Markdown file.
-- Bufferline has no public active-buffer resolver, so adapt its buffer models
-- and current-element lookup without swapping Neovim's actual current buffer.
local M = {}

local function source_buffer(buf)
  if vim.b[buf].markdown_table_wrap_reader == true then
    local source = vim.b[buf].markdown_table_wrap_source
    if type(source) == 'number' and vim.api.nvim_buf_is_valid(source) then return source end
  end
  return buf
end

function M.close_buffer(buf)
  -- Deleting Source lets the plugin dispose all its Readers, including those in
  -- other splits. Do not force deletion: unsaved Source edits must be protected.
  vim.cmd.bdelete { args = { tostring(source_buffer(buf or vim.api.nvim_get_current_buf())) } }
end

function M.setup()
  if M.installed then return end
  M.installed = true

  local Buffer = require('bufferline.models').Buffer
  local original_current = Buffer.current
  local original_visible = Buffer.visible
  local commands = require 'bufferline.commands'
  local original_index = commands.get_current_element_index
  local config = require 'bufferline.config'

  function Buffer:current()
    local current = vim.api.nvim_get_current_buf()
    local source = source_buffer(current)
    if source ~= current then return self.id == source end
    return original_current(self)
  end

  function Buffer:visible()
    if original_visible(self) then return true end
    -- A Reader in an unfocused split should also make its source tab "visible".
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if source_buffer(vim.api.nvim_win_get_buf(win)) == self.id then return true end
    end
    return false
  end

  -- Keep Bufferline's cycle/reorder/close-other commands on the same logical file
  -- that it highlights. Tabpage mode and ordinary buffers retain native behavior.
  function commands.get_current_element_index(state, opts)
    local current = vim.api.nvim_get_current_buf()
    local source = source_buffer(current)
    if source ~= current and not config:is_tabline() then
      local list = opts and opts.include_hidden and state.__components or state.components
      for index, item in ipairs(list) do
        local element = item:as_element()
        if element and element.id == source then return index, element end
      end
    end
    return original_index(state, opts)
  end

  vim.api.nvim_create_autocmd('User', {
    group = vim.api.nvim_create_augroup('custom-markdown-reader-bufferline', { clear = true }),
    pattern = { 'MarkdownTableWrapReaderEnter', 'MarkdownTableWrapReaderLeave' },
    callback = function()
      vim.schedule(function() vim.cmd.redrawtabline() end)
    end,
  })
end

return M
