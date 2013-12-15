#!/bin/sh
set -e
mkdir -p ../out
~/bin/lua5.1 unz80.lua memimage.z80 > ../out/memimage.rom
