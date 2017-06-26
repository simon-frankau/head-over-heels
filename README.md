# Head Over Heels reverse engineered

This is my attempt to reverse engineer the ZX Spectrum version of Head
Over Heels. I started with a memory image, disassembled it, and then
tidied up the disassembly, at each stage checking that it will still
recompile back to the original memory image.

For the sprites, etc., I've written tools to dump out the contents.

I don't expect the contents of this repo to be particularly
intelligible to anyone else, being in-progress work of a project
basically for my own amusement. Good luck!

## Tools needed

This repo needs:

 * **GNU Make** for the Makefile
 * **lua** for the scripts
 * **gcc** or the like for the modified Z80 dissassembler, diss.c
 * **[zasm](https://k1.spdns.de/Develop/Projects/zasm/Distributions/)**
   for the assembler
 * **scr2gif** for the loading screen
 * **dot** from GraphViz for the call graphs

## License

I'm reverse-engineering someone else's code, and using someone else's
disassembler to do it. I wouldn't worry about a license!
