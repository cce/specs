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

-- [H] keeps caption and body together but cannot break across pages: an
-- algorithm taller than one text page overflows the page bottom and gets
-- clipped. Warn well before that point so authors split at a semantic
-- boundary (see the Pseudocode section of CONTRIBUTIONS.md).
local MAX_ALGORITHM_LINES = 45

-- every command that produces a numbered line in algorithmicx
local LINE_COMMANDS = {
  "\\State", "\\If", "\\ElsIf", "\\Else", "\\EndIf",
  "\\For", "\\ForAll", "\\EndFor", "\\While", "\\EndWhile", "\\Repeat", "\\Until",
  "\\Function", "\\EndFunction", "\\Procedure", "\\EndProcedure",
  "\\Return", "\\Require", "\\Ensure",
}

local function count_lines(source)
  local total = 0
  for _, command in ipairs(LINE_COMMANDS) do
    for _ in source:gmatch(command .. "%f[%A]") do
      total = total + 1
    end
  end
  return total
end

local function latex_algorithm(source)
  local lines = count_lines(source)
  if lines > MAX_ALGORITHM_LINES then
    local caption = source:match("\\caption{([^}]*)}") or "<uncaptioned>"
    io.stderr:write(string.format(
      "[WARNING] pdf-pseudocode.lua: algorithm '%s' has %d numbered lines "
      .. "(max ~%d fits one PDF page); it will overflow and be clipped - "
      .. "split it at a function or semantic boundary.\n",
      caption, lines, MAX_ALGORITHM_LINES))
  end
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
