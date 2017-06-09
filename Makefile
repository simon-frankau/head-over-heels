ASM_FILES = $(shell find src/ -type f -name '*.asm')
BIN_FILES = $(wildcard bin/*)

.PHONY: check
check: out/HOH.bin
	diff out/memimage.bin out/HOH.bin

out/HOH.bin: $(ASM_FILES) $(BIN_FILES)
	mkdir -p out/
	zasm src/HOH.asm -o out/HOH.bin -l out/HOH.list -w
