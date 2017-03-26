#!/bin/sh
set -e

~/bin/zasm 128k.asm -o out/128k.bin -l out/128k.list -w

~/bin/zasm HOH.asm -o out/HOH.bin -l out/HOH.list -w
diff out/memimage.bin out/HOH.bin
