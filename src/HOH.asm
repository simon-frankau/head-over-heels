;;
;; HOH.asm
;;
;; Main Head Over Heels source file
;;
;; Glues together all the individual source files
;;

#target ROM
#code HOH, 0, $FFFF
        defs $4000, $00

; MAGIC_OFFSET is the offset by which the data in the higher area of
; memory is moved down by. Before this area is the 128K-specific sound code,
; which is copied into a different bank if it's needed, before the
; higher data is moved down, leaving space at the top for extra
; temporary data to be written.
MAGIC_OFFSET:   EQU 360

#insert "../bin/screen.scr"
#include "rooms/room_data.asm"
#include "mainloop.asm"
#include "interrupts.asm"
#include "draw_blacked.asm"
#include "gfx1/attr_scheme.asm"
#include "gfx1/char_code.asm"
#include "ui/controls.asm"
#include "gfx2/columns.asm"
#include "rooms/room.asm"
#include "stuff.asm"
#include "ui/menus.asm"
#include "gfx2/occlude.asm"
#include "objects/objects.asm"
#include "rooms/walls.asm"
#include "specials.asm"
#include "scoring.asm"
#include "directions.asm"
#include "utils/helpers.asm"
#include "objects/lists.asm"
#include "ui/sprite_stuff.asm"
#include "objects/obj_fns.asm"
#include "gfx1/screen_vars.asm"
#include "gfx1/blit_screen.asm"
#include "gfx1/screen_bits.asm"
#include "ui/controls2.asm"
#include "sound/sound48k.asm"
#include "gfx1/blit_mask.asm"
#include "gfx2/background.asm"
#include "gfx1/blit_rot.asm"
#include "gfx2/scene.asm"
#include "rooms/room_utils.asm"
#include "utils/fill_zero.asm"
#include "state.asm"
#include "wiggle.asm"
#include "character.asm"
#include "contact.asm"
#include "gfx2/get_sprite.asm"
#include "objects/procobj.asm"
#include "objects/depthcmp.asm"
#include "movement.asm"
#include "gfx1/print_char.asm"
#include "sound/patch.asm"
#include "sound/sound128k.asm"
#include "utils/data_space.asm"
#include "data_trailer.asm"

#end
