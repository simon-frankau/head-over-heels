	;; 
	;; HOH.asm
	;;
	;; Main Head Over Heels source file
	;;
	;; Glues together all the other assembly files, binaries, etc.
	;; 

#target ROM
#code HOH, 0, $FFFF
	defs $4000, $00

MAGIC_OFFSET:	EQU 360 	; The offset high data is moved down by...

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

L9376:	DEFB $FD,$F9,$FB,$FA,$FE,$F6,$F7,$F5

SetFacingDirEx: LD      C,(IY+$10)      ; Read direction code
                BIT     1,C             ; Heading 'down'?
                RES     4,(IY+$04)      ; Set bit 4 of flags, if so.
                JR      NZ,SetFacingDir
                SET     4,(IY+$04)
        ;; NB: Fall through
SetFacingDir:   LD      A,(IY+$0F)      ; Load animation code.
                AND     A
                RET     Z               ; Return if not animated
                BIT     2,C             ; Heading right?
        ;; TODO: All seems a bit complicated for what I think it does.
                LD      C,A
                JR      Z,SFD1          ; Then jump to that case.
                BIT     3,C
                RET     NZ
                LD      A,$08
                JR      SFD2
SFD1:           BIT     3,C             ; Ret if sprite currently faces forward.
                RET     Z
                XOR     A               ; ...
SFD2:           XOR     C
                AND     $0F
                XOR     C
                LD      (IY+$0F),A
                RET

L93AA:	DEFB $00,$00,$00,$00,$00,$00

	;; The phase mechanism allows an object to not get processed
	;; for one frame.
DoObjects:	LD	A,(Phase)
		XOR	$80
		LD	(Phase),A 		; Toggle top bit of Phase
		CALL	CharThing
	;; Loop over main object list...
		LD	HL,(ObjectLists + 2)
		JR	DO_3
DO_1:		PUSH	HL
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		EX	(SP),HL			; Next item on top of stack, curr item in HL
		EX	DE,HL
		LD	HL,10   ; TODO
		ADD	HL,DE
	;; Check position +10
		LD	A,(Phase)
		XOR	(HL)
		CP	$80			; Skip if top bit doesn't match Phase
		JR	C,DO_2
		LD	A,(HL)
		XOR	$80
		LD	(HL),A			; Flip top bit - will now mismatch Phase
		AND	$7F
		CALL	NZ,CallObjFn 		; And if any other bits set, call CallObjFn
DO_2:		POP	HL
DO_3:		LD	A,H			; loop until null pointer.
		OR	L
		JR	NZ,DO_1
		RET

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
        
StatusReinit:	DEFB $09	; Number of bytes to reinit with
	
		DEFB $00	; Inventory reset
		DEFB $00	; Speed reset
		DEFB $00	; Springs reset
		DEFB $00	; Heels invuln reset
		DEFB $00	; Head invuln reset
		DEFB $08	; Heels lives reset
		DEFB $08	; Head lives reset
		DEFB $00	; Donuts reset
		DEFB $00	; FIXME
	
Inventory:	DEFB $00	; Bit 0 purse, bit 1 hooter, bit 2 donuts FIXME
Speed:		DEFB $00	; Speed
		DEFB $00	; Springs
Invuln:		DEFB $00	; Heels invuln
		DEFB $00	; Head invuln
Lives:		DEFB $04	; Heels lives
		DEFB $04	; Head lives
Donuts:		DEFB $00	; Donuts
LA293:		DEFB $00
Character:	DEFB $03	; $3 = Both, $2 = Head, $1 = Heels
InSameRoom:	DEFB $01
LA296:	DEFB $00
LA297:	DEFB $00
InvulnModulo:	DEFB $03
SpeedModulo:	DEFB $02
	
ReinitThing:	DEFB $03	; Three bytes to reinit with
	
		DEFB $00
		DEFB $00
		DEFB $FF
	
LA29E:		DEFB $00
LA29F:		DEFB $00
IsStill:	DEFB $FF        ; $00 if moving, $FF if still

TickTock:	DEFB $02         ; Phase for moving
LA2A2:		DEFB $00
EntryPosn:	DEFB $00,$00,$00 ; Where we entered the room (for when we die).
LA2A6:		DEFB $03
Carrying:	DEFW $0000	 ; Pointer to carried object.
	
FiredObj:	DEFB $00,$00,$00,$00,$20
		DEFB $28,$0B,$C0
		DEFB $24,$08
		DEFB $12
		DEFB $FF,$FF,$00,$00
		DEFB $08,$00,$00
	
CharDir:	DEFB $0F        ; Bitmask of direction, suitable for passing to LookupDir.
SavedObjListIdx:	DEFB $00
OtherSoundId:	DEFB $00
SoundId:	DEFB $00	 ; Id of sound, +1 (0 = no sound)
Movement:	DEFB $FF
	
HeelsObj:	DEFB $00
LA2C1:	DEFB $00,$00,$00,$08
LA2C5:	DEFB $28,$0B,$C0
HeelsFrame:	DEFB $18,$21,$00,$FF,$FF
LA2CD:	DEFB $00,$00,$00,$00
LA2D1:	DEFB $00
	
HeadObj:	DEFB $00,$00,$00,$00,$08
LA2D7:	DEFB $28,$0B,$C0
HeadFrame:	DEFB $1F,$25,$00,$FF,$FF
LA2DF:	DEFB $00,$00
LA2E1:	DEFB $00,$00,$00

HeelsLoop:      DEFB $00,SPR_HEELS1,SPR_HEELS2,SPR_HEELS1,SPR_HEELS3,$00
HeelsBLoop:     DEFB $00,SPR_HEELSB1,SPR_HEELSB2,SPR_HEELSB1,SPR_HEELSB3,$00
HeadLoop:       DEFB $00,SPR_HEAD1,SPR_HEAD2,SPR_HEAD1,SPR_HEAD3,$00
HeadBLoop:      DEFB $00,SPR_HEADB1,SPR_HEADB2,SPR_HEADB1,SPR_HEADB3,$00
VapeLoop1:      DEFB $00, SPR_VAPE1, $80 | SPR_VAPE1
                DEFB $80 | SPR_VAPE2, SPR_VAPE2, $80 | SPR_VAPE2
                DEFB $80 | SPR_VAPE3, SPR_VAPE3, SPR_VAPE3, $80 | SPR_VAPE3, $80 | SPR_VAPE3
                DEFB SPR_VAPE3, SPR_VAPE3, $00
VapeLoop2:      DEFB $00, SPR_VAPE3, $80 | SPR_VAPE3, SPR_VAPE3, $80 | SPR_VAPE3
                DEFB $80 | SPR_VAPE2, SPR_VAPE2, SPR_VAPE1, $80 | SPR_VAPE2, $00

WiggleState:    DEFB $00
WiggleCounter:  DEFB $40

        ;; Start on 5th row of SPR_HEAD2
HEAD_OFFSET:    EQU (7 * 48 + 4) * 3 + 1

WiggleEyebrows:
        ;; Toggle top bit of WiggleState.
                LD      HL,WiggleState
                LD      A,$80
                XOR     (HL)
                LD      (HL),A
        ;; Check bit 0 of $C043 for source choice.
                LD      A,($C043) ; TODO
                BIT     0,A
        ;; Set up destination
                LD      HL,IMG_3x24 - MAGIC_OFFSET + HEAD_OFFSET
                LD      DE,XORs + 12 ; Reset means second image
                JR      Z,WE_1
                DEC     HL
                LD      DE,XORs ; Set means first image, dest 1 byte less.
        ;; Run XORify twice, at HL, and HL+0x48 (the other part of SPR_HEAD2).
WE_1:           PUSH    DE
                PUSH    HL
                CALL    XORify
                LD      DE,$48
                POP     HL
                ADD     HL,DE
                POP     DE
        ;; NB: Fall through

;; Source DE, dest HL, xor 2 bytes of 3 in, 6 times.
;; Used to XOR over 2 of three columns of a 3x24 sprite.
XORify:         LD      C,$06
        ;; C times, repeat the loop below, then HL++.
XOR_1:          LD      B,$02
        ;; XOR (DE++) over (HL++), B times.
XOR_2:          LD      A,(DE)
                XOR     (HL)
                LD      (HL),A
                INC     DE
                INC     HL
                DJNZ    XOR_2
                INC     HL
                DEC     C
                JR      NZ,XOR_1
                RET

        ;; Two images, of bits to flip to wiggle eyebrows, one facing
        ;; left, one right.
XORs:
#insert "../bin/img_2x6.bin"

#include "character.asm"

#include "contact.asm"

#include "gfx2/get_sprite.asm"

ObjVars:        DEFB $1B                ; Reinitialisation size

                DEFB $00
                DEFW Objects
                DEFW ObjectLists + 0
                DEFW ObjectLists + 2
                DEFW $0000
                DEFW $0000
                DEFW $0000,$0000
                DEFW $0000,$0000
                DEFW $0000,$0000
                DEFW $0000,$0000

        ;; The index into ObjectLists.
ObjListIdx:     DEFB $00
        ;; Current pointer for where we write objects into
ObjDest:        DEFW Objects
        ;; 'A' list item pointers are offset +2 from 'B' list pointers.
ObjListAPtr:    DEFW ObjectLists
ObjListBPtr:    DEFW ObjectLists + 2
        ;; Each list consists of a pair of pointers to linked lists of
        ;; objects (ListA and ListB). They're opposite directions in a
        ;; doubly-linked list, and each side has a head node, it seems.
ObjectLists:    DEFW $0000,$0000 ; 0 - Usual list
                DEFW $0000,$0000 ; 1 - Next room in V direction
                DEFW $0000,$0000 ; 2 - Next room in U direction
                DEFW $0000,$0000 ; 3 - Far
                DEFW $0000,$0000 ; 4 - Near

SavedObjDest:	DEFW Objects
SortObj:	DEFW $0000

        ;; Given an index in A, set the object list index and pointers.
SetObjList:     LD      (ObjListIdx),A
                ADD     A,A
                ADD     A,A
                ADD     A,ObjectLists & $ff
                LD      L,A
                ADC     A,ObjectLists >> 8
                SUB     L
                LD      H,A
        ;; ObjListAPtr = ObjectLists + (ObjListIdx) * 4
                LD      (ObjListAPtr),HL
                INC     HL
                INC     HL
        ;; ObjListBPtr = ObjectLists + (ObjListIdx) * 4 + 2
                LD      (ObjListBPtr),HL
                RET

;; DE contains an 'A' object pointer. Assumes the other half of the object
;; is in the next slot (+0x12). Syncs the object state.
SyncDoubleObject:
        ;; Copy 5 bytes, from the pointer location onwards:
        ;; Next pointer, flags, U & V coordinates.
                LD      HL,$0012
                ADD     HL,DE
                PUSH    HL
                EX      DE,HL
                LD      BC,$0005
                LDIR
        ;; Copy across Z coordinate, sutracting 6.
                LD      A,(HL)
                SUB     $06
                LD      (DE),A
        ;; If bit 5 of byte 9 is set on first object, we're done.
                INC     DE
                INC     HL
                INC     HL
                BIT     5,(HL)
                JR      NZ,SDO_2
        ;; Otherwise, copy the sprite over (byte 8).
                DEC     HL
                LDI
SDO_2:          POP     HL
                RET

#include "objects/procobj.asm"

#include "objects/depthcmp.asm"

#include "movement.asm"

#include "gfx1/print_char.asm"

#include "sound/patch.asm"

	;; NB: Not sure what this brief interlude is for!
XB867:	DEFB $F3,$21,$D3,$BD,$11,$00,$40,$01
XB86F:	DEFB $05,$00,$ED,$B0,$11,$00,$5B,$01,$00,$A5,$21,$54,$60,$C3,$00,$40
XB87F:	DEFB $ED,$B0,$C3,$30,$70

#include "sound/sound128k.asm"

#include "utils/data_space.asm"

#include "data_trailer.asm"

#end
