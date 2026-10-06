local h = require("tests.helpers")

h.test("layout cache retains widths with bounded LRU eviction", function()
  local cache = require("markdown-table-wrap.cache")
  cache.configure({ enabled = true })
  h.with_buffer({ "cache fixture" }, function(buf)
    cache.clear_buffer(buf)
    for _, key in ipairs({ "wide", "narrow", "third" }) do
      cache.set_ref(buf, "layout:table", key, 1, { key = key })
    end
    h.assert_eq("wide layout survives a narrow render", cache.get_ref(buf, "layout:table", "wide", 1).key, "wide")
    cache.set_ref(buf, "layout:table", "fourth", 1, { key = "fourth" })
    h.assert_eq("least recently used layout is evicted", cache.get_ref(buf, "layout:table", "narrow", 1), nil)
    h.assert_true("recently accessed wide layout survives", cache.get_ref(buf, "layout:table", "wide", 1) ~= nil)
    h.assert_true("third layout survives", cache.get_ref(buf, "layout:table", "third", 1) ~= nil)
    h.assert_eq("layout storage is bounded", cache.inspect(buf).layout_entries, 3)
    cache.set_ref(buf, "parse", "first", 1, { value = "first" })
    cache.set_ref(buf, "parse", "second", 1, { value = "second" })
    h.assert_eq("non-layout stages still retain one key", cache.get_ref(buf, "parse", "first", 1), nil)
  end)
end)

h.test("layout variants respect source generations, public copies, disable and cleanup", function()
  local cache = require("markdown-table-wrap.cache")
  cache.configure({ enabled = true })
  h.with_buffer({ "cache fixture" }, function(buf)
    local value = { nested = { text = "original" } }
    cache.set(buf, "layout:table", "wide", 1, value)
    cache.set_ref(buf, "layout:table", "narrow", 1, { text = "narrow" })
    value.nested.text = "caller mutation"
    local copy = cache.get(buf, "layout:table", "wide", 1)
    h.assert_eq("public set isolates its input", copy.nested.text, "original")
    copy.nested.text = "result mutation"
    h.assert_eq("public get isolates its result", cache.get(buf, "layout:table", "wide", 1).nested.text, "original")
    h.assert_eq("wrong changedtick never hits", cache.get_ref(buf, "layout:table", "wide", 2), nil)
    cache.set_ref(buf, "layout:old-line-range", "wide", 1, { text = "old table ID" })
    cache.set_ref(buf, "layout:table", "wide", 2, { text = "edited" })
    h.assert_eq("a new generation drops every old width", cache.get_ref(buf, "layout:table", "narrow", 1), nil)
    h.assert_eq("one layout in the new generation", cache.inspect(buf).layout_entries, 1)
    h.assert_false("old table IDs are released", vim.tbl_contains(cache.inspect(buf).stages, "layout:old-line-range"))
    cache.set_ref(buf, "layout:other", "wide", 2, false)
    h.assert_eq("public false values survive", cache.get(buf, "layout:other", "wide", 2), false)
    cache.clear_buffer(buf)
    h.assert_eq("buffer cleanup releases every variant", cache.inspect(buf).layout_entries, 0)
    cache.configure({ enabled = false })
    cache.set(buf, "layout:table", "wide", 2, value)
    cache.set_ref(buf, "layout:table", "narrow", 2, value)
    h.assert_eq("disabled cache never stores variants", cache.inspect(buf).entries, 0)
    h.assert_eq("disabled cache never returns a value", cache.get_ref(buf, "layout:table", "wide", 2), nil)
    cache.configure({ enabled = true })
  end)
end)

h.test("returning to a sidebar width reuses layout without rewrapping cells", function()
  local plugin = require("markdown-table-wrap")
  local parser = require("markdown-table-wrap.parser")
  local render = require("markdown-table-wrap.render")
  local wrap = require("markdown-table-wrap.wrap")
  plugin.setup({ auto_preview = false, max_width_ratio = 1, min_col_width = 4, max_col_width = 50 })
  h.with_buffer({
    "| Name | Description |",
    "| --- | --- |",
    "| one | a longer cell that must wrap differently at each window width |",
  }, function(buf)
    vim.bo[buf].filetype = "markdown"
    local area = 96
    local original_area = render.text_area_width
    local original_wrap = wrap.wrap_cell
    local calls = 0
    render.text_area_width = function()
      return area
    end
    wrap.wrap_cell = function(...)
      calls = calls + 1
      return original_wrap(...)
    end
    local ok, err = pcall(function()
      local model = parser.parse_all_ref(buf)[1]
      local wide = render.render_table_ref(model, plugin.config)
      area = 48
      local narrow = render.render_table_ref(model, plugin.config)
      h.assert_false("different widths have independent models", wide == narrow)
      h.assert_false("narrow layout really changes columns", vim.deep_equal(wide.column_widths, narrow.column_widths))
      local cold_calls = calls
      area = 96
      h.assert_true("returning to wide restores its model", wide == render.render_table_ref(model, plugin.config))
      area = 48
      h.assert_true("returning to narrow restores its model", narrow == render.render_table_ref(model, plugin.config))
      h.assert_eq("repeat toggles do not rewrap any cells", calls, cold_calls)
      local changed_config = vim.deepcopy(plugin.config)
      changed_config.max_col_width = 12
      h.assert_false("geometry options remain in the key", narrow == render.render_table_ref(model, changed_config))
      vim.api.nvim_buf_set_lines(buf, 2, 3, false, { "| changed | edited Source |" })
      local edited = parser.parse_all_ref(buf)[1]
      local updated = render.render_table_ref(edited, plugin.config)
      h.assert_false("Source edits never restore an old model", narrow == updated)
      h.assert_true("edited text is rendered", table.concat(updated.lines, "\n"):find("changed", 1, true) ~= nil)
    end)
    render.text_area_width = original_area
    wrap.wrap_cell = original_wrap
    if not ok then
      error(err)
    end
  end)
end)

h.test("Reader reuses overlay chunks without exposing mutable public results", function()
  local plugin = require("markdown-table-wrap")
  local reader = require("markdown-table-wrap.reader")
  local render = require("markdown-table-wrap.render")
  plugin.setup({ auto_preview = false, min_col_width = 4, max_col_width = 20 })
  h.with_buffer({ "| Name | Detail |", "| --- | --- |", "| [docs](docs.md) | **bold** `code` |" }, function(buf)
    vim.bo[buf].filetype = "markdown"
    local original_chunks = render.display_chunks
    local calls = 0
    render.display_chunks = function(...)
      calls = calls + 1
      return original_chunks(...)
    end
    local view
    local ok, err = pcall(function()
      view = plugin.reader_preview()
      local namespace = vim.api.nvim_create_namespace("markdown-table-wrap-reader")
      local function overlays()
        local result = {}
        for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(view, namespace, 0, -1, { details = true })) do
          result[#result + 1] = { mark[2], mark[3], mark[4] }
        end
        return result
      end
      local expected = overlays()
      local initial_calls = calls
      h.assert_true("initial Reader builds overlay chunks", initial_calls > 0)
      h.assert_true("explicit refresh remains supported", reader.refresh(view))
      h.assert_eq("unchanged models reuse chunks", calls, initial_calls)
      h.assert_deep_eq("cached overlays preserve styling", overlays(), expected)
      local line = reader.line_object(view, 2)
      local public = render.display_chunks(line, 2)
      public[1][1] = "caller mutation"
      h.assert_false("public chunks are independent", render.display_chunks(line, 2)[1][1] == "caller mutation")
      vim.api.nvim_buf_set_lines(buf, 2, 3, false, { "| changed | *new style* |" })
      local before_edit = calls
      reader.refresh(view)
      h.assert_true("edited models get fresh chunks", calls > before_edit)
    end)
    render.display_chunks = original_chunks
    plugin.close_reader()
    plugin.state.paused_buffers[buf] = nil
    if not ok then
      error(err)
    end
  end)
end)

h.test("resize events skip no-op layouts but source edits and explicit refresh still rebuild", function()
  local plugin = require("markdown-table-wrap")
  local reader = require("markdown-table-wrap.reader")
  plugin.setup({ auto_preview = false })
  h.with_buffer({ "| A | B |", "| --- | --- |", "| one | two |" }, function(buf)
    vim.bo[buf].filetype = "markdown"
    local win = vim.api.nvim_get_current_win()
    local view = plugin.reader_preview()
    local tick = vim.api.nvim_buf_get_changedtick(view)
    h.assert_eq("unchanged geometry does not rebuild", reader.refresh_windows({ win }, { if_changed = true }), 0)
    h.assert_eq("no-op resize does not rewrite Reader", vim.api.nvim_buf_get_changedtick(view), tick)
    vim.api.nvim_exec_autocmds("VimResized", { modeline = false })
    h.assert_eq("the real resize handler also skips no-ops", vim.api.nvim_buf_get_changedtick(view), tick)
    h.assert_eq("explicit refresh is still forced", reader.refresh_windows({ win }), 1)
    vim.api.nvim_buf_set_lines(buf, 2, 3, false, { "| edited | Source |" })
    h.assert_eq("same-width Source edits still rebuild", reader.refresh_windows({ win }, { if_changed = true }), 1)
    h.assert_true(
      "the new Source is visible",
      table.concat(vim.api.nvim_buf_get_lines(view, 0, -1, false), "\n"):find("edited", 1, true) ~= nil
    )
    plugin.close_reader()
    plugin.state.paused_buffers[buf] = nil
  end)
end)
