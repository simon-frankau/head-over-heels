local f = io.open(arg[1], "rb")

local contents = f:read("*a")

local len = contents:len()

local function unpack(x)
  return math.floor(x / 8), x % 8
end

-- Playing mode
local mode = {
  [0] = " ",
  [1] = " glissando",
  [2] = " stacatto"
}

-- Note durations.
local lengths = {
 [0] = "0.25", [1] = "0.5", [2] = "1", [3] = "1.5",
 [4] = "2",    [5] = "3",   [6] = "4", [7] = "8"
}

-- Note pitches
local pitches = {
  [0] = "A",  [1] = "A#", [2]  = "B",  [3]  = "C",
  [4] = "C#", [5] = "D",  [6]  = "D#", [7]  = "E",
  [8] = "F",  [9] = "F#", [10] = "G",  [11] = "G#"
}

local function to_note(x)
  local note = pitches[x % 12]
  local octave = math.floor(x / 12)
  return note .. octave
end

-- If the 0x04 bit is set, it's immediate.
if math.floor(contents:byte(1) / 4) % 2 == 1 then
  local cycles = contents:byte(1)
  local delay = contents:byte(2) + 256 * contents:byte(3)
  print "Immediate:"
  print(string.format("  0x%02x cycles, 0x%04x per cycle", cycles, delay))
  -- Could be off by a factor of 2 or something, but looks plausible.
  local freq = 220 * 1316 / delay
  local length = 1000 * cycles / freq
  print(string.format("  Approx %f Hz, %f ms", freq, length))
else
  -- Otherwise, it's a score.
  local new_phrase = true
  local base = 0
  for i = 1, len do
    local x = contents:byte(i)
    if new_phrase then
      if x == 0xFF then
        print "End"
      elseif x == 0x00 then
        print "Repeat"
      else
        local high, low = unpack(x)
        base = high
        print(string.format("Phrase on %s%s", to_note(high), mode[low]))
      end
      new_phrase = false
    else
      if x == 0xFF then
        new_phrase = true
      else
        local high, low = unpack(x)
        local note = high ~= 0 and to_note(base + high) or "REST"
        print(string.format("  %s %s", note, lengths[low]))
      end
    end
  end
end