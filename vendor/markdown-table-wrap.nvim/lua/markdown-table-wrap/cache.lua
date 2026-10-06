local M = {}

local buffers = {}
local enabled = true
local counters = { hits = 0, misses = 0, writes = 0 }
local layout_limit = 3

local function entry(bufnr)
  buffers[bufnr] = buffers[bufnr] or { stages = {} }
  return buffers[bufnr]
end

local function touch_layout(value, key)
  for index, cached_key in ipairs(value.order) do
    if cached_key == key then
      table.remove(value.order, index)
      break
    end
  end
  value.order[#value.order + 1] = key
end

local function lookup(bufnr, stage, key, changedtick)
  if not enabled or not bufnr then
    counters.misses = counters.misses + 1
    return nil
  end
  local buffer = buffers[bufnr]
  local value = buffer and buffer.stages[stage]
  if value and value.changedtick == changedtick then
    if value.layouts and value.layouts[key] ~= nil then
      touch_layout(value, key)
      counters.hits = counters.hits + 1
      return value.layouts[key]
    elseif not value.layouts and value.key == key then
      counters.hits = counters.hits + 1
      return value.value
    end
  end
  counters.misses = counters.misses + 1
  return nil
end

local function store(bufnr, stage, key, changedtick, value)
  local buffer = entry(bufnr)
  if buffer.changedtick ~= changedtick then
    -- Table IDs include their Source line range. Release old IDs as well as
    -- old widths, so inserting/removing rows cannot grow the cache forever.
    buffer.stages = {}
    buffer.changedtick = changedtick
  end
  if type(stage) == "string" and stage:sub(1, 7) == "layout:" then
    -- Keep both sidebar widths (plus one recent resize), not only the last one.
    -- Geometry/options remain in the key; a Source edit drops all old variants.
    local cached = buffer.stages[stage]
    if not cached or not cached.layouts or cached.changedtick ~= changedtick then
      cached = { changedtick = changedtick, layouts = {}, order = {} }
      buffer.stages[stage] = cached
    end
    cached.layouts[key] = value
    touch_layout(cached, key)
    if #cached.order > layout_limit then
      cached.layouts[table.remove(cached.order, 1)] = nil
    end
  else
    buffer.stages[stage] = { key = key, changedtick = changedtick, value = value }
  end
  counters.writes = counters.writes + 1
end

function M.configure(opts)
  opts = type(opts) == "table" and opts or {}
  enabled = opts.enabled ~= false
  if not enabled then
    M.clear()
  end
end

function M.get(bufnr, stage, key, changedtick)
  local value = lookup(bufnr, stage, key, changedtick)
  if value == nil then
    return nil
  end
  return vim.deepcopy(value)
end

-- Internal derived-model fast path. Callers must treat the returned value as
-- read-only; public boundaries continue to use get() and receive an isolated
-- copy.
function M.get_ref(bufnr, stage, key, changedtick)
  return lookup(bufnr, stage, key, changedtick)
end

function M.set(bufnr, stage, key, changedtick, value)
  if enabled and bufnr then
    store(bufnr, stage, key, changedtick, vim.deepcopy(value))
  end
  return value
end

-- Internal companion to get_ref(). Ownership transfers to the cache and the
-- value must not be mutated afterwards.
function M.set_ref(bufnr, stage, key, changedtick, value)
  if enabled and bufnr then
    store(bufnr, stage, key, changedtick, value)
  end
  return value
end

function M.clear_buffer(bufnr)
  buffers[bufnr] = nil
end

function M.clear()
  buffers = {}
  counters = { hits = 0, misses = 0, writes = 0 }
  local loaded, markdown = pcall(require, "markdown-table-wrap.markdown")
  if loaded and markdown.clear_cache then
    markdown.clear_cache()
  end
end

function M.inspect(bufnr)
  local stages = {}
  local layout_entries = 0
  for name, value in pairs((buffers[bufnr] or {}).stages or {}) do
    table.insert(stages, name)
    layout_entries = layout_entries + (value.layouts and #value.order or 0)
  end
  table.sort(stages)
  return {
    enabled = enabled,
    stages = stages,
    entries = #stages,
    layout_entries = layout_entries,
    layout_limit = layout_limit,
    hits = counters.hits,
    misses = counters.misses,
    writes = counters.writes,
    token_entries = package.loaded["markdown-table-wrap.markdown"]
        and require("markdown-table-wrap.markdown").cache_size()
      or 0,
  }
end

return M
