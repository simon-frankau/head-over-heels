local f = io.open(arg[1], "rb")

local contents = f:read("*a")

local len = contents:len()

local pos = 31 + 54 + 2 + 3

for i=1,0x4000 do
  io.write(string.char(0))
end

local written = 0

while pos < len do

  if written == 0x4000 then
    written = 0
    pos = pos + 3
  end

  local b = contents:byte(pos)
  if b == 0xed and contents:byte(pos+1) == 0xed then
    local reps = contents:byte(pos+2)
    local char = contents:byte(pos+3)
    for i=1,reps do
      io.write(string.char(char))
      written = written + 1
    end
    pos = pos + 4
  else
    io.write(string.char(b))
    pos = pos + 1
    written = written + 1
  end
end
