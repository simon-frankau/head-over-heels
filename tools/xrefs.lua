--
-- Generate a call graph for the given asm source file.
--
-- Probably very brittle
--

-- TODO/Wish list:
-- * Elide internal nodes of known functions
-- * Show variables referenced

local prefix = "out/graphs/"

local function extract_label(str)
  -- TODO: Assumes no spaces around "," - currently the convention in the code.
  _, _, lhs, rhs = string.find(str, "(.*),(.*)")
  if rhs then
    return true, rhs
  else
    return false, str
  end
end

-- Each node is labeled with the file that owns it.
local nodes = {}
local edges = {}
local files = {}

local function add_edge(src, dst)
  if dst == "" then
    -- Probably jp $...
    print("INFO: Skipping absolute jump from " .. src)
    return
  end
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
  files[filename] = true
  local fin = assert(io.open(filename, "r"))

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
      nodes[sym] = filename
      curr_sym = sym

      if debug then print("LABEL: '" .. sym .. "'") end
    end

    if string.find(line, "DEF[BW]") then
      -- Data can appear immediately after a call to certain functions
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
      if dest == "Reinitialise" or dest == "CopyData" then
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

local function write_graph(filename)
print(filename)
  _, _, name = string.find(filename, "/([A-Za-z0-9_]*).asm")
  local fout = io.open(prefix .. name .. ".dot", "w")
  fout:write("digraph calls {\n")
  local seen_nodes = {}

  local function write_node(node)
    -- Only process each node once.
    if seen_nodes[node] then
      return
    end
    seen_nodes[node] = true

    -- Skip far nodes
    if nodes[node] ~= filename then
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

  for node, name in pairs(nodes) do
    if name == filename then
      write_node(node)
    end
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
  write_graph("HOH.dot", remaining_list)
end

-- Build a graph of the edges between files.
local function write_cross_edges()
  local cross_edges = {}
  local owners = {}

  for node, src_file in pairs(nodes) do
    local list = edges[node]
    if list ~= nil then
      for dest, _ in pairs(list) do
        local dest_file = nodes[dest]
        if src_file ~= dest_file then
          if cross_edges[src_file] == nil then
            cross_edges[src_file] = {}
          end
          cross_edges[src_file][dest] = true
          if owners[dest_file] == nil then
            owners[dest_file] = {}
          end
          owners[dest_file][dest] = true

        end
      end
    end
  end

  local fout = io.open(prefix .. "connections.dot", "w")
  fout:write("digraph calls {\n")
  fout:write("  ranksep = 3;\n")
  fout:write("  rankdir = LR;\n")

  for file, dests in pairs(cross_edges) do
    for node, _ in pairs(dests) do
        local _, _, name = string.find(file, "/([A-Za-z0-9_]*).asm")
        name, _ = owners[file] and next(owners[file], nil) or name
        fout:write("  " .. name .. " -> " .. node .. ";\n")
    end
  end

  for owner_file, owned_nodes in pairs(owners) do
    _, _, name = string.find(owner_file, "/([A-Za-z0-9_]*).asm")
    fout:write("  subgraph cluster_" .. name .. "{\n")
    fout:write("    node [style=filled];\n")
    fout:write("    label=\"" .. owner_file .. "\";\n")
    for node, _ in pairs(owned_nodes) do
      fout:write("    " .. node .. ";\n")
    end
    fout:write("  }\n")
  end

  fout:write("}\n")
  fout:close()

end

------------------------------------------------------------------------
-- Main running code

for i = 1, #arg do
  read_asm(arg[i])
end

-- read_asm(arg[1])
-- read_asm("fake.asm")

check_nodes()

-- Remove edge out of game, so we can extract the main game loop.
if edges["FinishGame"] then
  edges["FinishGame"]["Main"] = nil
end

write_cross_edges()

for filename, _ in pairs(files) do
  write_graph(filename)
end

-- write_graph("sprite.dot", {"Draw3x24", "BlitObject"})
-- write_graph("menus.dot", {"GoMainMenu"})
-- write_graph("gameover.dot", {"GameOverScreen"})
-- write_graph("enlist.dot", {"Enlist"})
-- write_graph("enter1.dot", {"ProcEntry"})
-- write_graph("enter.dot", {"ReadRoom"})
-- write_graph("screen.dot", {"BuildRoom"})
-- write_graph("background.dot", {"DrawBkgnd"})
-- write_graph("end.dot", {"CrownScreenCont"})
-- write_graph("mysteries.dot", {"ChkSatOn", "CAB06"})
-- write_graph("move.dot", {"DoMove"})
-- write_graph("objaux.dot", {"ObjDraw", "ObjFnDisappear", "AnimateMe", "TurnOnCollision", "TurnRandomly"})
-- write_graph("objfns.dot", {"CallObjFn"})
-- write_graph("37.dot", {"EPIC_37"})
-- write_graph("ct15.dot", {"CharThing15"})
-- write_graph("loop.dot", {"MainLoop"})
-- write_graph("entry.dot", {"Entry"})
-- 
-- write_remaining()
