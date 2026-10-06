-- Run from the plugin root with -u NONE and this root on runtimepath.
-- Optional MARKDOWN_TABLE_WRAP_BENCH_FILE is read into an unnamed test buffer.
local plugin = require("markdown-table-wrap")
local reader = require("markdown-table-wrap.reader")
local cache = require("markdown-table-wrap.cache")
local original_columns = vim.o.columns
vim.o.columns = 200
plugin.setup({ auto_preview = false, max_width_ratio = 0.95, min_col_width = 6, max_col_width = 50 })

local lines
local path = vim.env.MARKDOWN_TABLE_WRAP_BENCH_FILE
if path and path ~= "" then
  lines = vim.fn.readfile(path)
else
  lines = { "# Resize benchmark", "", "| Name | Link | Description |", "| --- | --- | --- |" }
  for index = 1, 200 do
    lines[#lines + 1] = string.format(
      "| Item %d | [documentation](docs/item-%d.md) | **Styled prose** with `code_%d` and a longer explanation that wraps inside its cell. |",
      index,
      index,
      index
    )
  end
end
local source = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(source)
vim.bo[source].filetype = "markdown"
vim.bo[source].swapfile = false
vim.api.nvim_buf_set_lines(source, 0, -1, false, lines)
vim.bo[source].modified = false
local document_win = vim.api.nvim_get_current_win()

local function elapsed(callback)
  collectgarbage("collect")
  local start = vim.uv.hrtime()
  local result = callback()
  return (vim.uv.hrtime() - start) / 1e6, result
end
local open_ms, view = elapsed(function()
  return plugin.reader_preview()
end)
assert(reader.is_reader(view))
print(
  string.format(
    "Cold open: %.2f ms; %d Source lines -> %d Reader lines",
    open_ms,
    #lines,
    vim.api.nvim_buf_line_count(view)
  )
)
for round = 1, 4 do
  vim.cmd("topleft 40vnew")
  local sidebar_win = vim.api.nvim_get_current_win()
  local narrow_ms = elapsed(function()
    return reader.refresh_windows({ document_win }, { if_changed = true })
  end)
  vim.api.nvim_win_close(sidebar_win, true)
  local wide_ms = elapsed(function()
    return reader.refresh_windows({ document_win }, { if_changed = true })
  end)
  print(string.format("Round %d: sidebar open %.2f ms; close %.2f ms", round, narrow_ms, wide_ms))
end
local diagnostics = cache.inspect(source)
print(
  string.format(
    "Cache: %d layout variants; %d hits / %d misses",
    diagnostics.layout_entries or 0,
    diagnostics.hits,
    diagnostics.misses
  )
)
local noop_ms, rebuilt = elapsed(function()
  return reader.refresh_windows({ document_win }, { if_changed = true })
end)
print(string.format("Unchanged resize: %.2f ms; %d Readers rebuilt", noop_ms, rebuilt))
assert(vim.deep_equal(vim.api.nvim_buf_get_lines(source, 0, -1, false), lines), "benchmark changed Source")
plugin.close_reader()
vim.api.nvim_buf_delete(source, { force = true })
vim.o.columns = original_columns
