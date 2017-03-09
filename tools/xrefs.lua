--
-- Generate a call graph for the given asm source file.
--
-- Probably very brittle
--

-- TODO/Wish list:
-- * Elide internal nodes of known functions
-- * Show variables referenced

local function extract_label(str)
  -- TODO: Assumes no spaces around "," - currently the convention in the code.
  _, _, lhs, rhs = string.find(str, "(.*),(.*)")
  if rhs then
    return true, rhs
  else
    return false, str
  end
end

local nodes = {}
local edges = {}

local function add_edge(src, dst)
  if string.find(dst, "[(]") then
    -- Indirect jumps etc. Give up.
    print("INFO: Computed jump from " .. src)
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
      nodes[sym] = true
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
    _, _, dest = string.find(line, "CALL%s+([A-Za-z0-9,_()]*)")
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
    _, _, dest = string.find(line, "J[PR]%s+([A-Za-z0-9,_()]*)")
    if dest ~= nil then
      cond, label = extract_label(dest)
      add_edge(curr_sym, label)
      if not cond then
        curr_sym = nil
      end

      if debug then print("JUMPER: '" .. label .. "' " .. (cond and "COND" or "ALWAYS")) end
    end

    -- DJNZ is a conditional jump.
    _, _, dest = string.find(line, "DJNZ%s+([A-Za-z0-9,_()]*)")
    if dest ~= nil then
      add_edge(curr_sym, dest)

      if debug then print("DJNZER: '" .. dest .. "'") end
    end
  end

  fin:close()
end

local function check_nodes()
  for src,edge_list in pairs(edges) do
    for dst, _ in pairs(edge_list) do
      if not nodes[dst] then
        print("WARNING: '" .. src .. "' has edge to unknown node '" .. dst .. "'")
      end
    end
  end
end

local function write_graph(name, starting_nodes)
  local fout = io.open(name, "w")
  fout:write("digraph calls {\n")
  local seen_nodes = {}

  local function write_node(node)
    -- Only process each node once.
    if seen_nodes[node] then
      return
    end
    seen_nodes[node] = true

    -- If the node is unclaimed, claim it. Otherwise, mark as a 'far' node.
    if nodes[node] == true then
      nodes[node] = name
      -- fout:write("  " .. node .. ";\n")
    else
      fout:write("  " .. node .. " [style=bold,shape=rectangle];\n")
      -- Don't follow far nodes.
      return
    end

    -- Then write out the edges?
    local list = edges[node]
    if list ~= nil then
      edges[node] = nil
      for dest, _ in pairs(list) do
        fout:write("  " .. node .. " -> " .. dest .. ";\n")
        write_node(dest)
      end
    end
  end

  for _, node in ipairs(starting_nodes) do
     write_node(node)
  end

  fout:write("}\n")
  fout:close()
end

local function write_remaining()
  local remaining_list = {}
  -- Only print nodes with edges
  for node, location in pairs(nodes) do
    if location == true and edges[node] then
      -- Not yet in another file.
      remaining_list[#remaining_list + 1] = node
    end
  end
  write_graph("../out/HOH.dot", remaining_list)
end

------------------------------------------------------------------------
-- Main running code

read_asm(arg[1])
read_asm("fake.asm")

check_nodes()

-- Remove edge out of game, so we can extract the main game loop.
edges["FinishGame"]["Main"] = nil

write_graph("sprite.dot", {"Draw3x24", "BlitObject"})
write_graph("menus.dot", {"GoMainMenu"})
write_graph("gameover.dot", {"GameOverScreen"})
write_graph("enlist.dot", {"Enlist"})
write_graph("enter1.dot", {"ProcEntry"})
write_graph("enter.dot", {"EnterRoom"})
write_graph("screen.dot", {"DrawScreen"})
write_graph("end.dot", {"EndThing"})
write_graph("tablecall.dot", {"DoTableCall"})
write_graph("objfns.dot", {"CallObjFn"})
write_graph("37.dot", {"EPIC_37"})
write_graph("ct15.dot", {"CharThing15"})
write_graph("loop.dot", {"MainLoop"})
write_graph("entry.dot", {"Entry"})

write_remaining()
