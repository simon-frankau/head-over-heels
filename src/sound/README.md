# sound directory: Sound generation

This directory contains:

 * **sound.asm** 48K sound generation code.
 * **patch.asm** Code to patch to 128K sound generation.

It relies on the LastOut variable.

It exports the following symbols:

 * AltPlaySound
 * IrqFn
 * PlaySound
 * ShuffleMem
 * Snd2
 * SndEnable
