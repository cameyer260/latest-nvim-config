# Local Markdown table Reader fork

This is a vendored, MIT-licensed fork of
[ice345/markdown-table-wrap.nvim](https://github.com/ice345/markdown-table-wrap.nvim),
based on **v0.9.0**, upstream commit
`02445d4c338fa0966f997d45b134d197b4605f5a`.
The original copyright/license, help, architecture documentation and regression
suite are retained. No separate Git repository or network dependency is needed.

## Loading and updates

`../../lua/custom/plugins/markdown.lua` adds this directory to Neovim's runtime
path, then configures the existing `markdown-table-wrap` API. It does **not** call
`vim.pack.add()` for the upstream table plugin. The commands, Source/Reader
buffer variables, mappings and source-write protections remain compatible with
the existing file-tree and Bufferline integrations.

Keep this directory in the Neovim configuration repository. `vim.pack.update()`
updates downloaded packages, **not this fork**, so it cannot overwrite these
changes. Restart Neovim after switching versions; live sessions retain already
loaded Lua modules.

The old downloaded copy is currently retained **inactive** for pre-existing
Neovim sessions that may lazily load more modules. After restarting **all** older
sessions, optionally remove it with
`:lua vim.pack.del({ 'markdown-table-wrap.nvim' })`. That also cleans its lockfile
entry so fresh installations do not download the unused copy. Do not remove it
while an older session still uses its runtime path.

Upstream upgrades are deliberate merges, not automatic updates: compare a new
upstream checkout with the recorded base commit, preserve the changes below,
and rerun the regression suite. Do not replace this directory wholesale or add
a second runtime copy of the same plugin.

## Local performance changes

- `wrap.lua`: carry the current line's text through fit checks instead of
  rebuilding its styling/source-span metadata for every character. Whole-string
  Neovim width measurements preserve Unicode/combining-character behavior.
- `cache.lua`: retain up to **three LRU layouts per table/source generation**.
  Full/narrow sidebar layouts coexist, while width, link policy, viewport and
  geometry settings remain part of the cache key. A new Source changedtick drops
  all old table IDs/stages; disable and buffer deletion release the cache.
  Public cache reads/writes still isolate values through deep copies.
- `reader.lua`: weakly cache overlay chunks for internal, read-only layout line
  objects. Public render results remain independently mutable; discarded layouts
  do not retain highlight caches forever.
- `reader.lua` / `init.lua`: resize-event refreshes skip unchanged text-area width
  and Source content. Explicit refresh, option/configuration changes, real width
  changes and Source edits still rebuild as before.

This retains the ordinary **left sidebar**, window-fitted wrapped tables, actual
Reader text for search/selection, and exact Source cell/edit/save behavior. It
is not a viewport-only renderer: a previously unseen width still constructs the
full document, and large first renders can still pause.

## Tests

From this directory:

```sh
nvim --headless -u NONE -n -i NONE \
  -c 'set rtp+=.' -c 'luafile tests/run.lua' -c 'qa!'
```

The upstream tests and `tests/spec/performance_spec.lua` cover wrapping, cache
bounds/invalidation/isolation, reusable overlay styling, resize no-ops, writes,
deletions, split ownership and Reader lifecycle. See [tests/README.md](tests/README.md)
for optional Python UI tests and [docs/performance.md](docs/performance.md) for
benchmarks. From the configuration root, run `python3 tests/markdown_reader_integration.py`
for the actual configured file-tree/tab-close mappings (requires `pynvim`).
