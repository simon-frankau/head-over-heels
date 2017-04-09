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

#insert "screen.scr"

#include "src/rooms/room_data.asm"

	;; Hack, should be removed.
#include "equs.asm"

MAGIC_OFFSET:	EQU 360 	; The offset high data is moved down by...

#include "mainloop.asm"

;; Given a fetched 3-bit value in A... returns 0 in A. I assume there
;; was support for multiple door sprites, that got nixed at some
;; point.
ToDoorId:       XOR     A
                RET

	;; Installs the interrupt hook
IrqInstall:	DI
		IM	2
		LD	A,$39		; Page full of FFhs.
		LD	I,A
		LD	A,$18
		LD	($FFFF),A 	; JR 0xFFF4
		LD	A,$C3		; JP ...
		LD	($FFF4),A
		LD	HL,IrqHandler 	; to IrqHandler
		LD	($FFF5),HL
		CALL	ShuffleMem
		EI
		RET

	;; The main interrupt hook - calls IrqFn and decrements FrameCounter (if non-zero).
IrqHandler:	PUSH	AF
		PUSH	BC
		PUSH	HL
		PUSH	DE
		PUSH	IX
		PUSH	IY
		CALL	IrqFn
		POP	IY
		POP	IX
		POP	DE
		POP	HL
		POP	BC
		LD	A,(FrameCounter)
		AND	A
		JR	Z,SkipWriteFrame
		DEC	A
		LD	(FrameCounter),A
SkipWriteFrame:	POP	AF
		EI
		RET

;; Draws the screen in black. Presumably hides the drawing process.
;;
;; Draws screen in black with an X extent from 32 to 192,
;; Y extent from 40 to 255 (?!).
DrawBlacked:	LD	A,$08
		CALL	SetAttribs 	; Set all black attributes
		LD	HL,$4048	; X extent
		LD	DE,$4857 	; Y extent
DBL_1:		PUSH	HL
		PUSH	DE
		CALL	CheckYAndDraw
		POP	DE
		POP	HL
		LD	H,L
		LD	A,L
		ADD	A,$14   ; First window is 8 wide, subsequent are 20.
		LD	L,A
		CP	$C1     ; Loop across the visible core of the screen.
		JR	C,DBL_1
		LD	HL,$4048
		LD	D,E
		LD	A,E
		ADD	A,$2A   ; First window is 15, subsequent are 42.
		LD	E,A     ; Loop all the way to row 255!
		JR	NC,DBL_1
		RET

#include "src/gfx1/attr_scheme.asm"

#include "src/gfx1/char_code.asm"
        
#include "controls.asm"

#include "src/gfx2/columns.asm"
        
#include "src/rooms/room.asm"
        
#include "stuff.asm"

#include "menus.asm"

;; Takes a sprite code in B and a height in A, and applies truncation
;; of the third column A * 2 + from the top of the column. This
;; performs removal of the bits of the door hidden by the walls.
;; If the door is raised, more of the frame is visible, so A is
;; the height of the door.
OccludeDoorway:
        ;; Copy the sprite (and mask) indexed by L to DoorwayBuf
		PUSH		AF
		LD		A,L
		LD		H,$00
		LD		(SpriteCode),A
		CALL		Sprite3x56
		EX		DE,HL
		LD		DE,DoorwayBuf
		PUSH		DE
		LD		BC, 56 * 3 * 2
		LDIR
		POP		HL
		POP		AF
	;; A = Min(A * 2 + 8, 0x38)
		ADD		A,A
		ADD		A,$08
		CP		$39
		JR		C,ODW
		LD		A,$38
	;; A *= 3
ODW:		LD		B,A
		ADD		A,A
		ADD		A,B
	;; DE = Top of sprite + A
	;; HL = Top of mask + A
		LD		E,A
		LD		D,$00
		ADD		HL,DE
		EX		DE,HL
		LD		HL, 56 * 3
		ADD		HL,DE
	;; B = $39 - A
		LD		A,B
		NEG
		ADD		A,$39
		LD		B,A
	;; C = ~$03
		LD		C,$FC
		JR		ODW3
	;; This loop then cuts off a wedge from the right-hand side,
	;; presumably to give a nice trunction of the image?
ODW2:		LD		A,(DE)
		AND		C
		LD		(DE),A
		INC		DE
		INC		DE
		INC		DE
		LD		A,C
		CPL
		OR		(HL)
		LD		(HL),A
		INC		HL
		INC		HL
		INC		HL
		AND		A
		RL		C
		AND		A
		RL		C
ODW3:		DJNZ	ODW2
	;; Clear the flipped flag for this copy.
		XOR		A
		LD		(DoorwayFlipped),A
		RET

#include "src/objects/objects.asm"

#include "src/rooms/walls.asm"

#include "specials.asm"

L8ADC:	DEFB $00,$00
L8ADE:	DEFB $00
L8ADF:	DEFB $00,$00,$00

NUM_ROOMS:      EQU 301
RoomMask:       DEFS NUM_ROOMS, $00

;; Clear donut count and then count number of inventory items we have
EmptyDonuts:    LD      HL,Inventory
                RES     2,(HL)
ED1:            EXX
                LD      BC,1
                JR      CountBits

WorldCount:     LD      HL,WorldMask ; FIXME: Possibly actually crowns...
                JR      ED1

RoomCount:      LD      HL,RoomMask
                EXX
                LD      BC,301
        ;; NB: Fall through

;; Counts #bits set in BC bytes starting at HL', returning them in DE.
;; Count is given in BCD.
CountBits:      EXX
                LD      DE,0
                EXX
        ;; Outer loop
CB1:            EXX
                LD      C,(HL)
        ;; Run inner loop 8 times?
                SCF
                RL      C
CB2:
        ;; BCD-normalise E
                LD      A,E
                ADC     A,$00
                DAA
                LD      E,A
        ;; BCD-normalise D
                LD      A,D
                ADC     A,$00
                DAA
                LD      D,A
        ;; And loop...
                SLA     C
                JR      NZ,CB2
        ;; So, I think we just added bit population of (HL') into DE'.
                INC     HL
                EXX
                DEC     BC
                LD      A,B
                OR      C
                JR      NZ,CB1
        ;; And do the same for the rest of the BC entries...
                EXX
                RET

InitNewGame1:	LD	HL,RoomMask
		LD	BC,NUM_ROOMS
		JP	FillZero

        ;; Gets the score and puts it in HL
GetScore:	CALL	InVictoryRoom 		; Zero set if end reached.
		PUSH	AF
		CALL	RoomCount
		POP	AF
		LD	HL,0
		JR	NZ,GS_1
		LD	HL,$0501
		LD	A,(LA295) 	; TODO: Non-zero gets you points.
		AND	A
		JR	Z,GS_1
		LD	HL,$1002
GS_1:		LD	BC,16
		CALL	MulAccBCD
        ;; 500 points per inventory item.
		PUSH	HL
		CALL	EmptyDonuts ; Alternatively, score inventory minus donuts?
		POP	HL
		LD	BC,500
		CALL	MulAccBCD
        ;; Add score for each world - 636 per world.
		PUSH	HL
		CALL	WorldCount
		POP	HL
		LD	BC,636
        ;; NB: Fall through.

        ;; HL += DE * BC. HL and DE are in BCD. BC is not.
MulAccBCD:      LD      A,E
                ADD     A,L
                DAA
                LD      L,A
                LD      A,H
                ADC     A,D
                DAA
                LD      H,A
                DEC     BC
                LD      A,B
                OR      C
                JR      NZ,MulAccBCD
                RET

;; Given a direction bitmask in A, return a direction code.
LookupDir:      AND     $0F
                ADD     A,DirTable & $FF
                LD      L,A
                ADC     A,DirTable >> 8
                SUB     L
                LD      H,A
                LD      A,(HL)
                RET

;; Input into this look-up table is the 4-bit bitmask:
;; Left Right Down Up.
;;
;; Bits are low if direction is pressed.
;;
;; Combinations are mapped to the following directions:
;;
;; $05 $04 $03
;; $06 $FF $02
;; $07 $00 $01
;;
DirTable:       DEFB $FF,$00,$04,$FF,$06,$07,$05,$06
                DEFB $02,$01,$03,$02,$FF,$00,$04,$FF

;; A has a direction, returns Y delta in C, X delta in B, and
;; third entry is the DirTable inverse mapping.
DirDeltas:      LD              L,A
                ADD             A,A
                ADD             A,L
                ADD             A,DirTable2 & $FF
                LD              L,A
                ADC             A,DirTable2 >> 8
                SUB             L
                LD              H,A
                LD              C,(HL)
                INC             HL
                LD              B,(HL)
                INC             HL
                LD              A,(HL)
                RET

        ;; First byte is Y delta, second X, third is reverse lookup?
DirTable2:      DEFB $FF,$00,$0D        ; ~F2
                DEFB $FF,$FF,$09        ; ~F6
                DEFB $00,$FF,$0B        ; ~F4
                DEFB $01,$FF,$0A        ; ~F5
                DEFB $01,$00,$0E        ; ~F1
                DEFB $01,$01,$06        ; ~F9
                DEFB $00,$01,$07        ; ~F8
                DEFB $FF,$01,$05        ; ~FA

UpdateCurrPos:  LD	HL,(CurrObject)
        ;; Fall through

        ;; Takes direction in A.
UpdatePos:      PUSH    HL
                CALL    DirDeltas
        ;; Store the bottom 4 bits of A (dir bitmap) in Object + $0B
                LD      DE,$0B
                POP     HL
                ADD     HL,DE
                XOR     (HL)
                AND     $0F
                XOR     (HL)
                LD      (HL),A
        ;; Update U coordinate with Y delta.
                LD      DE,-$06
                ADD     HL,DE
                LD      A,(HL)
                ADD     A,C
                LD      (HL),A
        ;; Update V coordinate with X delta.
                INC     HL
                LD      A,(HL)
                ADD     A,B
                LD      (HL),A
                RET

;; Takes a pointer in HL to an index which is incremented into a byte
;; array that follows it. Next item is returned in A. Array is
;; terminated with 0, at which point we read the first item
;; again.
ReadLoop:
        ;; On to the next item.
                INC     (HL)
        ;; DE = HL + *HL
                LD      A,(HL)
                ADD     A,L
                LD      E,A
                ADC     A,H
                SUB     E
                LD      D,A
        ;; if (*DE != 0) return
                LD      A,(DE)
                AND     A
                RET     NZ
        ;; Otherwise, go back to the first item:
        ;; *HL = 1 (reset it?) and return *(HL+1)
                LD      (HL),$01
                INC     HL
                LD      A,(HL)
                RET

;; Word version of ReadLoop. Apparently unused?
ReadLoopW:      LD              A,(HL)
                INC             (HL)
        ;; DE = HL + 2 * *HL++
                ADD             A,A
                ADD             A,L
                LD              E,A
                ADC             A,H
                SUB             E
                LD              D,A
        ;; Zero index should be *after* HL, not at HL.
                INC             DE
        ;; Entry is zero? Jump to loop-to-start case.
                LD              A,(DE)
                AND             A
                JR              Z,RLW_1
        ;; Otherwise, return result in DE.
                EX              DE,HL
                LD              E,A
                INC             HL
                LD              D,(HL)
                RET
        ;; Loop-to-start: Set next time to index 1, return first entry.
RLW_1:          LD              (HL),$01
                INC             HL
                LD              E,(HL)
                INC             HL
                LD              D,(HL)
                RET

;; Build-your-own pseudo-random number generator...
Random:         LD      HL,(Rand2)
                LD      D,L
                ADD     HL,HL
                ADC     HL,HL
                LD      C,H
                LD      HL,(Rand1)
                LD      B,H
                RL      B
                LD      E,H
                RL      E
                RL      D
                ADD     HL,BC
                LD      (Rand1),HL
                LD      HL,(Rand2)
                ADC     HL,DE
                RES     7,H
                LD      (Rand2),HL
                JP      M,RND_2
                LD      HL,Rand1
RND_1:          INC     (HL)
                INC     HL
                JR      Z,RND_1
RND_2:          LD      HL,(Rand1)
                RET

Rand1:          DEFW $6F4A
Rand2:          DEFW $216E

	;; Pointer to object in HL
RemoveObject:	PUSH	HL
		PUSH	HL
		PUSH	IY
		PUSH	HL
		POP	IY
		CALL	Unlink
		POP	IY
		POP	HL
		CALL	DrawObject
		POP	IX
		SET	7,(IX+$04)
	;; Transfer top bit of Phase to IX+$0A
		LD	A,(Phase)
		LD	C,(IX+$0A)
		XOR	C
		AND	$80
		XOR	C
		LD	(IX+$0A),A
		RET

DrawObject:     PUSH    IY
        ;; Bump to an obj+2 pointer for call to GetObjExtents2.
                INC     HL
                INC     HL
                CALL    GetObjExtents2
        ;; Move X extent from BC to HL, Y extent from HL to DE.
                EX      DE,HL
                LD      H,B
                LD      L,C
        ;; Then draw where the thing is.
                CALL    CheckAndDraw
                POP     IY
                RET

InsertObject:	PUSH	HL
		PUSH	HL
		PUSH	IY
		PUSH	HL
		POP	IY
		CALL	EnlistAux
		POP	IY
		POP	HL
		CALL	DrawObject
		POP	IX
		RES	7,(IX+$04)
		LD	(IX+$0B),$FF
		LD	(IX+$0C),$FF
		RET
	
#include "sprite_stuff.asm"
	
#include "src/objects/obj_fns.asm"
	
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

#include "src/gfx1/screen_vars.asm"

#include "src/gfx1/blit_screen.asm"

#include "src/gfx1/screen_bits.asm"

#include "controls2.asm"

#include "src/sound/sound48k.asm"

#include "src/gfx1/blit_mask.asm"

#include "src/gfx2/background.asm"

#include "src/gfx1/blit_rot.asm"

#include "src/gfx2/scene.asm"

#include "src/rooms/room_utils.asm"

#include "src/utils/fill_zero.asm"
        
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
LA295:	DEFB $01
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
#insert "img_2x6.bin"

#include "character.asm"

#include "contact.asm"

#include "src/gfx2/get_sprite.asm"

ObjVars:        DEFB $1B                ; Reinitialisation size

                DEFB $00
                DEFW LBA40
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
ObjDest:        DEFW LBA40
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

LAF92:		DEFW LBA40
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

#include "src/objects/procobj.asm"

#include "src/objects/depthcmp.asm"

LB217:		DEFB $00
LB218:		DEFB $00
LB219:		DEFB $00
Dying:		DEFB $00                ; Mask of the characters who are dying
Direction:	DEFB $00

        ;; HL contains an object, A contains a direction
Move:		PUSH	AF
		CALL	GetUVZExtentsE
		EXX
		POP	AF
		LD	(Direction),A
	;; NB: Fall through

        ;; Takes value in A etc. plus extra return value.
DoMove:		CALL	DoMoveAux
		LD	A,(Direction)
		RET

	;; Takes value in A, indexes into table, writes variable, makes call...
DoMoveAux:	LD	DE,PostMove
        ;; Pop this on the stack to be called upon return.
		PUSH	DE
		LD	C,A
		ADD	A,A
		ADD	A,A
		ADD	A,C		; Multiply by 5
		ADD	A,MoveTbl & $FF
		LD	L,A
		ADC	A,MoveTbl >> 8
		SUB	L
		LD	H,A		; Generate index into table
		LD	A,(HL)
		LD	(LB217),A 	; Load first value here
		INC	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)		; Next two in DE
		INC	HL
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A		; Next two in HL
		PUSH	DE
		EXX			; Save regs, and...
		RET			; tail call DE.

PostMove:       EXX
                RET     Z
                PUSH    HL
                POP     IX
                BIT     2,C
                JR      NZ,PM_2
        ;; Object list traversal time!
                LD      HL,ObjectLists
PM_1:           LD      A,(HL)
                INC     HL
                LD      H,(HL)
                LD      L,A
                OR      H
                JR      Z,PM_5
                PUSH    HL
                CALL    DoCopy  ; JP (IX)
                POP     HL
                JR      C,PM_8  ; Found case
                JR      NZ,PM_1 ; Loop case
                JR      PM_5    ; Break case
        ;; Bit 2 of C was set - other object list traversal.
PM_2:           LD      HL,ObjectLists + 2
PM_3:           LD      A,(HL)
                INC     HL
                LD      H,(HL)
                LD      L,A
                OR      H
                JR      Z,PM_4
                PUSH    HL
                CALL    DoCopy  ; JP (IX)
                POP     HL
                JR      C,PM_9  ; Other found case
                JR      NZ,PM_3 ; Loop case
PM_4:           CALL	GetCharObj ; Break case...
                LD      E,L
                JR      PM_6
        ;; Exit point for first loop, line up with exit point for second loop...
PM_5:           CALL    GetCharObj
                LD      E,L
                INC     HL
                INC     HL
        ;; HL points 2 into object
PM_6:           BIT     0,(IY+$09)
                JR      Z,PM_7
                LD      A,YL
                CP      E
                RET     Z
PM_7:           LD      A,(SavedObjListIdx)
                AND     A
                RET     Z
                CALL    DoCopy  ; JP (IX)
                RET     NC
        ;; Adjust pointer and fall through...
                CALL    GetCharObj
                INC     HL
                INC     HL
        ;; Exit point for second loop, adjust to merge with exit point from first...
PM_8:           DEC     HL
                DEC     HL
        ;; FIXME
PM_9:           PUSH    HL
                POP     IX
                LD      A,(LB217)
                BIT     1,(IX+$09) ; Second of double-height character?
                JR      Z,PM_10
        ;; Adjust first, then.
                AND     A,(IX+$0C-18)
                LD      (IX+$0C-18),A
                JR      PM_11
        ;; Otherwise, adjust it.
PM_10:          AND     A,(IX+$0C)
                LD      (IX+$0C),A
        ;; Call "Contact" with $FF in A.
PM_11:          XOR     A
                SUB     $01
        ;; NB: Fall through

;; Handle contact between a pair of objects in IX and IY
Contact:        PUSH	AF
		PUSH	IX
		PUSH	IY
		CALL	ContactAux
		POP	IY
		POP	IX
		POP	AF
		RET

;; IX and IY are both objects, may be characters.
;; Something is in A.
ContactAux:     BIT	0,(IY+$09)
		JR	NZ,CA_1 		; Bit 0 set on IY? Proceed.
		BIT	0,(IX+$09)
		JR	Z,ContactNonChar 	; Bit 0 not set on IX? ContactNonChar instead.
        ;; Swap IY and IX.
		PUSH	IY
		EX	(SP),IX
		POP	IY
        ;; At this point, bit 0 set on IY.
CA_1:		LD	C,(IY+$09) 		; IY's sprite flags in C.
		LD	B,(IY+$04)		; IY's flags in B.
		BIT	5,(IX+$04)              ; Bit 5 not set in IX's flags?
		RET	Z			; Then return.
		BIT	6,(IX+$04)		; Bit 6 set?
		JR	NZ,CollectSpecial       ; CollectSpecial instead, then.
        ;; Return if A is non-zero and bit 4 of IX is set.
		AND	A
		JR	Z,DeadlyContact
		BIT	4,(IX+$09)
		RET	NZ
        ;; NB: Fall through.

;; TODO: Current theory...
;; IY holds character sprite. We've hit a deadly floor or object.
;; C is character's sprite flags (offset 9)
;; B is character's other flags (offset 4)
DeadlyContact:
        ;; If we're double-height (i.e. joined), set bottom two bits
	;; of B and jump.
		BIT	3,B
		LD	B,$03
		JR	NZ,DCO_1
		DEC	B
        ;; Otherwise, if bit 2 of C is set (we're Head), set to 2.
		BIT	2,C
		JR	NZ,DCO_1
        ;; Otherwise (we're Heels), set to 1.
		DEC	B
DCO_1:
        ;; Now clear bits based on invulnerability...
        ;; If Heels is invuln, reset bit 0.
        	XOR	A
		LD	HL,Invuln
		CP	(HL)
		JR	Z,DCO_2
		RES	0,B
DCO_2:		INC	HL
        ;; If Head is invuln, reset bit 1.
		CP	(HL)
		JR	Z,DCO_3
		RES	1,B
        ;; No bits set = invulnerable, so return.
DCO_3:		LD	A,B
		AND	A
		RET	Z
        ;; Update Dying - the mask of which characters should die.
		LD	HL,Dying
		OR	(HL)
		LD	(HL),A
        ;; Another check.
		DEC	HL
		LD	A,(HL)
		AND	A
		RET	NZ
        ;; Return if emperor
		LD	A,(WorldMask)
		CP	$1F
		RET	Z
        ;; Update a thing...
		LD	(HL),$0C
        ;; And do invulnerability if LB218 is non-zero.
		LD	A,(LB218)
		AND	A
		CALL	NZ,BoostInvuln2
		LD	B,$C6
		JP	PlaySound 	; Tail call.

;; Make the special object disappear and call the associated function.
CollectSpecial:
        ;; Set flags etc. for fading
                LD      (IX+$0F),$08
                LD      (IX+$04),$80
        ;; Switch to fade function
                LD      A,(IX+$0A)
                AND     $80
                OR      OBJFN_FADE
                LD      (IX+$0A),A
        ;; Clear special collectable item status.
                RES     6,(IX+$09)
        ;; Extract the item id for the call to GetSpecial.
                LD      A,(IX+$11)
                JP      GetSpecial      ; Tail call

;; Contact between two non-character objects.
ContactNonChar:	BIT		3,(IY+$09)
		JR		NZ,CNC_1
		BIT		3,(IX+$09)
		RET		Z
		PUSH	IY
		POP		IX
        ;; Object in IX has bit 3 of sprite flags set.
        ;; If we're second part of double-height object, find the first part.
CNC_1:		BIT		1,(IX+$09)
		JR		Z,CNC_2
		LD		DE,-18
		ADD		IX,DE
        ;; Return if bit 7 reset
CNC_2:		BIT		7,(IX+$09)
		RET		Z
        ;; Set bit 6, clear movement (?)
		SET		6,(IX+$09)
		LD		(IX+$0B),$FF
		RET

#include "movement.asm"

#include "src/gfx1/print_char.asm"

#include "src/sound/patch.asm"

	;; NB: Not sure what this brief interlude is for!
XB867:	DEFB $F3,$21,$D3,$BD,$11,$00,$40,$01
XB86F:	DEFB $05,$00,$ED,$B0,$11,$00,$5B,$01,$00,$A5,$21,$54,$60,$C3,$00,$40
XB87F:	DEFB $ED,$B0,$C3,$30,$70

#include "src/sound/sound128k.asm"

#include "src/utils/data_space.asm"

#include "data_trailer.asm"

#end
