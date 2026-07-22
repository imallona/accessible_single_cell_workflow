-- Screen-reader-only "start/end" boundaries around executed code and output.
--
-- A nonvisual reader cannot see where a code cell stops and its result begins.
-- This filter announces those boundaries in the accessibility reading order
-- while keeping the visual layout unchanged.
--
-- What gets marked, decided from the real Quarto AST (not assumed):
--   executed source code = CodeBlock with class "cell-code"
--   computed output       = Div with class "cell-output" (stdout/stderr) or
--                           "cell-output-display" (kable tables, figures)
-- The output Div is wrapped as a whole, so both output shapes (a plain
-- CodeBlock and a df-print kable Table) are covered by one rule. Static,
-- non-executed ```r / ```bash snippets carry "r"/"bash" but not "cell-code"
-- and are left untouched.
--
-- Each writer hides the text its own way:
--   HTML  visually-hidden span (.sr-only in custom.scss), present in the a11y tree.
--   typst 0.1pt white text in a zero-height, clipped block. typst tags text as
--         it is drawn and has no separate accessibility tree, so the marker must
--         be drawn to enter the PDF reading order; it cannot be hidden the way
--         the HTML span is. 0.1pt white ink is visually imperceptible and the
--         zero-height clipped block adds no visible line. The block keeps its
--         default (weak) spacing rather than forcing it to zero: forcing zero
--         collapsed the gap between a cell output and the following paragraph,
--         making them bleed together. This is a known typst limitation, not a bug.

local function has_class(el, name)
  for _, c in ipairs(el.classes) do
    if c == name then return true end
  end
  return false
end

local function markers(label)
  local html_start = pandoc.RawBlock("html",
    '<span class="sr-only">start ' .. label .. '</span>')
  local html_end = pandoc.RawBlock("html",
    '<span class="sr-only">end ' .. label .. '</span>')
  local typst_start = pandoc.RawBlock("typst",
    '#block(height: 0pt, clip: true)[#text(size: 0.1pt, fill: white)[start ' .. label .. ']]')
  local typst_end = pandoc.RawBlock("typst",
    '#block(height: 0pt, clip: true)[#text(size: 0.1pt, fill: white)[end ' .. label .. ']]')
  return { html_start, typst_start }, { html_end, typst_end }
end

local function wrap(el, label)
  local before, after = markers(label)
  local out = {}
  for _, b in ipairs(before) do out[#out + 1] = b end
  out[#out + 1] = el
  for _, b in ipairs(after) do out[#out + 1] = b end
  return out
end

function CodeBlock(cb)
  if has_class(cb, "cell-code") then
    return wrap(cb, "code")
  end
end

function Div(div)
  if has_class(div, "cell-output") or has_class(div, "cell-output-display") then
    return wrap(div, "output")
  end
end
