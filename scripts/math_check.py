#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Report math blocks that Markdown inline parsing silently broke.

Scans the native AST emitted by mdbook-pandoc (see scripts/math-check.sh,
which builds it) for math delimiters that survived as plain text (Str)
instead of becoming Math nodes, and maps each one back to the source line
where the paragraph was split - i.e. exactly where a $$ block must end.

Usage: math_check.py NATIVES_DIR SRC_DIR
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

DELIMITER = re.compile(r"\$\$|\\\\\(|\\\\\[")


def str_strings(text: str):
    """Yield the contents of Str "..." tokens from mdbook-pandoc native AST.

    Only Str is prose subject to the MathJax emulation; strings preceded by
    ')' (Code/CodeBlock/RawInline attributes) or by Math tags are skipped.
    """
    i = 0
    while True:
        q = text.find('"', i)
        if q == -1:
            return
        before = text[:q].rstrip()
        j = q + 1
        out = []
        while j < len(text):
            ch = text[j]
            if ch == "\\" and j + 1 < len(text):
                out.append(text[j : j + 2])
                j += 2
                continue
            if ch == '"':
                break
            out.append(ch)
            j += 1
        i = j + 1
        if before.endswith("Str"):
            yield "".join(out)


def unescape(fragment: str) -> str:
    """Native-AST string escaping back to source text."""
    return fragment.replace('\\"', '"').replace("\\\\", "\\")


def find_line(lines: list[str], probe: str) -> int | None:
    probe = probe.strip()
    if not probe:
        return None
    for n, line in enumerate(lines, 1):
        if probe in line:
            return n
    return None


def check_file(native: Path, source: Path, rel: Path) -> str | None:
    hits = [s for s in str_strings(native.read_text())
            if "$$" in s or "\\\\(" in s or "\\\\[" in s]
    if not hits:
        return None
    lines = source.read_text().splitlines() if source.exists() else []

    hit = hits[0]
    # the delimiter that survived as text anchors the affected block/span ...
    m = DELIMITER.search(hit)
    around = unescape(hit[max(0, m.start() - 40) : m.end() + 20])
    probe = around.splitlines()[-1] if "\n" in around[:41] else around.splitlines()[0]
    anchor = find_line(lines, probe)
    # ... and the parsed text run ends exactly where inline parsing split it
    split_line = find_line(lines, unescape(hit.splitlines()[-1]))
    block_start = None
    ref = split_line or anchor
    if ref:
        for n in range(ref, 0, -1):
            if lines[n - 1].strip() == "$$":
                block_start = n
                break

    where = f"src/{rel}:{split_line or anchor or '?'}"
    return (
        f"{where}: math delimiters left unparsed by Markdown"
        + (f" (in the $$ block starting at line {block_start})" if block_start else "")
        + (f"; inline parsing splits the paragraph right after line {split_line}"
           if split_line else "")
        + ". Either a span is malformed (e.g. an unclosed \\\\( ... \\\\)), or two "
        "'_' pair as emphasis across lines: end the $$ block after that line "
        "(or move it last in the block)."
    )


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(f"usage: {sys.argv[0]} NATIVES_DIR SRC_DIR")
    natives = Path(sys.argv[1])
    src = Path(sys.argv[2])

    findings = []
    for native in sorted(natives.rglob("*.md")):
        rel = native.relative_to(natives)
        finding = check_file(native, src / rel, rel)
        if finding:
            findings.append(finding)

    if findings:
        print("\n".join(findings))
        sys.exit(f"math-check: {len(findings)} broken math block(s)")
    print("math-check: OK - all math blocks survive Markdown inline parsing")


if __name__ == "__main__":
    main()
