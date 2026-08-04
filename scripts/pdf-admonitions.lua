-- mdBook admonitions (GitHub-style alerts) reach Pandoc as plain Divs:
--   Div (classes=[<type>]) [Div (classes=[title]) [Para <title>], <body>...]
-- The LaTeX writer renders those without any styling. Turn them into the
-- `callout` environments defined in scripts/pdf-header.tex.

local callout_types = {
  note      = true,
  tip       = true,
  important = true,
  warning   = true,
  caution   = true,
}

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

local function escaped_latex (text)
  return (text:gsub("[\\{}$%%&_#%^~]", latex_escapes))
end

function Div (div)
  if not FORMAT:match("latex") then
    return nil
  end

  local kind = div.classes[1]
  if not callout_types[kind] then
    return nil
  end

  local blocks = div.content
  local title = kind:gsub("^%l", string.upper)
  local first = blocks[1]
  if first and first.t == "Div" and first.classes:includes("title") then
    title = pandoc.utils.stringify(first)
    blocks:remove(1)
  end

  local result = pandoc.List()
  result:insert(pandoc.RawBlock(
    "latex",
    "\\begin{callout}{callout" .. kind .. "}{" .. escaped_latex(title) .. "}"
  ))
  result:extend(blocks)
  result:insert(pandoc.RawBlock("latex", "\\end{callout}"))
  return result
end
