#!/usr/bin/env python3
"""
Render a Codex prompt template with one or more argument files.

Usage:

  python scripts/render_codex_prompt.py \
    .codex/prompts/search-change-points.md \
    --feature .codex/features/applet-tool-call.md

  python scripts/render_codex_prompt.py \
    .codex/prompts/implement-slice.md \
    --feature .codex/features/applet-tool-call.md \
    --slice .codex/slices/applet-tool-call-01.md

Template placeholders:

  {{FEATURE}}
  {{SLICE}}
  {{PLAN}}
  {{ERROR}}
  {{DIFF}}

Any placeholder whose argument is not provided is left unchanged.
"""

from __future__ import annotations

import argparse
from pathlib import Path


PLACEHOLDERS = {
    "feature": "FEATURE",
    "slice": "SLICE",
    "plan": "PLAN",
    "error": "ERROR",
    "diff": "DIFF",
}


def read_text_file(path: str | None) -> str | None:
    if path is None:
        return None

    file_path = Path(path)

    if not file_path.exists():
        raise FileNotFoundError(f"File does not exist: {file_path}")

    if not file_path.is_file():
        raise ValueError(f"Path is not a file: {file_path}")

    return file_path.read_text(encoding="utf-8")


def render_template(template: str, values: dict[str, str | None]) -> str:
    rendered = template

    for arg_name, placeholder_name in PLACEHOLDERS.items():
        value = values.get(arg_name)

        if value is None:
            continue

        rendered = rendered.replace(f"{{{{{placeholder_name}}}}}", value.strip())

    return rendered


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Render a Codex prompt template with reusable argument files."
    )

    parser.add_argument(
        "template",
        help="Path to the prompt template file, e.g. .codex/prompts/search-change-points.md",
    )

    parser.add_argument(
        "--feature",
        help="Path to the feature definition file.",
    )

    parser.add_argument(
        "--slice",
        help="Path to the implementation slice file.",
    )

    parser.add_argument(
        "--plan",
        help="Path to an existing change plan file.",
    )

    parser.add_argument(
        "--error",
        help="Path to an error log or failing command output file.",
    )

    parser.add_argument(
        "--diff",
        help="Path to a git diff file.",
    )

    args = parser.parse_args()

    template_path = Path(args.template)

    if not template_path.exists():
        raise FileNotFoundError(f"Template does not exist: {template_path}")

    if not template_path.is_file():
        raise ValueError(f"Template path is not a file: {template_path}")

    template = template_path.read_text(encoding="utf-8")

    values = {
        "feature": read_text_file(args.feature),
        "slice": read_text_file(args.slice),
        "plan": read_text_file(args.plan),
        "error": read_text_file(args.error),
        "diff": read_text_file(args.diff),
    }

    print(render_template(template, values))


if __name__ == "__main__":
    main()