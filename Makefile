#
# Makefile for the Head Over Heels reverse-engineering.
#

ASM_FILES = $(shell find src/ -type f -name '*.asm')
BIN_FILES = $(wildcard bin/*)

.PHONY: all
all: diss_check check

########################################################################
# Rules to disassemble the memory image.
#

# Build a memory image from the .z80 game file.
out/memimage.bin: memimage/unz80.lua memimage/memimage.z80
	mkdir -p out/
	lua memimage/unz80.lua memimage/memimage.z80 > out/memimage.bin

# Build the disassembler used to pull the memory image apart.
out/diss: memimage/diss.c
	cc $< -o $@

# Dissassemble the memory image. This generates the .asm file from
# which the reversing was done.
out/memimage.asm: out/diss out/memimage.bin
	cd out && ./diss

# Recompile it back to a binary for a check...
out/memimage.rom: out/memimage.asm
	zasm $< -o $@

# And perform the check
.PHONY: diss_check
diss_check: out/memimage.bin out/memimage.rom
	diff out/memimage.bin out/memimage.rom

########################################################################
# Build the image from source, and compare it against the one from the
# memory image.

# Build the image from source.
out/HOH.bin: $(ASM_FILES) $(BIN_FILES)
	mkdir -p out/
	zasm src/HOH.asm -o out/HOH.bin -l out/HOH.list -w

# Check the binary built from the sources matches the one from the
# memory image.
.PHONY: check
check: out/HOH.bin
	diff out/memimage.bin out/HOH.bin
