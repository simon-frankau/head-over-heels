# gfx1 directory: Low-level graphics routines

This directory contains the low-level graphics routines. Specifically:

 * **blit_mask.asm** does a masked blit of a sprite into an off-screen
   buffer. Uses nothing, and is used by scene.asm.
 * **blit_rot.asm** performs a blit with a sub-byte rotation into an
   offscreen buffer. Used by scene.asm.
 * **blit_screen.asm** copies data to the screen. Used by scene.asm,
   screen_bits.asm and sprite_stuff.asm.
 * **screen_bits.asm** provides various sprite utility functions.
   TODO: Could do with a polish.
 * **screen_vars.asm** defines some variables.
 * **attr_scheme.asm** deals with the attribute schemes.
 * **char_code.asm** defines CharCodeToAddr.
 * **print_char.asm** deals with printing (formatted) text.

The files in this directory depend upon utils/fill_zero.asm.

They rely on the following symbols defined elsewhere:

 * IMG_CHARS
 * SpriteWidth
 * Strings
 * Strings2
 * SpriteRowCount
 * ViewXExtent
 * ViewYExtent

They export the following symbols used elsewhere:

 * BlitMask[12345]of[345]
 * BlitRot
 * BlitScreen
 * Buffer
 * CHAR_*
 * CTRL_*
 * CharCursor
 * DELIM
 * DrawSprite
 * LastOut
 * Print2DigitsL
 * Print2DigitsR
 * Print4DigitsL
 * PrintChar
 * RoomOrigin
 * ScreenWipe
 * SetAttribs
 * SetCursor
 * UpdateAttribs
 * ViewBuff
