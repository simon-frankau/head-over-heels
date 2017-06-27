# ui directory: Input-handling, menus, extra graphics

This directory contains input-handling and those parts of the graphics
which aren't the main room-drawing parts.

 * **menus.asm** provides the menu-drawing infrastructure, the main
   menus, and the main strings table.
 * **controls.asm** mostly contains the functions to receive unmapped
   input and set up the key mappings.
 * **controls2.asm** contains the mapped keys function (GetInputCtrls)
   and 'IsHPressed'.
 * **sprite_stuff.asm** does non-level sprite drawing - the crown
   screen, game screen periphery, etc.

They export the following symbols used elsewhere:

 * CTRL_ATTR1
 * CTRL_ATTR3
 * CTRL_POS_LIGHTNING
 * Clear3x24
 * CrownScreen
 * CrownScreenCont
 * Draw3x24
 * DrawScreenPeriphery
 * GameOverScreen
 * GetInputCtrls
 * GetInputEntSh
 * GoMainMenu
 * InitStick
 * IsHPressed
 * MENU_SOUND
 * STR_FINISH_RESTART
 * STR_FREEDOM
 * STR_GAME_SYMBOLS
 * Strings2
 * Strings
 * WaitInputClear
