-- Run from the config root:
-- nvim --headless -u NONE -i NONE -n -l tests/clipboard_spec.lua
-- No plugins, real clipboard writes, or user files are involved.
local config = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)))
vim.opt.runtimepath:prepend(config)

local writes = {}
vim.api.nvim_ui_send = function(sequence)
  local encoded = sequence:match('^\027%]52;c;([A-Za-z0-9+/=]*)\027\\$')
  assert(encoded, 'unexpected terminal sequence (clipboard read or primary selection)')
  writes[#writes + 1] = vim.base64.decode(encoded)
end
vim.wait = function()
  error('clipboard operations must not wait for terminal responses')
end

local function eq(expected, actual, label)
  assert(vim.deep_equal(expected, actual), label .. ': expected ' .. vim.inspect(expected) .. ', got ' .. vim.inspect(actual))
end

local function normal(keys)
  vim.cmd.normal { bang = true, args = { vim.api.nvim_replace_termcodes(keys, true, false, true) } }
end

local function buffer(lines)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

-- Initialize the old provider first to exercise the live-reload path as well.
vim.g.clipboard = 'osc52'
eq(1, vim.fn.has 'clipboard', 'old provider initialized')
local clipboard = require 'custom.clipboard'
clipboard.setup()
vim.o.clipboard = 'unnamedplus'
eq('OSC 52 (copy only, local paste)', vim.fn['provider#clipboard#Executable'](), 'new provider initialized')
eq({ '' }, vim.fn.getreg('+', 1, true), 'empty initial clipboard')
eq(0, #writes, 'paste does not write/query terminal')
print('PASS: live provider replacement and empty initial paste')

for _, kind in ipairs { 'v', 'V', '\0223' } do
  vim.fn.setreg('+', { 'abc', 'def' }, kind)
  eq({ 'abc', 'def' }, vim.fn.getreg('+', 1, true), 'cached + contents')
  eq(kind, vim.fn.getregtype '+', 'cached + register type')
  eq({ 'abc', 'def' }, vim.fn.getreg('*', 1, true), 'shared * clipboard')
  eq(kind, vim.fn.getregtype '*', 'shared * register type')
  eq(kind == 'v' and 'abc\ndef' or 'abc\ndef\n', writes[#writes], 'OSC 52 copy payload (' .. kind .. ')')
end
vim.fn.setreg('*', { 'from star' }, 'v')
eq({ 'from star' }, vim.fn.getreg('+', 1, true), '* writes update shared cache')
eq('from star', writes[#writes], '* writes target standard clipboard')
print('PASS: +/* copies and all register types')

local provider = vim.g.clipboard
local lines = { 'unchanged' }
provider.copy['+'](lines, 'v')
lines[1] = 'mutated source'
local pasted = provider.paste['+']()
pasted[1][1] = 'mutated result'
eq({ { 'unchanged' }, 'v' }, provider.paste['+'](), 'cache does not share mutable lists')
clipboard.setup()
eq({ 'unchanged' }, vim.fn.getreg('+', 1, true), 'repeated setup preserves cache')
print('PASS: cache isolation and repeated setup')

buffer { 'hello world' }
normal 'yiw'
normal 'p'
eq({ 'hhelloello world' }, vim.api.nvim_buf_get_lines(0, 0, -1, false), 'normal characterwise yank/paste')
eq('v', vim.fn.getregtype '+', 'characterwise type')

buffer { 'first', 'second' }
normal 'yy'
normal 'p'
eq({ 'first', 'first', 'second' }, vim.api.nvim_buf_get_lines(0, 0, -1, false), 'normal linewise yank/paste')
eq('V', vim.fn.getregtype '+', 'linewise type')

buffer { 'abcd', 'efgh', 'ijkl' }
normal '<C-v>jly'
eq('\0222', vim.fn.getregtype '+', 'blockwise type')
normal 'p'
eq({ 'aabbcd', 'eeffgh', 'ijkl' }, vim.api.nvim_buf_get_lines(0, 0, -1, false), 'normal blockwise yank/paste')
print('PASS: normal y/p for characterwise, linewise, and blockwise selections')

buffer { 'cut me', 'keep me' }
normal 'dd'
normal 'P'
eq({ 'cut me', 'keep me' }, vim.api.nvim_buf_get_lines(0, 0, -1, false), 'delete and paste-before')
print('PASS: cut/P round trip')

buffer { 'anchor' }
local previous = vim.fn.getreg('+', 1, true)
local writes_before = #writes
assert(vim.api.nvim_paste('from Mac\nsecond line', false, -1), 'terminal paste rejected')
eq({ 'afrom Mac', 'second linenchor' }, vim.api.nvim_buf_get_lines(0, 0, -1, false), 'terminal paste contents')
eq(previous, vim.fn.getreg('+', 1, true), 'terminal paste does not read/change local clipboard')
eq(writes_before, #writes, 'terminal paste does not send OSC 52')
print('PASS: terminal paste bypasses OSC 52')
print('ALL CLIPBOARD TESTS PASSED')
