local latex_escapes = {
  ["\\"] = "\\textbackslash{}",
  ["{"] = "\\{",
  ["}"] = "\\}",
  ["$"] = "\\$",
  ["%"] = "\\%",
  ["&"] = "\\&",
  ["_"] = "\\_",
  ["#"] = "\\#",
  ["^"] = "\\^{}",
  ["~"] = "\\textasciitilde{}",
}

local function escaped_latex(text, separator)
  local characters = {}
  for character in text:gmatch(utf8.charpattern) do
    table.insert(characters, latex_escapes[character] or character)
  end

  return table.concat(characters, separator or "")
end

local function breakable_latex(text)
  return escaped_latex(text, "\\allowbreak{}")
end

-- TeX treats inline code as a single word. Add invisible break opportunities
-- only to long spans, including table identifiers and encoded values.
function Code(code)
  if not FORMAT:match("latex") or #code.text < 10 then
    return nil
  end

  return pandoc.RawInline(
    "latex",
    "\\texttt{" .. breakable_latex(code.text) .. "}"
  )
end

-- Verbatim environments cannot reliably wrap hashes and encoded values. Render
-- PDF code blocks as monospaced paragraphs with invisible break opportunities.
function CodeBlock(code)
  if not FORMAT:match("latex") then
    return nil
  end

  local lines = {}
  for line in (code.text .. "\n"):gmatch("(.-)\n") do
    if line == "" then
      table.insert(lines, "\\mbox{}\\par")
    else
      local text = breakable_latex(line)
      text = text:gsub(" ", "\\mbox{\\ }")
      text = text:gsub("\t", "\\mbox{\\ }\\mbox{\\ }\\mbox{\\ }\\mbox{\\ }")
      table.insert(lines, text .. "\\par")
    end
  end

  return pandoc.RawBlock(
    "latex",
    table.concat({
      "\\par\\smallskip",
      "\\begingroup",
      "\\small\\ttfamily\\raggedright",
      "\\setlength{\\parindent}{0pt}",
      "\\setlength{\\parskip}{0pt}",
      table.concat(lines, "\n"),
      "\\endgroup",
      "\\smallskip",
    }, "\n")
  )
end

local function has_text(text, fragment)
  return text:find(fragment, 1, true) ~= nil
end

local function column(align, width)
  return { align, width }
end

-- Markdown link destinations can distort Pandoc's inferred column widths even
-- though only their short labels are visible. Normalize the recurring tables.
--
-- Each rule below matches a table family by column count plus a header
-- fragment, so it applies book-wide, not to a single table:
--   5 columns, "Reference Implementation Name": the consensus parameter
--   tables in src/ledger/ledger-parameters.md;
--   4 columns, "Parameter Name": the node configuration tables in
--   src/node/non-normative/node-nn-appendix-b-*.md;
--   3 and 2 columns, "DESCRIPTION": the codec, parameter, and opcode table
--   families across src/ledger, src/abft, src/network, and src/_include/auto.
-- A new table matching one of these signatures silently inherits the widths;
-- adjust the header fragments here when that is not intended.
function Table(tbl)
  if not FORMAT:match("latex") then
    return nil
  end

  local header = pandoc.utils.stringify(tbl.head)
  local columns = #tbl.colspecs

  if columns == 5 and has_text(header, "Reference Implementation Name") then
    tbl.colspecs = {
      column(pandoc.AlignCenter, 0.13),
      column(pandoc.AlignCenter, 0.20),
      column(pandoc.AlignCenter, 0.08),
      column(pandoc.AlignLeft, 0.42),
      column(pandoc.AlignLeft, 0.17),
    }
  elseif columns == 4 and has_text(header, "Parameter Name") then
    tbl.colspecs = {
      column(pandoc.AlignLeft, 0.30),
      column(pandoc.AlignCenter, 0.30),
      column(pandoc.AlignCenter, 0.20),
      column(pandoc.AlignCenter, 0.20),
    }
  elseif columns == 3 and has_text(header, "DESCRIPTION") then
    tbl.colspecs = {
      column(pandoc.AlignLeft, 0.35),
      column(pandoc.AlignCenter, 0.18),
      column(pandoc.AlignLeft, 0.47),
    }
  elseif columns == 2 and has_text(header, "DESCRIPTION") then
    tbl.colspecs = {
      column(pandoc.AlignLeft, 0.35),
      column(pandoc.AlignLeft, 0.65),
    }
  end

  return tbl
end


-- Every table with five or more columns is set on its own landscape page,
-- keeping the immediately preceding heading (if any) on that page.
function Pandoc(document)
  if not FORMAT:match("latex") then
    return nil
  end

  local blocks = pandoc.List()
  local index = 1

  while index <= #document.blocks do
    local block = document.blocks[index]
    local following = document.blocks[index + 1]

    if block.t == "Header" and following and following.t == "Table"
        and #following.colspecs >= 5 then
      blocks:insert(pandoc.RawBlock("latex", "\\begin{landscape}"))
      blocks:insert(block)
      blocks:insert(following)
      blocks:insert(pandoc.RawBlock("latex", "\\end{landscape}"))
      index = index + 2
    elseif block.t == "Table" and #block.colspecs >= 5 then
      blocks:insert(pandoc.RawBlock("latex", "\\begin{landscape}"))
      blocks:insert(block)
      blocks:insert(pandoc.RawBlock("latex", "\\end{landscape}"))
      index = index + 1
    else
      blocks:insert(block)
      index = index + 1
    end
  end

  return pandoc.Pandoc(blocks, document.meta)
end
