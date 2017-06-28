# sound directory: Sound generation

This directory contains:

 * **sound48k.asm** 48K sound generation code.
 * **patch.asm** Code to patch to 128K sound generation.
 * **sound128k.asm** 128k sound generation code that gets patched in.

It relies on the LastOut variable.

It exports the following symbols:

 * PlayTune
 * IrqFn
 * PlaySound
 * ShuffleMem
 * Snd2
 * SndEnable

The sounds are:

  * **C0** Silence?
  * **C1** "Tada!" noise
  * **C2** Hornpipe
  * **C3** Theme music
  * **C4** Nope noise (e.g. can't swap characters now noise)
  * **C5** Dum-diddy-dum dum-diddy-dum etc.
  * **C6** Death noise
  * **C7** Teleport beam up
  * **C8** Teleport beam down
  * **47** Teleporter waiting noise
  * **48** Donut firing noise - a sweep up, arpeggio down
  * **05** Beepy sound, baddy direction change
  * **04** Clicky blip
  * **80** Slower up and down - Walking sound
  * **81** Stacatto up and down - Running sound
  * **82** Another descending sequence - faster
  * **83** Repeated descending sequence - falling.
  * **84** Repeated rising sequence
  * **85** Even higher blip
  * **86** Higher Blip than menu
  * **87** Sweep down and up.
  * **88** Menu blip

The above list is 48K sounds. I think there are some extra 128K-only
sounds, as "SetSound" is called on 1,3,4,5,6, and sounds 40-46 are
used as world sounds.
