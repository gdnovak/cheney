#!/usr/bin/env python3
"""
Prompt helper for openclaw_router_repl.sh.

Behavior:
- Enter submits the full message.
- Ctrl+J inserts a newline into the current message.
- Multiline editing/history behaves like modern TUI chat inputs.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from prompt_toolkit import PromptSession
from prompt_toolkit.history import FileHistory
from prompt_toolkit.key_binding import KeyBindings
from prompt_toolkit.output import create_output


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="OpenClaw router REPL input helper")
    parser.add_argument("--prompt", default="router> ", help="Prompt prefix")
    parser.add_argument(
        "--history-file",
        required=True,
        help="Path to prompt history file",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    history_path = Path(args.history_file).expanduser()
    history_path.parent.mkdir(parents=True, exist_ok=True)
    if not history_path.exists():
        history_path.touch()

    kb = KeyBindings()

    @kb.add("enter")
    def _submit(event) -> None:
        event.current_buffer.validate_and_handle()

    @kb.add("c-j")
    def _insert_newline(event) -> None:
        event.current_buffer.insert_text("\n")

    session = PromptSession(
        multiline=True,
        prompt_continuation=lambda _width, _line_no, _soft_wrap: "... ",
        history=FileHistory(str(history_path)),
        key_bindings=kb,
        output=create_output(stdout=sys.stderr),
    )

    try:
        text = session.prompt(args.prompt)
    except EOFError:
        return 1
    except KeyboardInterrupt:
        return 130

    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
