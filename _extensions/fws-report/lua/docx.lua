-- lua/docx.lua
-- DOCX filter for fws-report: prepends a styled cover and inside-cover page.
-- The banner is a 2-column table built with pandoc.utils.from_simple_table.

local script_dir = pandoc.path.directory(PANDOC_SCRIPT_FILE)
local core = dofile(pandoc.path.join({ script_dir, "core.lua" }))

local paths = core.extension_paths(script_dir)
local images_path = paths.images_path

local stringify = pandoc.utils.stringify
local trim = core.trim

local function get(meta, key)
  return core.meta_string(meta, key)
end

local function set_custom_style(el, style_name)
  local a = el.attr or pandoc.Attr("", {}, {})
  local attrs = {}
  if a.attributes then
    for k, v in pairs(a.attributes) do attrs[k] = v end
  end
  attrs["custom-style"] = style_name
  el.attr = pandoc.Attr(a.identifier or "", a.classes or {}, attrs)
  return el
end

-- Paragraph style via custom-style (paragraph style in Word)
local function pstyle(text, style_name)
  return set_custom_style(
    pandoc.Div({ pandoc.Para({ pandoc.Str(text) }) }),
    style_name
  )
end

-- Character style via custom-style (character style in Word)
local function cstyle(text, style_name)
  return set_custom_style(pandoc.Span({ pandoc.Str(text) }), style_name)
end

local function page_break()
  return pandoc.RawBlock("openxml", '<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
end

-- XML escape for OpenXML raw blocks
local function xml_escape(s)
  s = tostring(s or "")
  s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
  return s
end

-- OpenXML paragraph with optional formatting.
-- opts:
--   pstyle: paragraph style name (w:pStyle)
--   bold: boolean (wraps run with w:b)
--   left_twips: left indent (w:ind@w:left)
--   hanging_twips: hanging indent (w:ind@w:hanging)
--   space_before: twips
--   space_after: twips
local function openxml_para(text, opts)
  opts = opts or {}
  local pStyle = opts.pstyle and string.format('<w:pStyle w:val="%s"/>', xml_escape(opts.pstyle)) or ""
  local ind = ""
  if opts.left_twips or opts.hanging_twips then
    local left = opts.left_twips and tostring(opts.left_twips) or "0"
    local hang = opts.hanging_twips and tostring(opts.hanging_twips) or nil
    if hang then
      ind = string.format('<w:ind w:left="%s" w:hanging="%s"/>', left, hang)
    else
      ind = string.format('<w:ind w:left="%s"/>', left)
    end
  end
  local spacing = ""
  if opts.space_before or opts.space_after then
    local before = opts.space_before and tostring(opts.space_before) or "0"
    local after = opts.space_after and tostring(opts.space_after) or "0"
    spacing = string.format('<w:spacing w:before="%s" w:after="%s"/>', before, after)
  end
  local rpr = ""
  if opts.bold then
    rpr = "<w:rPr><w:b/></w:rPr>"
  end
  return pandoc.RawBlock("openxml", string.format([[
<w:p>
  <w:pPr>%s%s%s</w:pPr>
  <w:r>%s<w:t xml:space="preserve">%s</w:t></w:r>
</w:p>
]], pStyle, ind, spacing, rpr, xml_escape(text)))
end

local function vspace_twips(after_twips)
  return openxml_para(" ", { space_after = after_twips or 0 })
end

local function blank_line()
  return openxml_para(" ", {})
end

local function remove_title_block_div(doc)
  local out = {}
  for _, b in ipairs(doc.blocks) do
    if not (b.t == "Div" and b.identifier == "title-block") then
      out[#out + 1] = b
    end
  end
  doc.blocks = out
end

-- Horizontal rule using Word paragraph borders.
-- thickness_eip: border thickness in eighths of a point (w:sz)
-- line_pt: paragraph line height in points (default 4)
local function hrule(thickness_eip, line_pt)
  local w = tostring(thickness_eip or 48)

  local lp = tonumber(line_pt) or 4
  if lp < 1 then lp = 1 end

  local line_twips = tostring(math.floor(lp * 20 + 0.5))
  local run_sz = tostring(math.floor(lp * 2 + 0.5))

  return pandoc.RawBlock("openxml", string.format([[
<w:p>
  <w:pPr>
    <w:spacing w:before="0" w:after="0" w:line="%s" w:lineRule="exact"/>
    <w:pBdr>
      <w:top w:val="single" w:sz="%s" w:space="0" w:color="000000"/>
    </w:pBdr>
  </w:pPr>
  <w:r>
    <w:rPr><w:sz w:val="%s"/></w:rPr>
    <w:t xml:space="preserve"> </w:t>
  </w:r>
</w:p>
]], line_twips, w, run_sz))
end

-- Convert Pandoc HorizontalRule (e.g., Markdown `---`) into a Word paragraph border.
-- sz_eip: border thickness in eighths of a point (w:sz). 4=0.5pt, 2=0.25pt.
-- after_twips: spacing AFTER the rule paragraph (twips). 240=12pt.
local function word_hrule(sz_eip, after_twips, before_twips)
  local sz = tostring(sz_eip or 4)
  local after = tostring(after_twips or 240)
  local before = tostring(before_twips or 0)
  return pandoc.RawBlock("openxml", string.format([[
<w:p>
  <w:pPr>
    <w:spacing w:before="%s" w:after="%s"/>
    <w:pBdr>
      <w:bottom w:val="single" w:sz="%s" w:space="0" w:color="000000"/>
    </w:pBdr>
  </w:pPr>
</w:p>
]], before, after, sz))
end

-- Make Markdown horizontal rules (`---`) thinner and add extra space after.
function HorizontalRule(_)
  return word_hrule(4, 240, 0)
end

-- Apply hanging indent to citeproc bibliography in DOCX without affecting PDF.
-- Pandoc citeproc typically emits a Div#refs.references containing Div.csl-entry blocks.
local BIB_STYLE = "Bibliography"

local function style_blocks_hanging(blocks)
  local out = {}
  for _, b in ipairs(blocks) do
    if b.t == "Para" then
      out[#out + 1] = set_custom_style(b, BIB_STYLE)
    elseif b.t == "Div" then
      b.content = style_blocks_hanging(b.content)
      out[#out + 1] = b
    else
      out[#out + 1] = b
    end
  end
  return out
end

function Div(el)
  local is_refs = (el.identifier == "refs")
  if not is_refs and el.classes then
    for _, c in ipairs(el.classes) do
      if c == "references" then
        is_refs = true
        break
      end
    end
  end
  if not is_refs then return nil end

  el.content = style_blocks_hanging(el.content)
  return el
end

local function cover_image_block(path)
  if not path or path == "" then return nil end
  local img = pandoc.Image({}, path)
  img.attr = pandoc.Attr("", {}, { width = "6.5in" })
  return pandoc.Para({ img })
end

-- Build banner as a simple table, but put content in the header row
-- so we do not get an extra blank header line in Word.
local function banner_table(header_left_blocks, header_right_blocks)
  if not (pandoc.utils and pandoc.utils.from_simple_table) then
    error("pandoc.utils.from_simple_table is not available; cannot build DOCX-safe banner table.")
  end

  local aligns = { pandoc.AlignLeft, pandoc.AlignRight }
  local widths = { 0.82, 0.18 }
  local headers = { header_left_blocks, header_right_blocks }
  local rows = {}

  local st
  if pandoc.SimpleTable then
    st = pandoc.SimpleTable({}, aligns, widths, headers, rows)
  else
    st = pandoc.Table({}, aligns, widths, headers, rows)
  end

  local t = pandoc.utils.from_simple_table(st)
  local a = t.attr or pandoc.Attr("", {}, {})
  local attrs = {}
  if a.attributes then
    for k, v in pairs(a.attributes) do attrs[k] = v end
  end
  attrs["custom-style"] = "Cover Banner Table"
  t.attr = pandoc.Attr(a.identifier or "", a.classes or {}, attrs)

  return t
end

function Pandoc(doc)
  local meta = doc.meta

  local title = trim(stringify(meta.title or ""))
  title = title:gsub("^%s*|%s?", ""):gsub("%s+", " ")
  title = trim(title)

  local authors = core.authors(meta)
  local defaults = core.defaults(meta)

  local fws_program = get(meta, "fws-program")
  if fws_program == "" then fws_program = defaults.fws_program end

  local fws_region = get(meta, "fws-region")
  if fws_region == "" then fws_region = defaults.fws_region end

  local fws_station = get(meta, "fws-station")
  local year = get(meta, "year")
  local report_number = get(meta, "report-number")

  local cover_image = get(meta, "cover-image")
  local cover_credit = get(meta, "cover-image-credit")

  local fws_logo = get(meta, "fws-logo")
  if fws_logo == "" then
    fws_logo = pandoc.path.join({ images_path, "fws_logo.png" })
  end

  doc.meta.title = nil
  doc.meta.author = nil
  remove_title_block_div(doc)

  local pre = {}

  pre[#pre + 1] = hrule(48, 4)

  local logo_img = pandoc.Image({}, fws_logo)
  logo_img.attr = pandoc.Attr("", {}, { height = "0.5in" })

  local agency_inlines = {
    pandoc.Strong({ cstyle("U.S. Fish and Wildlife Service", "Cover Banner Agency Char") }),
    pandoc.LineBreak(),
    pandoc.Strong({ cstyle("U.S. Department of the Interior", "Cover Banner Agency Char") })
  }

  local program_inlines = {
    pandoc.Strong({ cstyle(fws_program .. " – " .. fws_region .. " Region", "Cover Banner Program Char") })
  }

  local header_left = {
    set_custom_style(pandoc.Div({ pandoc.Para(agency_inlines) }), "Cover Banner Agency"),
    set_custom_style(pandoc.Div({ pandoc.Para(program_inlines) }), "Cover Banner Program")
  }

  local header_right = {
    set_custom_style(pandoc.Div({ pandoc.Para({ logo_img }) }), "Cover Banner Agency Logo")
  }

  pre[#pre + 1] = banner_table(header_left, header_right)
  pre[#pre + 1] = hrule(8, 4)

  local report_id = core.report_id(year, report_number)

  local top_line = ""
  if fws_station ~= "" then top_line = fws_station .. " " end
  if report_id ~= "" then top_line = top_line .. "Report # " .. report_id end
  if top_line ~= "" then pre[#pre + 1] = pstyle(top_line, "Cover Meta") end

  if title ~= "" then pre[#pre + 1] = pstyle(title, "Cover Title") end
  if authors.author_line ~= "" then pre[#pre + 1] = pstyle(authors.author_line, "Cover Authors") end

  local imgblk = cover_image_block(cover_image)
  if imgblk then pre[#pre + 1] = imgblk end
  if cover_credit ~= "" then pre[#pre + 1] = pstyle(cover_credit, "Cover Credit") end

  pre[#pre + 1] = page_break()

  local location = get(meta, "location")
  local doi = get(meta, "doi")
  local cover_caption = get(meta, "cover-caption")

  pre[#pre + 1] = pandoc.Para({ pandoc.Str(
    "This report is used to disseminate information and analysis about natural resources and related topics concerning lands managed by the U.S. Fish and Wildlife Service. This report supports the advancement of science and informed decision-making by publishing scientific findings that may be ongoing or too limited for journal publication but provide valuable information or interpretations to the field of study."
  )})

  pre[#pre + 1] = blank_line()

  pre[#pre + 1] = pandoc.Para({ pandoc.Str(
    "Manuscripts receive an appropriate level of peer review to ensure that the information is scientifically credible, technically accurate, appropriately written for the intended audience, and designed and published in a professional manner."
  )})

  pre[#pre + 1] = blank_line()

  pre[#pre + 1] = pandoc.Para({ pandoc.Str(
    "Disclaimer: The use of trade names of commercial products in this report does not constitute endorsement or recommendation for use by the federal government."
  )})

  pre[#pre + 1] = blank_line()

  pre[#pre + 1] = openxml_para("How to cite this report:", { bold = true, space_before = 120, space_after = 120 })

  local cite_bits = {}
  if authors.cite_author_line ~= "" then cite_bits[#cite_bits + 1] = authors.cite_author_line end
  if year ~= "" then cite_bits[#cite_bits + 1] = year .. "." end
  if title ~= "" then cite_bits[#cite_bits + 1] = title .. "." end
  if report_id ~= "" then cite_bits[#cite_bits + 1] = "Report " .. report_id .. "." end

  local org_bits = { "U.S. Fish and Wildlife Service" }
  if fws_program ~= "" then org_bits[#org_bits + 1] = fws_program end
  if fws_region ~= "" then org_bits[#org_bits + 1] = fws_region .. " Region" end
  cite_bits[#cite_bits + 1] = table.concat(org_bits, ", ") .. "."

  local place_bits = {}
  if fws_station ~= "" then place_bits[#place_bits + 1] = fws_station end
  if location ~= "" then place_bits[#place_bits + 1] = location end
  if #place_bits > 0 then
    cite_bits[#cite_bits + 1] = table.concat(place_bits, ", ") .. "."
  end

  if doi ~= "" then
    cite_bits[#cite_bits + 1] = "<https://doi.org/" .. doi .. ">."
  end

  pre[#pre + 1] = openxml_para(table.concat(cite_bits, " "), { left_twips = 720, hanging_twips = 720 })
  pre[#pre + 1] = blank_line()

  pre[#pre + 1] = vspace_twips(4800) -- approx. 3.33 inches

  pre[#pre + 1] = openxml_para("ON THE COVER", { bold = true, space_after = 60 })
  if cover_caption ~= "" then
    pre[#pre + 1] = pandoc.Para({ pandoc.Str(cover_caption) })
  end
  if cover_credit ~= "" then
    pre[#pre + 1] = pandoc.Para({ pandoc.Str(cover_credit) })
    pre[#pre + 1] = blank_line()
  end

  pre[#pre + 1] = page_break()

  for i = #pre, 1, -1 do
    table.insert(doc.blocks, 1, pre[i])
  end

  return doc
end
