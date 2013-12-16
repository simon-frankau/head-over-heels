#!/bin/sh
set -e
mkdir -p ../out
~/bin/lua5.1 unz80.lua memimage.z80 > ../out/memimage.bin
# Command-line stuff not set up. Here's one I prepared earlier with Xcode:
# gcc BLAH
cp ~/z80diss/build/Release/z80diss ../out/diss
pushd ../out
./diss
popd