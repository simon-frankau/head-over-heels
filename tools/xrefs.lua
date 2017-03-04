--
-- Generate a call graph for the given asm source file.
--
-- Probably very brittle

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
  if string.find(dst, "[(]") then
    -- Indirect jumps etc. Give up.
    print("// Computed jump from " .. src)
    return
  end

  local src_list = edges[src]
  if src_list == nil then
    src_list = {}
    edges[src] = src_list
  end
  src_list[dst] = true
end

local debug = nil

local function read_asm(filename)
  local fin = io.open(filename, "r")

  local curr_sym
  local reinit_call

  -- Slurp up the data
  for line in fin:lines() do
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

      if debug then print("LABEL: '" .. sym .. "'") end
    end

    if string.find(line, "DEF[BW]") then
      -- Data can appear immediately after a call to Reinitialise.
      if not reinit_call then
        curr_sym = nil
      end

      if debug then print("DATA") end
    end

    if string.find(line, "EQU") then
      curr_sym = nil

      if debug then print("EQU") end
    end

    reinit_call = false

    -- Calls always create edges, don't end flow.
    _, _, dest = string.find(line, "CALL%s+(.*)")
    if dest ~= nil then
      _, label = extract_label(dest)
      add_edge(curr_sym, label)
      -- Nasty hack
      if dest == "Reinitialise" then
        reinit_call = true
      end

      if debug then print("CALLER: '" .. label .. "'") end
    end

    -- Non-conditional returns end flows.
    _, _, cond = string.find(line, "RET%s*([A-Z]*)")
    if cond ~= nil then
      if cond == "" then
        curr_sym = nil
      end

      if debug then print("RETER: '" .. (cond ~= "" and "CONT" or "ALWAYS") .. "'") end
    end

    -- Jumps create edges. Non-conditional jumps end flows.
    _, _, dest = string.find(line, "J[PR]%s+(.*)")
    if dest ~= nil then
      cond, label = extract_label(dest)
      add_edge(curr_sym, label)
      if not cond then
        curr_sym = nil
      end

      if debug then print("JUMPER: '" .. label .. "' " .. (cond and "COND" or "ALWAYS")) end
    end

    -- DJNZ is a conditional jump.
    _, _, dest = string.find(line, "DJNZ%s+(.*)")
    if dest ~= nil then
      add_edge(curr_sym, dest)

      if debug then print("DJNZER: '" .. dest .. "'") end
    end
  end

  fin:close()
end

local function write_graph(name, nodes)
  local fout = io.open(name, "w")
  fout:write("digraph calls {\n")

  local function write_node(node)
    local list = edges[node]
    if list ~= nil then
      edges[node] = nil
      for dest, _ in pairs(list) do
        fout:write("  " .. node .. " -> " .. dest .. ";\n")
        write_node(dest)
      end
    end
  end

  for _, node in ipairs(nodes) do
     write_node(node)
  end

  fout:write("}\n")
  fout:close()
end

local function write_remaining()
  print("digraph calls {")

  for src, dsts in pairs(edges) do
    for dst, _ in pairs(dsts) do
      print("  " .. src .. " -> " .. dst .. ";")
    end
  end

  print("}")
end

read_asm(arg[1])
read_asm("fake.asm")

-- Remove edge out of game, so we can extract the main game loop.
edges["FinishGame"]["Main"] = nil

write_graph("sprite.dot", {"Draw3x24", "BlitObject"})
write_graph("menus.dot", {"GoMainMenu"})
write_graph("gameover.dot", {"GameOverScreen"})
write_graph("screen.dot", {"DrawScreen"})
write_graph("end.dot", {"EndThing"})
write_graph("objfns.dot", {"CallObjFn"})
write_graph("37.dot", {"EPIC_37"})
write_graph("ct15.dot", {"CharThing15"})
write_graph("loop.dot", {"MainLoop"})
write_graph("entry.dot", {"Entry"})

write_remaining()
