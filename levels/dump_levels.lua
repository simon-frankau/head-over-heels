local f = io.open(arg[1], "rb")
local contents = f:read("*a")

-- Set of functions to access the packed arrays
do
  local idx_byte = 0
  local idx_bit = 0
  local entry_posn = 0

  function init_posn(posn)
    entry_posn = posn + 1 -- Take account of 1-based indexing
    started = false
  end

  function next_entry()
    if started then
      -- Check no gaps from the previous entry.
      if idx_bit > 0 then idx_byte = idx_byte + 1 end
      if idx_byte ~= entry_posn then
        io.write("GAP FROM PREVIOUS ENTRY!\n")
      end
    end
    started = true

    local entry_len = contents:byte(entry_posn)
    if entry_len == 0 then return false end
    io.write("========================================\n")
    io.write(string.format("Entry at 0x%04x, length 0x%02x\n", entry_posn - 1, entry_len))
    idx_byte = entry_posn + 1
    idx_bit = 0
    entry_posn = entry_posn + 1 + entry_len
    return true
  end

  function fetch1()
    -- A bit cheesy as I'm avoiding those fancy Lua bit-twiddling functions.
    local src = contents:byte(idx_byte)
    for i=1,idx_bit do
      src = src * 2
      if src >= 256 then src = src - 256 end
    end

    idx_bit = idx_bit + 1
    if idx_bit > 7 then
      idx_bit = 0
      idx_byte = idx_byte + 1
    end

    return src >= 128
  end

  function fetchn(n)
    local res = 0
    for i=1,n do
      res = res * 2
      if fetch1() then res = res + 1 end
    end
    return res
  end
end

function print_body()
    repeat
      local code = fetchn(8)
      if code == 0xff then
        do end
      elseif code >= 0xc0 then
        io.write(string.format("Macro: %01x %01x %01x %01x\n",
                                code, fetchn(3), fetchn(3), fetchn(3)))
      else
        io.write(string.format("Object: 0x%02x ", code))

        local read_once = fetch1()
        io.write(read_once and "Single flag " or "Multi flag ")
        local should_loop = fetch1()
        io.write(should_loop and "Loop " or "Singleton ")
        if not read_once then
          should_loop = true -- Always loop if not reading once
          io.write("\n")
        else
          io.write(fetch1() and "T\n" or "F\n")
        end

        repeat
          if not read_once then
            io.write(fetch1() and "T " or "F ")
          end
          local u = fetchn(3)
          local v = fetchn(3)
          local z = fetchn(3)
          io.write(string.format("U=%01x V=%01x Z=%01x\n", u, v, z))
        until (u == 7 and v == 7 and z == 0) or not should_loop
      end
    until code == 0xff
end

function print_header()
  io.write(string.format("Mystery field (BPD): %01x\n", fetchn(3)))
  io.write(string.format("Attrib scheme: %01x\n", fetchn(3)))
  io.write(string.format("World id: %01x\n", fetchn(3)))
  io.write(string.format("Door style: %01x\n", fetchn(3)))
  for i=1,4 do
    io.write(string.format("Door: %01x\n", fetchn(3)))
  end
  io.write(string.format("Floor code: %01x\n", fetchn(3)))
end

function print_macros(posn)
  init_posn(posn)
  while next_entry() do
    io.write(string.format("Macro id: 0x%02x\n", fetchn(8)))
    print_body()
  end
end

function print_rooms(posn)
  init_posn(posn)
  while next_entry() do
    io.write(string.format("Room Id: 0x%02x\n", fetchn(12)))
    print_header()
    print_body()
  end
end

print_macros(0x5b00)
print_rooms(0x5c71)
print_rooms(0x6b16)
