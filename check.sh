#!/bin/sh
set -e

~/bin/zasm/zasm HOH.asm -o out/HOH.bin -l out/HOH.list -w
diff out/memimage.bin out/HOH.bin