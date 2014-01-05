#!/bin/sh
set -e

# Extract the images as XBM.
mkdir -p ../out
for EACH in img_3x56 img_3x32 img_3x24
do
    ~/bin/lua5.1 xbmify.lua 3 ../$EACH.bin > ../out/$EACH.xbm
done

~/bin/lua5.1 xbmify.lua 4 ../img_4x28.bin > ../out/img_4x28.xbm

~/bin/lua5.1 xbmify.lua 2 ../img_2x24.bin > ../out/img_2x24.xbm

~/bin/lua5.1 xbmify.lua 1 ../img_chars.bin > ../out/img_chars.xbm

~/bin/scr2gif ../screen.scr 
mv ../screen.gif ../out
