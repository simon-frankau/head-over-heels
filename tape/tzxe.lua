local f = io.open(arg[1], "rb")

local contents = f:read("*a")

local offset = 1

local function is_eof()
    return offset == #contents
end

local function get_byte()
    assert(not is_eof(), "Unexpected EOF!")
    local c = contents:byte(offset)
    offset = offset + 1
    return c
end

local function get_word()
    local lo = get_byte()
    local hi = get_byte()
    return hi * 256 + lo
end

------------------------------------------------------------------------
-- Blocks

local function read_header()
    local hdr = "ZXTape!"

    for i = 1,#hdr do
        assert(get_byte() == hdr:byte(i), "Bad header (1)")
    end

    assert(get_byte() == 0x1a, "Bad header (2)")

    local major = get_byte()
    local minor = get_byte()

    local txt = [[
# HEADER

Major: 0x%02x
Minor: 0x%02x
]]

    io.write(txt:format(major, minor))
end

function id_10()
    local pause   = get_word()
    local dat_len = get_word()
    local data    = {}
    for i=1,dat_len do
        data[i] = string.format("0x%02x", get_byte())
    end

    local txt = [[
# 10 Standard speed data block

Pause: 0x%04x
Length: 0x%04x
Data: %s
]]

    io.write(txt:format(pause, dat_len, table.concat(data, ", ")))
end

function id_12()
    local length = get_word()
    local num    = get_word()

    local txt = [[
# 12 Pure tone

Length: 0x%04x
NumPulses: 0x%04x
]]

    io.write(txt:format(length, num))
end

function id_13()
    local count = get_byte()
    local data   = {}
    for i=1,count do
        data[i] = string.format("0x%04x", get_word())
    end

    local txt = [[
# 13 Pulse sequence

Count: 0x%02x
Data: %s
]]

    io.write(txt:format(count, table.concat(data, ", ")))
end

function id_14()
    local zero_len = get_word()
    local one_len  = get_word()
    local end_bits = get_byte()
    local pause    = get_word()
    local data_len = get_byte() + get_word() * 256
    local data   = {}
    for i=1,data_len do
        data[i] = string.format("0x%02x", get_byte())
    end
    
    local txt = [[
# 14 Pure data block

ZeroLen: 0x%04x
OneLen: 0x%04x
EndBits: 0x%02x
Pause: 0x%04x
DataLen: 0x%06x
Data: %s
]]

    io.write(txt:format(zero_len, one_len, end_bits, pause, data_len,
             table.concat(data, ", ")))
end

function id_21()
    local str_len = get_byte()
    local data    = {}
    for i=1,str_len do
        data[i] = string.format("0x%02x", get_byte())
    end

    local txt = [[
# 21 Group start

Length: 0x%02x
Data: %s
]]

    io.write(txt:format(str_len, table.concat(data, ", ")))
end

function id_22()
    local txt = [[
# 22 Group end
]]

    io.write(txt)
end

------------------------------------------------------------------------
-- Main block
--

read_header()

local function dispatch()
    local idx = get_byte()
    local fn = _G[string.format("id_%02x", idx)]
    if not fn then
        error(string.format("Unrecognised block type - 0x%02x", idx))
    end
    fn()
end

while not is_eof() do
    print()
    dispatch()
end

print("\n# EOF")
