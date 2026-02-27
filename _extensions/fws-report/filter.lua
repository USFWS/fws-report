-- filter.lua
-- Produces:
--  - author-line: "Jane Biologist, Joe Botanist, ..."
--  - cite-author-line: "Biologist, J., J. Botanist, ..."
--  - header-includes LaTeX macros used by frontmatter.tex:
--      \TitleShort, \AuthorLine, \CiteAuthorLine, \ReportYear, \ReportNumber,
--      \FwsProgram, \FwsRegion, \FwsStation, \Location,
--      \CoverImage, \CoverImageCredit, \CoverCaption, \Doi
--      \FwsReportFontsPath, \FwsReportImagesPath
-- Also:
--  - Sets main font (Roboto Condensed family) + defines \RobotoBold
--  - Makes Markdown horizontal rules full text width in PDF

local stringify = pandoc.utils.stringify

-- ---------------- Path helpers ----------------

local function dirname(p)
  if not p or p == "" then return "" end
  p = p:gsub("\\", "/")
  p = p:gsub("/+$", "")
  return (p:gsub("/[^/]*$", ""))
end

local function self_dir()
  local src = debug.getinfo(1, "S").source or ""
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return dirname(src)
end

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

local function parse_author(name)
  name = (name or ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  local parts = {}
  for w in name:gmatch("%S+") do parts[#parts + 1] = w end
  if #parts == 0 then return { first_initial = "", last = "" } end
  local first = parts[1]
  local last  = parts[#parts]
  local initial = first:sub(1, 1)
  if initial ~= "" then initial = initial .. "." end
  return { first_initial = initial, last = last }
end

local function ensure_metalist(x)
  if not x then return pandoc.MetaList({}) end
  if x.t == "MetaList" then return x end
  return pandoc.MetaList({ x })
end

-- ---------------- Markdown HR override ----------------
-- Make Markdown horizontal rules (---) span full text width in PDF,
-- with extra space AFTER the line.
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
  return pandoc.RawBlock("latex",
    string.format("\\gdef\\%s{%s}", name, tex_escape(value or "")))
end

local function latex_gdef_detokenized(name, value)
  return pandoc.RawBlock("latex",
    string.format("\\gdef\\%s{\\detokenize{%s}}", name, value or ""))
end

local function latex_raw(s)
  return pandoc.RawBlock("latex", s)
end

-- ---------------- Main Meta filter ----------------

function Meta(meta)
  local hi = ensure_metalist(meta["header-includes"])
  local function get(key) return meta[key] and stringify(meta[key]) or "" end

  -- ---- compute extension-root-relative paths ----
  local extdir = self_dir():gsub("\\", "/")
  local fonts_path  = (extdir .. "/fonts/"):gsub("\\", "/")
  local images_path = (extdir .. "/images/"):gsub("\\", "/")

  -- Paths (portable)
  hi:insert(pandoc.MetaBlocks({ latex_gdef_detokenized("FwsReportFontsPath", fonts_path) }))
  hi:insert(pandoc.MetaBlocks({ latex_gdef_detokenized("FwsReportImagesPath", images_path) }))

  -- Fonts (Path resolved by Lua; no dependency on LaTeX macro ordering)
  local font_block = string.format([[
%% --- fws-report: set Roboto Condensed as the main font (Path resolved by Lua) ---
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

  hi:insert(pandoc.MetaBlocks({ latex_raw(font_block) }))

  -- Images
  local img_block = string.format([[
%% --- fws-report: portable image lookup (Path resolved by Lua) ---
\graphicspath{{%s}{./}}
]], images_path)
  hi:insert(pandoc.MetaBlocks({ latex_raw(img_block) }))

  -- Authors
  local a = meta["author"]
  local names = {}

  if a then
    if type(a) == "table" and a[1] then
      for _, v in ipairs(a) do names[#names + 1] = stringify(v) end
    else
      names[#names + 1] = stringify(a)
    end
  end

  local author_line = ""
  local cite_author_line = ""

  if #names > 0 then
    author_line = table.concat(names, ", ")

    local cite_parts = {}
    for i, nm in ipairs(names) do
      local p = parse_author(nm)
      if p.last ~= "" and p.first_initial ~= "" then
        if i == 1 then
          cite_parts[#cite_parts + 1] = string.format("%s, %s", p.last, p.first_initial)
        else
          cite_parts[#cite_parts + 1] = string.format("%s %s", p.first_initial, p.last)
        end
      else
        cite_parts[#cite_parts + 1] = nm
      end
    end
    cite_author_line = table.concat(cite_parts, ", ")
  end

  -- Defaults
  local fws_program = get("fws-program")
  if fws_program == "" then fws_program = "National Wildlife Refuge System" end

  local fws_region = get("fws-region")
  if fws_region == "" then fws_region = "Alaska" end

  -- Macros used by frontmatter.tex
  hi:insert(pandoc.MetaBlocks({ latex_gdef("TitleShort", get("title-short")) }))
  hi:insert(pandoc.MetaBlocks({ latex_gdef("AuthorLine", author_line) }))
  hi:insert(pandoc.MetaBlocks({ latex_gdef("CiteAuthorLine", cite_author_line) }))

  hi:insert(pandoc.MetaBlocks({ latex_gdef("ReportYear", get("year")) }))
  hi:insert(pandoc.MetaBlocks({ latex_gdef("ReportNumber", get("report-number")) }))

  hi:insert(pandoc.MetaBlocks({ latex_gdef("FwsProgram", fws_program) }))
  hi:insert(pandoc.MetaBlocks({ latex_gdef("FwsRegion", fws_region) }))
  hi:insert(pandoc.MetaBlocks({ latex_gdef("FwsStation", get("fws-station")) }))
  hi:insert(pandoc.MetaBlocks({ latex_gdef("Location", get("location")) }))

  hi:insert(pandoc.MetaBlocks({ latex_gdef("CoverImage", get("cover-image")) }))
  hi:insert(pandoc.MetaBlocks({ latex_gdef("CoverImageCredit", get("cover-image-credit")) }))
  hi:insert(pandoc.MetaBlocks({ latex_gdef("CoverCaption", get("cover-caption")) }))

  hi:insert(pandoc.MetaBlocks({ latex_gdef("Doi", get("doi")) }))

  meta["header-includes"] = hi
  return meta
end