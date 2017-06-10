local f = io.open(arg[2], "rb")

local width = arg[1]

local contents = f:read("*a")

local len = contents:len()

local height = math.ceil(len / width)

print("#define IMG_width "  .. width * 8)
print("#define IMG_height " .. height)

print("static unsigned char IMG_bits[] = {")

local function flip(x)
  local y = 0
  for i = 1, 8 do
    y = y * 2
    x = x / 2
    local x2 = math.floor(x)
    if x ~= x2 then
      y = y + 1
    end
    x = x2
  end
  return y
end

local as_str = {}

for i = 1, len do
  as_str[i] = string.format("0x%02x", flip(contents:byte(i)))
end

print(table.concat(as_str, ", "))

print("};")
