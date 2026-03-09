-- lua/pdf.lua
-- PDF/LaTeX-specific filter for fws-report.

local script_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
local core = dofile(pandoc.path.join({ script_dir, "core.lua" }))

-- ---------------- Text helpers ----------------

local function tex_escape(s)
  s = s or ""
  s = s:gsub("\\", "\\textbackslash{}")
  s = s:gsub("%%", "\\%%")
  s = s:gsub("#", "\\#")
  s = s:gsub("&", "\\&")
  s = s:gsub("_", "\\_")
  s = s:gsub("{", "\\{")
  s = s:gsub("}", "\\}")
  return s
end

-- ---------------- Markdown HR override ----------------
-- Make Markdown horizontal rules (---) span full text width in PDF,
-- with extra space after the line.
function HorizontalRule(el)
  if FORMAT:match("latex") then
    return pandoc.RawBlock(
      "latex",
      "\\par\\noindent\\rule{\\linewidth}{0.6pt}\\par\\vspace{12pt}"
    )
  end
  return el
end

-- ---------------- LaTeX emitters ----------------

local function latex_gdef(name, value)
  return pandoc.RawBlock(
    "latex",
    string.format("\\gdef\\%s{%s}", name, tex_escape(value or ""))
  )
end

local function latex_raw(s)
  return pandoc.RawBlock("latex", s)
end

local function append_header_include(hi, block)
  hi:insert(pandoc.MetaBlocks({ block }))
end

-- ---------------- Main Meta filter ----------------

function Meta(meta)
  local hi = core.ensure_metalist(meta["header-includes"])
  local function get(key) return core.meta_string(meta, key) end

  local paths = core.extension_paths(script_dir)
  local fonts_path = paths.fonts_path
  local images_path = paths.images_path

  local font_block = string.format([[
%% --- fws-report: set Roboto Condensed as the main font (path resolved by Lua) ---
\setmainfont[
  Path=%s,
  UprightFont    = RobotoCondensed-Regular.ttf,
  ItalicFont     = RobotoCondensed-Italic.ttf,
  BoldFont       = RobotoCondensed-Bold.ttf,
  BoldItalicFont = RobotoCondensed-BoldItalic.ttf,
  FontFace = {ul}{n}{RobotoCondensed-Thin.ttf},
  FontFace = {ul}{it}{RobotoCondensed-ThinItalic.ttf},
  FontFace = {el}{n}{RobotoCondensed-ExtraLight.ttf},
  FontFace = {el}{it}{RobotoCondensed-ExtraLightItalic.ttf},
  FontFace = {l}{n}{RobotoCondensed-Light.ttf},
  FontFace = {l}{it}{RobotoCondensed-LightItalic.ttf},
  FontFace = {sb}{n}{RobotoCondensed-SemiBold.ttf},
  FontFace = {sb}{it}{RobotoCondensed-SemiBoldItalic.ttf},
  FontFace = {eb}{n}{RobotoCondensed-ExtraBold.ttf},
  FontFace = {eb}{it}{RobotoCondensed-ExtraBoldItalic.ttf},
  FontFace = {ub}{n}{RobotoCondensed-Black.ttf},
  FontFace = {ub}{it}{RobotoCondensed-BlackItalic.ttf}
]{}

%% Roboto Bold for # headings (expects Roboto-Bold.ttf in fonts/)
\newfontfamily\RobotoBold[
  Path=%s,
  UprightFont=Roboto-Bold.ttf
]{Roboto}
]], fonts_path, fonts_path)

  local img_block = string.format([[
%% --- fws-report: portable image lookup (path resolved by Lua) ---
\graphicspath{{%s}{./}}
]], images_path)

  append_header_include(hi, latex_raw(font_block))
  append_header_include(hi, latex_raw(img_block))

  local authors = core.authors(meta)
  local defaults = core.defaults(meta)

  append_header_include(hi, latex_gdef("TitleShort", get("title-short")))
  append_header_include(hi, latex_gdef("AuthorLine", authors.author_line))
  append_header_include(hi, latex_gdef("CiteAuthorLine", authors.cite_author_line))

  append_header_include(hi, latex_gdef("ReportYear", get("year")))
  append_header_include(hi, latex_gdef("ReportNumber", get("report-number")))

  append_header_include(hi, latex_gdef("FwsProgram", defaults.fws_program))
  append_header_include(hi, latex_gdef("FwsRegion", defaults.fws_region))
  append_header_include(hi, latex_gdef("FwsStation", get("fws-station")))
  append_header_include(hi, latex_gdef("Location", get("location")))

  append_header_include(hi, latex_gdef("CoverImage", get("cover-image")))
  append_header_include(hi, latex_gdef("CoverImageCredit", get("cover-image-credit")))
  append_header_include(hi, latex_gdef("CoverCaption", get("cover-caption")))

  append_header_include(hi, latex_gdef("Doi", get("doi")))

  meta["header-includes"] = hi
  return meta
end
