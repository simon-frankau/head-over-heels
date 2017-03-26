# sound directory: Sound generation

This directory contains:

 * **sound48k.asm** 48K sound generation code.
 * **patch.asm** Code to patch to 128K sound generation.
 * **sound128k.asm** 128k sound generation code that gets patched in.

It relies on the LastOut variable.

It exports the following symbols:

 * AltPlaySound
 * IrqFn
 * PlaySound
 * ShuffleMem
 * Snd2
 * SndEnable
