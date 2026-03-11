-- lua/core.lua
-- Shared helpers for fws-report filters (pdf/docx/html)

local M = {}

local stringify = pandoc.utils.stringify

-- ---------- path helpers ----------

local function dirname(p)
  if not p or p == "" then return "" end
  p = p:gsub("\\", "/")
  p = p:gsub("/+$", "")
  return (p:gsub("/[^/]*$", ""))
end

function M.extension_paths(script_dir)
  local sd = (script_dir or ""):gsub("\\", "/")
  local extdir = dirname(sd) -- parent of lua/
  local fonts_path  = (extdir .. "/fonts/"):gsub("\\", "/")
  local images_path = (extdir .. "/images/"):gsub("\\", "/")
  return {
    extdir = extdir,
    fonts_path = fonts_path,
    images_path = images_path
  }
end

-- ---------- text / meta helpers ----------

function M.trim(s)
  s = tostring(s or "")
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

function M.meta_string(meta, key)
  if not (meta and meta[key]) then
    return ""
  end
  return M.trim(stringify(meta[key]))
end

function M.report_id(year, report_number)
  year = M.trim(year)
  report_number = M.trim(report_number)

  if year ~= "" and report_number ~= "" then
    return year .. "-" .. report_number
  end
  if year ~= "" then
    return year
  end
  return report_number
end

function M.ensure_metalist(x)
  if not x then
    return pandoc.MetaList({})
  end
  if type(x) == "table" and x.t == "MetaList" then
    return x
  end
  return pandoc.MetaList({ x })
end

-- ---------- author parsing helpers ----------

local function parse_author(name)
  name = M.trim(name):gsub("%s+", " ")
  local parts = {}
  for w in name:gmatch("%S+") do
    parts[#parts + 1] = w
  end

  if #parts == 0 then
    return { first = "", last = "", first_initial = "" }
  end
  if #parts == 1 then
    return { first = "", last = parts[1], first_initial = "" }
  end

  local last = parts[#parts]
  table.remove(parts, #parts)
  local first = table.concat(parts, " ")

  local ini = {}
  for w in first:gmatch("%S+") do
    ini[#ini + 1] = w:sub(1, 1) .. "."
  end

  return {
    first = first,
    last = last,
    first_initial = table.concat(ini, " ")
  }
end

-- Returns:
--  names: {"Jane Biologist", "Joe Botanist", ...}
--  author_line: "Jane Biologist, Joe Botanist, ..."
--  cite_author_line: "Biologist, J., J. Botanist, ..."
function M.authors(meta)
  local a = meta and meta["author"] or nil
  local names = {}

  local function add_name(v)
    local s = M.trim(stringify(v))
    if s ~= "" then
      names[#names + 1] = s
    end
  end

  if a then
    if type(a) == "table" and a.t == "MetaList" then
      for _, v in ipairs(a) do
        add_name(v)
      end
    elseif type(a) == "table" and #a > 0 then
      for _, v in ipairs(a) do
        add_name(v)
      end
    else
      add_name(a)
    end
  end

  local author_line = table.concat(names, ", ")

  local cite_parts = {}
  for i, nm in ipairs(names) do
    local p = parse_author(nm)
    if p.last ~= "" and p.first_initial ~= "" then
      if i == 1 then
        cite_parts[#cite_parts + 1] = string.format("%s, %s", p.last, p.first_initial)
      else
        cite_parts[#cite_parts + 1] = string.format("%s %s", p.first_initial, p.last)
      end
    elseif p.last ~= "" then
      cite_parts[#cite_parts + 1] = p.last
    else
      cite_parts[#cite_parts + 1] = nm
    end
  end

  return {
    names = names,
    author_line = author_line,
    cite_author_line = table.concat(cite_parts, ", ")
  }
end

-- ---------- defaults ----------

function M.defaults(meta)
  local fws_program = M.meta_string(meta, "fws-program")
  if fws_program == "" then
    fws_program = "National Wildlife Refuge System"
  end

  local fws_region = M.meta_string(meta, "fws-region")
  if fws_region == "" then
    fws_region = "Alaska"
  end

  return {
    fws_program = fws_program,
    fws_region = fws_region
  }
end

return M