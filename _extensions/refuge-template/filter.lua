-- Builds:
--  - author-line: joined author list for cover display
--  - cite-first-author: first author for "How to cite"

local stringify = pandoc.utils.stringify

function Meta(meta)
  -- ----- Authors -----
  local a = meta["author"]
  if a then
    if type(a) == "table" and a[1] then
      meta["cite-first-author"] = stringify(a[1])

      local parts = {}
      for _, v in ipairs(a) do
        parts[#parts + 1] = stringify(v)
      end
      meta["author-line"] = table.concat(parts, ", ")
    else
      local s = stringify(a)
      meta["author-line"] = s

      local first = s
      first = first:gsub("%s*,%s*and%s+.*$", "")
      first = first:gsub("%s+and%s+.*$", "")
      first = first:gsub("%s*;%s*.*$", "")
      meta["cite-first-author"] = first
    end
  end

  return meta
end