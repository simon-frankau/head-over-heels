--
-- Generate a call graph for the given asm source file.
--
-- Probably very brittle

local f = io.open(arg[1], "r")

local function extract_label(str)
  -- TODO: Assumes no spaces around "," - currently the convention in the code.
  _, _, lhs, rhs = string.find(str, "(.*),(.*)")
  if rhs then
    return true, rhs
  else
    return false, str
  end
end

local edges = {}

local function add_edge(src, dst)
  local src_list = edges[src]
  if src_list == nil then
    src_list = {}
    edges[src] = src_list
  end
  src_list[#src_list + 1] = dst
end

local curr_sym

for line in f:lines() do
  -- Strip comments
  line = string.gsub(line, "%s*;.*", "")

  -- Strip trailing blah
  if string.find(line, "#end") then
    break
  end

  -- Handle labels.
  _, _, sym = string.find(line, "([A-Za-z0-9_]*):")
  if sym ~= nil then
    if curr_sym ~= nil then
      -- Fall through
      add_edge(curr_sym, sym)
    end
    curr_sym = sym

    print("LABEL: '" .. sym .. "'")
  end

  -- Calls always create edges, don't end flow.
  _, _, dest = string.find(line, "CALL%s+(.*)")
  if dest ~= nil then
    _, label = extract_label(dest)
    add_edge(curr_sym, label)

    print("CALLER: '" .. label .. "'")
  end

  -- Non-conditional returns end flows.
  _, _, cond = string.find(line, "RET%s*([A-Z]*)")
  if cond ~= nil then
    if not cond then
      curr_sym = nil
    end

    print("RETER: '" .. (cond ~= "" and "CONT" or "ALWAYS") .. "'")
  end

  -- Jumps create edges. Non-conditional jumps end flows.
  _, _, dest = string.find(line, "J[PR]%s+(.*)")
  if dest ~= nil then
    cond, label = extract_label(dest)
    add_edge(curr_sym, label)
    if not cond then
      curr_sym = nil
    end

    print("JUMPER: '" .. label .. "' " .. (cond and "COND" or "ALWAYS"))
  end

  -- DJNZ is a conditional jump.
  _, _, dest = string.find(line, "DJNZ%s+(.*)")
  if dest ~= nil then
    add_edge(curr_sym, dest)

    print("DJNZER: '" .. dest .. "'")
  end

  -- Data should not be part of a control flow - but is sometimes!
  if string.find(line, "DEF[BW]") then
    -- curr_sym = nil

    print("DATA")
  end
end