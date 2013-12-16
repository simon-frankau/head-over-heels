#!/bin/sh
set -e

~/bin/zasm/zasm HOH.asm -o out/HOH.bin
diff out/memimage.bin out/HOH.bin
