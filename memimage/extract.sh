#!/bin/sh
set -e

# Build a plain image
mkdir -p ../out
~/bin/lua5.1 unz80.lua memimage.z80 > ../out/memimage.bin

# Build and run the decompiler...
# Command-line stuff not set up. Here's one I prepared earlier with Xcode:
# gcc BLAH
# cp ~/z80diss/build/Release/z80diss ../out/diss
pushd ../out
./diss
popd

# And then compile it back up and check we're where we started...
~/bin/zasm/zasm ../out/memimage.asm
diff ../out/memimage.bin ../out/memimage.rom 
