-- Herdr forwards OSC 52 writes, but does not answer clipboard-read requests.
-- Keep a local copy (including register type) so p/P never query the terminal.
local M = {}
local cached = { { '' }, 'v' }
local copy_osc52 = require('vim.ui.clipboard.osc52').copy '+'

local function copy(lines, regtype)
  cached = { vim.deepcopy(lines), regtype }
  copy_osc52(lines)
end

local function paste()
  return vim.deepcopy(cached)
end

function M.setup()
  vim.g.clipboard = {
    name = 'OSC 52 (copy only, local paste)',
    -- Both registers use the standard clipboard (c); Herdr does not forward
    -- writes to the primary selection (p) used by OSC 52's default * handler.
    copy = { ['+'] = copy, ['*'] = copy },
    paste = { ['+'] = paste, ['*'] = paste },
    cache_enabled = 0,
  }

  -- Also support loading this fix into an already-running Neovim instance.
  if vim.g.loaded_clipboard_provider ~= nil then
    vim.g.loaded_clipboard_provider = nil
    vim.cmd.runtime 'autoload/provider/clipboard.vim'
  end
end

return M
