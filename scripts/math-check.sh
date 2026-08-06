#!/usr/bin/env bash
# Detect math blocks that Markdown inline parsing silently breaks, and point
# at the exact source line responsible.
#
# Background: mdBook's mathjax-support does not parse math. A $$ ... $$ block
# is ordinary Markdown text, so inline rules still apply to it: two
# underscores with punctuation on both sides (e.g. the `}_{` in
# `{\mathrm{TxTail}_{\max}}` paired with a later `_`) become *emphasis*,
# splitting the paragraph. The block then silently stops being math in both
# renderers, and the PDF fails with "Undefined control sequence" far from the
# cause. Where to split a definition block to avoid this is not guessable by
# eye - this check answers it.
#
# Mechanics: build a minimal copy of the book with the mdbook-pandoc "check"
# profile, then run scripts/math_check.py over the emitted native AST.
#
# Requires mdbook, mdbook-pandoc, and pandoc; `make docker-math-check` runs it
# via the release image instead. MATH_CHECK_PYTHON overrides the Python
# interpreter (the Makefile passes the uv-pinned one).
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
work_rel="tmp/math-check"
work="$repo/$work_rel"
mdbook_cmd="${MATH_CHECK_MDBOOK:-mdbook}"
python_cmd="${MATH_CHECK_PYTHON:-python3}"

if [ "$mdbook_cmd" = "mdbook" ]; then
    for tool in mdbook mdbook-pandoc pandoc; do
        command -v "$tool" >/dev/null 2>&1 || {
            echo "ERROR: '$tool' not found in PATH; install it or run 'make docker-math-check'." >&2
            exit 1
        }
    done
fi

cd "$repo"
rm -rf "$work"
mkdir -p "$work"
git ls-files -z -- src \
    | tar --null --files-from=- --create --file=- \
    | tar --extract --file=- --directory="$work"

# Minimal config: mathjax-support drives the MathJax emulation in
# mdbook-pandoc; the "check" profile writes plain text (no TeX, no filters).
cat > "$work/book.toml" <<'EOF'
[book]
title = "math-check"
src = "src"

[output.html]
mathjax-support = true

[output.pandoc.profile.check]
output-file = "check.txt"
EOF

$mdbook_cmd build "$work_rel" > /dev/null

$python_cmd scripts/math_check.py "$work_rel/book/pandoc/check/src" src
