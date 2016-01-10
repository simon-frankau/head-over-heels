-- Absolutely horric hacked-up script. Checking it in before I tidy it up.

local f = io.open(arg[1], "rb")
local contents = f:read("*a")

local idx_byte = 0
local idx_bit = 0

function setfetch(posn)
  idx_byte = posn
  idx_bit = 0
end

function fetch1()
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

function process_core(next_pos)
    local code = fetchn(8)
    while code ~= 255 and idx_byte <= next_pos do
      if code >= 0xc0 then
        -- io.write(string.format("Recurse 8 3 3 3: %01x %01x %01x %01x\n",
        --                         code, fetchn(3), fetchn(3), fetchn(3)))
        fetchn(3) fetchn(3) fetchn(3)
      else
        -- io.write(string.format("Code 8 0x%02x ", code))

        local read_once = fetch1()
        -- io.write(string.format("Read once 1? %s ", tostring(read_once)))
        local should_loop = fetch1()
        -- io.write(string.format("Should loop 1? %s ", tostring(should_loop)))
        if not read_once then
          should_loop = true -- Always loop if not reading once
          -- io.write("\n")
        else
          -- io.write(string.format("Flag 1? %s\n", tostring(fetch1())))
          fetch1()
        end

        repeat
          if not read_once then
            -- io.write(string.format("Flag 1? %s ", tostring(fetch1())))
            fetch1()
          end

          local u = fetchn(3)
          local v = fetchn(3)
          local z = fetchn(3)
          -- io.write(string.format("3 3 3 U=%01x V=%01x Z=%01x\n", u, v, z))
        until (u == 7 and v == 7 and z == 0) or not should_loop
      end

      code = fetchn(8)
    end
end

function process_recur(posn)
  posn = posn + 1 -- Make allowances for one-based indexing
  while contents:byte(posn) ~= 0 do
    local len = contents:byte(posn)
    local id = contents:byte(posn+1)
    local next_pos = posn + len + 1

    io.write("========================================\n")
    io.write(string.format("Address: 0x%04x\n", posn - 1))
    io.write(string.format("Sub id: 0x%02x\n", id))

    setfetch(posn + 2)
    process_core(next_pos)

    if idx_bit > 0 then idx_byte = idx_byte + 1 end
    if idx_byte ~= next_pos then
      io.write("GOSH!\n")
    end

    posn = next_pos
  end
end


function process(posn)
  posn = posn + 1 -- Make allowances for one-based indexing
  while contents:byte(posn) ~= 0 do
    local len = contents:byte(posn)
    local next_pos = posn + len + 1

    io.write("========================================\n")
    io.write(string.format("Address: 0x%04x\n", posn - 1))
    setfetch(posn + 1)

    io.write(string.format("Room Id: 0x%02x\n", fetchn(12)))
    io.write(string.format("Mystery field (BPD): %01x\n", fetchn(3)))
    io.write(string.format("Attrib scheme: %01x\n", fetchn(3)))
    io.write(string.format("World id: %01x\n", fetchn(3)))
    io.write(string.format("Mystery field (BPDSubB): %01x\n", fetchn(3)))
    for i=1,4 do
        io.write(string.format("Mystery field (ThingA): %01x\n", fetchn(3)))
    end
    io.write(string.format("Floor code: %01x\n", fetchn(3)))

    process_core(next_pos)

    if idx_bit > 0 then idx_byte = idx_byte + 1 end
    if idx_byte ~= next_pos then
      io.write("GOSH!\n")
    end

    posn = next_pos
  end
end

-- process_recur(0x5b00)
process(0x5c71)
process(0x6b16)