--[[
Render fenced ```pseudocode blocks natively with algorithm + algpseudocode.

The HTML build renders the same source with pseudocode.js (see
theme-ext/pseudocode-init.js); scripts/pdf-header.tex loads the LaTeX
packages. Must run before pdf-layout.lua so its generic CodeBlock handler
never sees these blocks.

Renderer alignment:
- `\begin{algorithmic}` gains `[1]` so every line is numbered, matching the
  HTML renderer's lineNumber option.
- `\begin{algorithm}` gains `[H]` (float package): the algorithm stays exactly
  where it is authored and the caption cannot be separated from the body.
- A line-leading `\Return` is wrapped in `\State`: pseudocode.js treats
  `\Return` as a full statement, algpseudocode expects it inside one.
]]

local function latex_algorithm(source)
  source = source:gsub("\\begin{algorithm}", "\\begin{algorithm}[H]", 1)
  source = source:gsub("\\begin{algorithmic}", "\\begin{algorithmic}[1]", 1)
  source = source:gsub("(\n%s*)\\Return", "%1\\State \\Return")
  return source
end

function CodeBlock(block)
  if not FORMAT:match("latex") then
    return nil
  end
  if not block.classes:includes("pseudocode") then
    return nil
  end
  return pandoc.RawBlock("latex", latex_algorithm(block.text))
end
