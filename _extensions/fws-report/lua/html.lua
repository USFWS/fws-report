-- lua/html.lua
-- HTML filter for fws-report: prepends a styled cover/header for screen-first HTML.
-- Reuses shared author/default logic from core.lua so HTML matches PDF/DOCX.

local stringify = pandoc.utils.stringify
local path = pandoc.path

local script_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
local core = dofile(pandoc.path.join({ script_dir, "core.lua" }))
local trim = core.trim

local function html_escape(s)
  s = tostring(s or "")
  s = s:gsub("&", "&amp;")
  s = s:gsub("<", "&lt;")
  s = s:gsub(">", "&gt;")
  s = s:gsub('"', "&quot;")
  return s
end

local function file_exists(p)
  if not p or p == "" then
    return false
  end
  local f = io.open(p, "rb")
  if f then
    f:close()
    return true
  end
  return false
end

local function get(meta, key)
  return core.meta_string(meta, key)
end

local function split_plain_text_lines(text)
  local items = {}
  text = tostring(text or "")
  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
  for part in text:gmatch("[^\n]+") do
    local clean = trim(part)
    if clean ~= "" then
      table.insert(items, clean)
    end
  end
  return items
end

local function split_inlines_on_breaks(inlines)
  local lines = {}
  local current = pandoc.List({})

  local function flush()
    if #current > 0 then
      local text = trim(stringify(current))
      if text ~= "" then
        table.insert(lines, text)
      end
      current = pandoc.List({})
    end
  end

  for _, item in ipairs(inlines or {}) do
    if item.t == "SoftBreak" or item.t == "LineBreak" then
      flush()
    else
      current:insert(item)
    end
  end

  flush()
  return lines
end

local function title_lines(meta)
  local value = meta.title
  if value == nil then
    return {}
  end

  if value.t == "MetaInlines" and value.c then
    local lines = split_inlines_on_breaks(value.c)
    if #lines > 0 then
      return lines
    end
  end

  if value.t == "MetaBlocks" and value.c then
    local lines = {}
    for _, block in ipairs(value.c) do
      if (block.t == "Para" or block.t == "Plain") and block.c then
        for _, line in ipairs(split_inlines_on_breaks(block.c)) do
          table.insert(lines, line)
        end
      else
        local text = trim(stringify(block))
        if text ~= "" then
          table.insert(lines, text)
        end
      end
    end
    if #lines > 0 then
      return lines
    end
  end

  local text = get(meta, "title")
  if text == "" then
    return {}
  end
  return split_plain_text_lines(text)
end

local function one_line_title(meta)
  return trim(table.concat(title_lines(meta), " "))
end

local function first_nonempty(...)
  for i = 1, select("#", ...) do
    local value = trim(select(i, ...))
    if value ~= "" then
      return value
    end
  end
  return ""
end

local function default_logo_path()
  local paths = core.extension_paths(script_dir)
  local images_path = paths.images_path

  local candidates = {
    path.join({ images_path, "fws_logo.svg" }),
    path.join({ images_path, "fws_logo.png" }),
    path.join({ images_path, "fws-logo.svg" }),
    path.join({ images_path, "fws-logo.png" }),
    "_extensions/fws-report/images/fws_logo.svg",
    "_extensions/fws-report/images/fws_logo.png",
    "_extensions/fws-report/images/fws-logo.svg",
    "_extensions/fws-report/images/fws-logo.png"
  }

  for _, p in ipairs(candidates) do
    if file_exists(p) then
      return p
    end
  end

  return ""
end

local function resolve_logo(meta)
  return first_nonempty(
    get(meta, "fws-logo"),
    get(meta, "fws_logo"),
    get(meta, "logo"),
    get(meta, "logo-image"),
    get(meta, "logo_image"),
    default_logo_path()
  )
end

local function author_line_text(meta)
  local authors = core.authors(meta)
  return authors.author_line or ""
end

local function add_font_dependency()
  quarto.doc.add_html_dependency({
    name = "fws-report-fonts",
    version = "1.0.0",
    stylesheets = { "../css/fws-fonts.css" }
  })

  quarto.doc.attach_to_dependency("fws-report-fonts", {
    path = "../fonts/RobotoCondensed-Regular.ttf",
    name = "RobotoCondensed-Regular.ttf"
  })

  quarto.doc.attach_to_dependency("fws-report-fonts", {
    path = "../fonts/RobotoCondensed-Italic.ttf",
    name = "RobotoCondensed-Italic.ttf"
  })

  quarto.doc.attach_to_dependency("fws-report-fonts", {
    path = "../fonts/RobotoCondensed-Bold.ttf",
    name = "RobotoCondensed-Bold.ttf"
  })

  quarto.doc.attach_to_dependency("fws-report-fonts", {
    path = "../fonts/RobotoCondensed-BoldItalic.ttf",
    name = "RobotoCondensed-BoldItalic.ttf"
  })

  quarto.doc.attach_to_dependency("fws-report-fonts", {
    path = "../fonts/Roboto-Bold.ttf",
    name = "Roboto-Bold.ttf"
  })
end

local function render_cover(meta)
  local defaults = core.defaults(meta)

  local service_name = first_nonempty(get(meta, "service-name"), "U.S. Fish and Wildlife Service")
  local department_name = first_nonempty(get(meta, "department-name"), "U.S. Department of the Interior")
  local fws_program = get(meta, "fws-program")
  if fws_program == "" then fws_program = defaults.fws_program end

  local fws_station = get(meta, "fws-station")
  local fws_region = get(meta, "fws-region")
  if fws_region == "" then fws_region = defaults.fws_region end

  local report_number = get(meta, "report-number")
  local year = get(meta, "year")
  local logo = resolve_logo(meta)
  local cover_image = get(meta, "cover-image")
  local cover_alt = first_nonempty(get(meta, "cover-image-alt"), one_line_title(meta))
  local cover_caption = first_nonempty(get(meta, "cover-caption"), get(meta, "cover-image-caption"))
  local title = title_lines(meta)
  local author_line = author_line_text(meta)

  local eyebrow_text = ""
  if fws_station ~= "" and year ~= "" and report_number ~= "" then
    eyebrow_text = fws_station .. " Report # " .. year .. "-" .. report_number
  elseif fws_station ~= "" and year ~= "" then
    eyebrow_text = fws_station .. " Report # " .. year
  elseif fws_station ~= "" and report_number ~= "" then
    eyebrow_text = fws_station .. " Report # " .. report_number
  else
    eyebrow_text = fws_station
  end

  local title_html = {}
  for _, line in ipairs(title) do
    table.insert(title_html, '<span class="fws-title-line">' .. html_escape(line) .. '</span>')
  end

  local masthead_text = {}
  table.insert(masthead_text, '<div class="fws-program">' .. html_escape(service_name) .. '</div>')

  if department_name ~= "" then
    table.insert(masthead_text, '<div class="fws-program">' .. html_escape(department_name) .. '</div>')
  end

  local program_region = ""
  if fws_program ~= "" and fws_region ~= "" then
    program_region = fws_program .. " – " .. fws_region
  elseif fws_program ~= "" then
    program_region = fws_program
  elseif fws_region ~= "" then
    program_region = fws_region
  end

  if program_region ~= "" then
    table.insert(masthead_text, '<div class="fws-program fws-program-gap">' .. html_escape(program_region) .. '</div>')
  end

  local logo_html = ""
  if logo ~= "" then
    logo_html = '<div class="fws-brand-logo"><img src="' .. html_escape(logo) .. '" alt="U.S. Fish and Wildlife Service logo"></div>'
  end

  local cover_image_html = ""
  if cover_image ~= "" then
    local caption_html = ""
    if cover_caption ~= "" then
      caption_html = table.concat({
        '<figcaption>',
        '<p>' .. html_escape(cover_caption) .. '</p>',
        '</figcaption>'
      })
    end

    cover_image_html = table.concat({
      '<figure class="fws-cover-figure">',
      '<img src="' .. html_escape(cover_image) .. '" alt="' .. html_escape(cover_alt) .. '">',
      caption_html,
      '</figure>'
    })
  end

  return table.concat({
    '<section class="fws-cover" aria-labelledby="fws-report-title">',
    '<div class="fws-masthead">',
    '<div class="fws-brand-text">' .. table.concat(masthead_text) .. '</div>',
    logo_html,
    '</div>',
    '<div class="fws-cover-body">',
    (eyebrow_text ~= "") and ('<div class="fws-eyebrow">' .. html_escape(eyebrow_text) .. '</div>') or '',
    '<h1 id="fws-report-title" class="fws-title">' .. table.concat(title_html) .. '</h1>',
    (author_line ~= "") and ('<div class="fws-author-line">' .. html_escape(author_line) .. '</div>') or '',
    '<div class="fws-cover-grid">',
    cover_image_html,
    '</div>',
    '</div>',
    '</section>'
  })
end

return {
  {
    Meta = function(meta)
      if not quarto.doc.is_format("html") then
        return meta
      end

      add_font_dependency()
      meta["title-block-style"] = pandoc.MetaString("none")
      return meta
    end,

    Pandoc = function(doc)
      if not quarto.doc.is_format("html") then
        return doc
      end

      local cover = pandoc.RawBlock("html", render_cover(doc.meta))
      local page_title = one_line_title(doc.meta)

      if page_title ~= "" then
        doc.meta.pagetitle = pandoc.MetaString(page_title)
      end

      doc.meta["title-block-style"] = pandoc.MetaString("none")
      doc.blocks:insert(1, cover)
      return doc
    end
  }
}