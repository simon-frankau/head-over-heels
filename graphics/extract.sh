#!/bin/sh
set -e

# Extract the images as XBM.
mkdir -p ../out
for EACH in img_3x56 img_3x32 img_3x24
do
    ~/bin/lua5.1 xbmify.lua 3 ../$EACH.bin > ../out/$EACH.xbm
done
