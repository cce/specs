# Contribution Guidelines {.noexport}

The source of the Algorand Specification is released on the official GitHub Algorand
Foundation [repository](https://github.com/algorandfoundation/specs).

If you would like to contribute, please consider submitting an [issue](https://github.com/algorandfoundation/specs/issues/new/choose)
or opening a [pull request](https://github.com/algorandfoundation/specs/pulls).

## Typos

To fix typos, consider opening a pull request labeled _"typo"_. By clicking on the
_“Suggest an edit”_ icon in the top-right corner of the page containing the typo,
you will be redirected to the relevant source code file to be edited in the pull
request.

## Issues

To report major issues, such as unclear contents, errors in mathematical formulas,
broken rendering of the Web version or PDF version, broken rendering of diagrams,
broken links, etc. please consider submitting a [templated issue](https://github.com/algorandfoundation/specs/issues/new/choose).

## Source Code

The Algorand Specifications book is built with [mdBook](https://rust-lang.github.io/mdBook/index.html).

The source code is structured as follows:

```text
src/                      -> mdBook source code
└── _include/             -> Code snippets, templates, TeX-macros, auto-generated files, and examples
└── _excalidraw/          -> Excalidraw diagrams source code
└── _images/              -> SVG files
└── Part_A/               -> Part A normative files
    └── non-normative/    -> Part A non-normative files
└── Part_B/               -> Part B files
└── Part.../              -> ...
└── SUMMARY.md, ...       -> mdBook SUMMARY.md, COVER.md, prefix/suffix-chapters, etc.
```

## Markdown

The book is written in [CommonMark](https://commonmark.org/).

The CI pipeline enforces Markdown linting, formatting, and style checking with
[`rumdl`](https://github.com/rvben/rumdl).

### Numbered Lists

Numbered lists **MUST** be defined with `1`-only style.

> [!TIP]
> **EXAMPLE:**
>
> ```text
> 1. First item
> 1. Second item
> 1. Third item
> ```
>
> Result:
>
> 1. First item
> 1. Second item
> 1. Third item

### Tables

Table rows **MUST** use the same column widths.

> [!TIP]
> **EXAMPLE:**
>
> **Correct table format:**
>
> ```text
> | Month    | Savings |
> |----------|---------|
> | January  | €250    |
> | February | €80     |
> | March    | €420    |
> ```
>
> **Incorrect table format:**
>
> ```text
> | Month | Savings |
> |----------|---------|
> | January | €250 |
> | February | €80 |
> | March | €420 |
> ```
>
> Result:
>
> | Month    | Savings |
> | -------- | ------- |
> | January  | €250    |
> | February | €80     |
> | March    | €420    |

Consider aligning text in the columns to the left, right, or center by adding a
colon `:` to the left, right, or on both sides of the dashes `---` within the header
row.

> [!TIP]
> **EXAMPLE:**
>
> ```text
> | Name   | Quantity | Size |
> |:-------|:--------:|-----:|
> | Item A |    1     |    S |
> | Item B |    5     |    M |
> | Item C |    10    |   XL |
> ```
>
> Result:
>
> | Name   | Quantity | Size |
> | :----- | :------: | ---: |
> | Item A |    1     |    S |
> | Item B |    5     |    M |
> | Item C |    10    |   XL |

## MathJax

Mathematical formulas are defined with [MathJax](https://www.mathjax.org/).

> [!NOTE]
> mdBook MathJax [documentation](https://rust-lang.github.io/mdBook/format/mathjax.html).

> [!IMPORTANT]
> When you use double backslashes in MathJax blocks (for example in commands such
> as `\begin{cases} \frac 1 2 \\ \frac 3 4 \end{cases}`) you need to add two extra
> backslashes (e.g., `\begin{cases} \frac 1 2 \\\\ \frac 3 4 \end{cases}`).

### Inline Equations

Inline equations **MUST** include extra spaces in the MathJax delimiters.

> [!TIP]
> **EXAMPLE:**
>
> Equation: \\( \int x dx = \frac{x^2}{2} + C \\)
>
> **Correct inline delimiter:**
>
> ```text
> \\( \int x dx = \frac{x^2}{2} + C \\)
> ```
>
> **Incorrect inline delimiter:**
>
> ```text
> \\(\int x dx = \frac{x^2}{2} + C\\)
> ```

### Block Equations

Block equations **MUST** use the `$$` delimiter (instead of `\\[ ... \\]`).

> [!TIP]
> **EXAMPLE:**
>
> Equation:
>
> $$
> \mu = \frac{1}{N} \sum_{i=0} x_i
> $$
>
> **Correct block delimiter:**
>
> ```text
> $$
> \mu = \frac{1}{N} \sum_{i=0} x_i
> $$
> ```
>
> **Incorrect block delimiter:**
>
> ```text
> \\[
> \mu = \frac{1}{N} \sum_{i=0} x_i
> \\]
> ```

For readability, long equations **SHOULD** be wrapped at natural operators with
continuation lines indented.

### TeX-Macros

TeX-macros are defined per page, in a `$$ ... $$` block of `\newcommand`
definitions at the top of the file (before the first heading). Macros are
page-scoped in the Web version, so each page **MUST** define every macro it
uses, before the first usage.

Macros shared by several pages (e.g., domain separators) live in the
`./src/_include/tex-macros/` folder and are imported at the top of the consumer
files using the mdBook [include feature](https://rust-lang.github.io/mdBook/format/mdbook.html#including-files).

The same macro name **MUST** have the same definition on every page that
defines it, so notation stays consistent across the book (in the PDF version,
definitions are document-wide and the last redefinition wins).

Avoid macro names that collide with LaTeX kernel or common-package commands
(e.g., accent commands such as `\t`, `\b`, `\r`, `\c`): they break the PDF
build or silently change output.

After adding or editing math — definition blocks in particular — run
`make math-check` (or `make docker-math-check`): Markdown inline parsing can
silently break a `$$ ... $$` block (e.g., two `_` that pair as emphasis across
lines) or reveal a malformed `\\( ... \\)` span, and the check pinpoints the
exact line where the block must be split.

> [!TIP]
> **EXAMPLE:**
>
> Page-local definitions:
>
> ```text
> $$
> \newcommand \TxTail {\mathrm{TxTail}}
> \newcommand \floor[1] {\left \lfloor #1 \right \rfloor}
> $$
> ```
>
> Import shared macros (e.g., domain separators):
>
> ```text
> \{{#include ./_include/tex-macros/domain-separators.md}}
> ```

## Pseudocode

Algorithms are written in fenced `pseudocode` code blocks containing LaTeX
`algorithmic` markup. The Web version renders them with [pseudocode.js](https://github.com/SaswatPadhi/pseudocode.js)
(vendored in `theme-ext/`); the PDF version renders the same source natively with
the `algorithm` and `algpseudocode` packages (via `scripts/pdf-pseudocode.lua`).

Pseudocode blocks **MUST** only use the command subset supported by both renderers:

- `\begin{algorithm}`, `\caption{...}`, `\begin{algorithmic}` (and the matching ends)
- `\Function{Name}{$args$}` / `\EndFunction`, `\Procedure` / `\EndProcedure`
- `\If{$cond$}` / `\ElsIf{$cond$}` / `\Else` / `\EndIf`
- `\While{$cond$}` / `\EndWhile`, `\For{$spec$}` / `\ForAll{$spec$}` / `\EndFor`,
  `\Repeat` / `\Until{$cond$}`
- `\State`, `\Return`, `\Comment{...}`, `\Call{Name}{$args$}`, `\Require`, `\Ensure`
- Text-style commands in open text (`\texttt{...}`, `\textbf{...}`, `\textit{...}`, etc.)

Conventions:

- Captions **MUST NOT** contain numbering ("Algorithm N"). Reference
  algorithms by their caption title, which **MUST** be unique across the book.
- Lines are numbered automatically; **do not** write manual line numbers.
- `\Return` is used bare (not wrapped in `\State`) and **MUST** start its own
  line; the PDF filter adds the wrapper LaTeX needs, but only rewrites
  line-leading occurrences.
- Algorithms **MUST** fit on one PDF page (roughly 45 numbered lines): larger
  ones overflow the page and get clipped. Split them at a function or semantic
  boundary; the PDF build emits a warning past this size.
- Mathematical notation inside statements uses `$...$` delimiters; all
  [TeX-macros](#tex-macros) are available inside.
- Function names in `\Function`/`\Call` are plain text, not macros.

> [!TIP]
> **EXAMPLE:**
>
> ````markdown
> ```pseudocode
> \begin{algorithm}
> \caption{Example Algorithm}
> \begin{algorithmic}
> \Function{Ingest}{$\TG\ gtx$}
>   \If{$\lnot \BlockEval$}
>     \Return \Comment{No pending Block Evaluator exists}
>   \EndIf
>   \State $\TP \gets \BlockEval.\mathrm{add}(gtx)$
> \EndFunction
> \end{algorithmic}
> \end{algorithm}
> ```
> ````

## Admonitions

Admonitions **MUST** use mdBook's native Markdown syntax. Use `NOTE` for non-normative
comments, `TIP` with an `EXAMPLE` label for examples, and `IMPORTANT` with an `IMPLEMENTATION`
label for reference implementation details.

```text
> [!NOTE]
> This is a non-normative comment.
```

```text
> [!TIP]
> **EXAMPLE:**
>
> This is an example.
```

```text
> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> This describes the reference implementation.
```

## GitHub Links

Links to the `go-algorand` reference implementation or other repositories **MUST**
be [permalinks](https://docs.github.com/en/repositories/working-with-files/using-files/getting-permanent-links-to-files).

## Diagrams

### Structured Diagrams

Structured diagrams (e.g., flow charts, sequence diagrams, etc.) are defined with
[Mermaid](https://mermaid.js.org/intro/) “text-to-diagram” tool.

### Unstructured Diagrams

Unstructured diagrams and images are drawn with [Excalidraw](https://excalidraw.com/).

Excalidraw images **MUST** be exported in `.svg` format without a background and
saved in the `./src/_images/` folder.

Excalidraw images source code **MUST** be committed in the `./src/_excalidraw/`
folder.

## Prepare and Submit a Change

Repository setup, local preview, validation commands, and pull-request preview
behavior are maintained in the [repository README](https://github.com/algorandfoundation/specs#repository-setup).
Follow those instructions before submitting a pull request.

Keep each pull request focused and explain the scope and motivation in its description.
When a change affects rendering, inspect its deployment preview. External-contribution
previews are triggered by maintainers on request.
