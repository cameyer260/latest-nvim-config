"""Exercise the actual configured Reader/tree/close mappings in a disposable UI.

Run from the configuration root: python3 tests/markdown_reader_integration.py
Requires pynvim and the configuration's downloaded dependencies to be installed.
"""
from pathlib import Path
import tempfile
import time

import pynvim

CONFIG = Path(__file__).resolve().parents[1]


def settle(nvim):
    # Let resize/render callbacks complete between synthetic user actions.
    time.sleep(0.2)
    nvim.exec_lua("return true")
    time.sleep(0.1)
    nvim.exec_lua("return true")


def press(nvim, keys):
    nvim.input(keys)
    settle(nvim)


def assert_closed(nvim, source, readers):
    settle(nvim)
    assert nvim.exec_lua(
        "return not vim.bo[...].buflisted and not vim.api.nvim_buf_is_loaded(...)", source
    ), "backing Source stayed open"
    for reader in readers:
        assert nvim.exec_lua("return not vim.api.nvim_buf_is_valid(...)", reader), "Reader stayed open"


def run():
    with tempfile.TemporaryDirectory(prefix="nvim-reader-integration-") as tmp:
        root = Path(tmp)
        table = root / "wrapped table.md"
        ordinary = root / "ordinary.txt"
        table.write_text(
            "# Fixture\n\n| Name | Detail |\n| --- | --- |\n"
            "| [docs](docs.md) | **bold** and a long cell that wraps at sidebar width |\n",
            encoding="utf-8",
        )
        ordinary.write_text("Ordinary buffer.\n", encoding="utf-8")
        n = pynvim.attach("child", argv=["nvim", "--embed", "--headless", "-n", "-i", "NONE", "-u", str(CONFIG / "init.lua")])
        try:
            n.ui_attach(200, 65, rgb=True, ext_linegrid=True)
            n.command("cd " + n.funcs.fnameescape(str(root)))
            module_path = n.exec_lua("return debug.getinfo(require('markdown-table-wrap').setup, 'S').source")
            assert module_path.startswith("@" + str(CONFIG / "vendor")), "downloaded plugin loaded instead of the fork"
            assert n.exec_lua("return vim.g.loaded_markdown_table_wrap == 1"), "plugin bootstrap did not run"
            assert n.exec_lua("for _, p in ipairs(vim.pack.get()) do if p.spec.name == 'markdown-table-wrap.nvim' and p.active then return false end end; return true"), "upstream plugin is still active in vim.pack"

            n.command("edit " + n.funcs.fnameescape(str(ordinary)))
            settle(n)

            def open_reader():
                n.command("edit " + n.funcs.fnameescape(str(table)))
                assert n.exec_lua("return vim.wait(3000, function() return vim.b[0].markdown_table_wrap_reader == true end, 20)"), "automatic Reader did not open"
                settle(n)
                return n.exec_lua("return vim.b[0].markdown_table_wrap_source"), n.current.buffer.number, n.current.window.handle

            source, view, win = open_reader()
            before = table.read_bytes()
            for key in (" e", " o"):
                press(n, key)
                assert n.exec_lua("return vim.bo.filetype == 'neo-tree'"), "explorer was not focused"
                state = n.exec_lua("local s = require('neo-tree.sources.manager').get_state('filesystem'); return {path = s.tree:get_node():get_id(), position = s.current_position or s.window.position}")
                assert state["path"] == str(table), "explorer did not reveal the backing file"
                assert state["position"] == "left", "explorer became floating"
                assert n.api.win_get_buf(win).number == view, "explorer replaced Reader"
                press(n, " e")
                assert n.current.buffer.number == view, "tree close did not return to Reader"
            assert table.read_bytes() == before, "rendering changed the file"
            print("PASS: local fork loaded; Space e/o reveal Source in the left sidebar and preserve Reader")

            press(n, " bd")
            assert_closed(n, source, [view])
            assert n.api.win_is_valid(win), "close removed the document window"
            print("PASS: Space bd closes the logical document without reopening Reader")

            source, view, win = open_reader()
            press(n, " me")
            assert n.current.buffer.number == source, "edit mapping did not enter Source"
            press(n, " bd")
            assert_closed(n, source, [view])
            print("PASS: Source-mode close behaves the same")

            source, first_view, first_win = open_reader()
            n.command("vsplit")
            second_win = n.current.window.handle
            n.api.set_current_buf(source)
            second_view = n.exec_lua("return require('markdown-table-wrap').reader_preview()")
            settle(n)
            assert second_view != first_view, "two windows shared one Reader"
            press(n, " bd")
            assert_closed(n, source, [first_view, second_view])
            assert n.api.win_is_valid(first_win) and n.api.win_is_valid(second_win), "close destroyed splits"
            n.api.win_close(second_win, True)
            n.api.set_current_win(first_win)
            print("PASS: closing shared Source disposes both Readers and preserves splits")

            for handler in ("handle_close", "right_click"):
                source, view, win = open_reader()
                if handler == "handle_close":
                    n.exec_lua("___bufferline_private.handle_close(...)", source)
                else:
                    n.exec_lua("___bufferline_private.handle_click(..., 1, 'r')", source)
                assert_closed(n, source, [view])
            print("PASS: Bufferline close icon and right-click close Source plus Reader")

            source, view, win = open_reader()
            n.api.buf_set_lines(source, 4, 5, False, ["| unsaved | protected edit |"])
            confirm = n.options["confirm"]
            n.options["confirm"] = False  # Deterministic refusal instead of an interactive save prompt.
            result = n.exec_lua("local ok, err = pcall(vim.fn.maparg(' bd', 'n', false, true).callback); return {ok, tostring(err)}")
            assert not result[0] and "E89" in result[1], "unsaved Source was discarded"
            settle(n)
            assert n.current.buffer.number == view and n.api.buf_is_loaded(source), "refused close destroyed Reader/Source"
            assert table.read_bytes() == before, "refused close wrote the file"
            n.options["confirm"] = confirm
            n.command("write")
            press(n, " bd")
            assert_closed(n, source, [view])
            assert b"protected edit" in table.read_bytes(), "saved Source edits were lost"
            print("PASS: unsaved Source protected; save from Reader then close succeeds")
            print("ALL CONFIGURED READER INTEGRATION TESTS PASSED")
        finally:
            try:
                n.command("qa!")
            except (EOFError, OSError):
                pass
            n.close()


if __name__ == "__main__":
    run()
