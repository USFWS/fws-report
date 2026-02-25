-- filter.lua
-- Produces:
--  - author-line: "Jane Biologist, Joe Botanist, ..."
--  - cite-author-line: "Biologist, J., J. Botanist, ..."
--  - header-includes LaTeX macros used by frontmatter.tex:
--      \CoverTitle            (multiline, with \\ line breaks for cover)
--      \CoverTitleOneLine     (single line, explicit TeX spaces between lines)
--      \TitleShort, \AuthorLine, \CiteAuthorLine, \ReportYear, \ReportNumber,
--      \FwsProgram, \FwsRegion, \FwsStation, \Location,
--      \CoverImage, \CoverImageCredit, \CoverCaption, \Doi

local stringify = pandoc.utils.stringify

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

local function strip_pipe_prefix(line)
  line = line:gsub("^%s*", "")
  line = line:gsub("^|%s*", "")
  return line
end

local function lines_from_inlines(inls)
  local lines = { "" }
  for _, inl in ipairs(inls or {}) do
    if inl.t == "SoftBreak" or inl.t == "LineBreak" then
      table.insert(lines, "")
    else
      local s = stringify(inl)
      if s ~= "" then
        if lines[#lines] == "" then
          lines[#lines] = s
        else
          lines[#lines] = lines[#lines] .. " " .. s
        end
      end
    end
  end
  return lines
end

local function title_to_lines(mt)
  -- If MetaString comes through as Lua string (may contain \n)
  if type(mt) == "string" then
    local out = {}
    mt = mt:gsub("\r\n", "\n"):gsub("\r", "\n")
    for line in mt:gmatch("([^\n]*)\n?") do
      if line == "" and #out > 0 then break end
      out[#out + 1] = line
    end
    return out
  end

  if type(mt) == "table" then
    -- Pandoc MetaInlines is iterable; do NOT rely on .c
    if mt.t == "MetaInlines" then
      return lines_from_inlines(mt)
    end

    if mt.t == "MetaBlocks" then
      for _, blk in ipairs(mt.c or {}) do
        if blk.t == "Para" or blk.t == "Plain" then
          return lines_from_inlines(blk.c)
        end
      end
      return { stringify(mt) }
    end

    -- Sometimes meta.title arrives already as an Inlines list
    if mt[1] and mt[1].t then
      return lines_from_inlines(mt)
    end
  end

  return { stringify(mt) }
end

local function parse_author(name)
  name = (name or ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  local parts = {}
  for w in name:gmatch("%S+") do parts[#parts + 1] = w end
  if #parts == 0 then return { first_initial = "", last = "" } end
  local first = parts[1]
  local last  = parts[#parts]
  local initial = first:sub(1,1)
  if initial ~= "" then initial = initial .. "." end
  return { first_initial = initial, last = last }
end

local function ensure_metalist(x)
  if not x then return pandoc.MetaList({}) end
  if x.t == "MetaList" then return x end
  return pandoc.MetaList({ x })
end

local function latex_define(name, value)
  -- Escapes value (safe for most macros)
  return pandoc.RawBlock("latex",
    string.format("\\providecommand{\\%s}{%s}", name, tex_escape(value or "")))
end

local function latex_define_raw(name, value)
  -- ALWAYS override (prevents stale definitions from winning)
  return pandoc.RawBlock("latex",
    string.format("\\gdef\\%s{%s}", name, value or ""))
end

function Meta(meta)
  -- ---- authors ----
  local a = meta["author"]
  local names = {}

  if a then
    if type(a) == "table" and a[1] then
      for _, v in ipairs(a) do names[#names + 1] = stringify(v) end
    else
      names[#names + 1] = stringify(a)
    end
  end

  if #names > 0 then
    meta["author-line"] = table.concat(names, ", ")

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
    meta["cite-author-line"] = table.concat(cite_parts, ", ")
  end

-- ---- title for cover (multiline) + one-line version ----
local cover_title = ""
local cover_title_one_line = ""
if meta.title then
  local lines = title_to_lines(meta.title)
  local escaped_lines = {}
  for i = 1, #lines do
    local ln = strip_pipe_prefix(lines[i])
    escaped_lines[#escaped_lines + 1] = tex_escape(ln)
  end
  cover_title = table.concat(escaped_lines, "\\\\\n")
  cover_title_one_line = table.concat(escaped_lines, "\\space ")

  -- If we only got one "line" but it contains run-together boundaries, fix them.
  cover_title_one_line = cover_title_one_line
    :gsub("(%d)(%u)", "%1 %2")
    :gsub("(%l)(%u)", "%1 %2")
end

  -- ---- push LaTeX macros into header-includes ----
  local hi = ensure_metalist(meta["header-includes"])
  local function get(key) return meta[key] and stringify(meta[key]) or "" end

  -- defaults
  local fws_program = get("fws-program")
  if fws_program == "" then fws_program = "National Wildlife Refuge System" end

  local fws_region = get("fws-region")
  if fws_region == "" then fws_region = "Alaska" end

  hi:insert(pandoc.MetaBlocks({ latex_define_raw("CoverTitle", cover_title) }))
  hi:insert(pandoc.MetaBlocks({ latex_define_raw("CoverTitleOneLine", cover_title_one_line) }))

  hi:insert(pandoc.MetaBlocks({ latex_define("TitleShort", get("title-short")) }))
  hi:insert(pandoc.MetaBlocks({ latex_define("AuthorLine", meta["author-line"] and stringify(meta["author-line"]) or "") }))
  hi:insert(pandoc.MetaBlocks({ latex_define("CiteAuthorLine", meta["cite-author-line"] and stringify(meta["cite-author-line"]) or "") }))

  hi:insert(pandoc.MetaBlocks({ latex_define("ReportYear", get("year")) }))
  hi:insert(pandoc.MetaBlocks({ latex_define("ReportNumber", get("report-number")) }))
  hi:insert(pandoc.MetaBlocks({ latex_define("FwsProgram", fws_program) }))
  hi:insert(pandoc.MetaBlocks({ latex_define("FwsRegion", fws_region) }))
  hi:insert(pandoc.MetaBlocks({ latex_define("FwsStation", get("fws-station")) }))
  hi:insert(pandoc.MetaBlocks({ latex_define("Location", get("location")) }))

  hi:insert(pandoc.MetaBlocks({ latex_define("CoverImage", get("cover-image")) }))
  hi:insert(pandoc.MetaBlocks({ latex_define("CoverImageCredit", get("cover-image-credit")) }))
  hi:insert(pandoc.MetaBlocks({ latex_define("CoverCaption", get("cover-caption")) }))

  hi:insert(pandoc.MetaBlocks({ latex_define("Doi", get("doi")) }))

  meta["header-includes"] = hi
  return meta
end