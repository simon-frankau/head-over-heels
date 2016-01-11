	;; 
	;; HOH.asm
	;;
	;; Main Head Over Heels source file
	;;
	;; Glues together all the other assembly files, binaries, etc.
	;; 

#target ROM
#code 0, $10000
	defs $4000, $00

#insert "screen.scr"

#include "room_data.asm"

	;; Hack, should be removed.
#include "equs.asm"

MAGIC_OFFSET:	EQU 360 	; The offset high data is moved down by...
	
ViewBuff:	EQU $B800

	;; The buffer into which we draw the columns doors stand on
ColBuf:		EQU $F944
ColBufLen:	EQU $94

DoorwayBuf:	EQU $F9D8

#include "mainloop.asm"
        
C72A0:	XOR		A
		JR		L72A9
C72A3:	LD		A,$FF
		LD		HL,L7305
		PUSH	HL
L72A9:	LD		HL,L7355
		LD		DE,L72EB
		JR		L72BC
L72B1:	XOR		A
		LD		HL,L7B78
		PUSH	HL
		LD		HL,L734B
		LD		DE,L72F3
L72BC:	PUSH	DE
		LD		(L7348+1),HL
		CALL	C7314
		LD		(L72F0),HL
		AND		A
		LD		HL,LFB28
		JR		NZ,L72CD
		EX		DE,HL
L72CD:	EX		AF,AF'
		CALL	C7321
		INC		B
		NOP
		DEC		SP
		LD		(HL),B
		CALL	C7321
		DEC		E
		NOP
		LD		(HL),A
		XOR		A
		CALL	C7321
		ADD		HL,DE
		NOP
		AND		D
		AND		D
		CALL	C7321
		RET		P
		INC		BC
		LD		B,B
		CP		D
		RET
L72EB:	CALL	C7321
		LD		(DE),A
		NOP			
L72F0:		RET		NZ 		; Self-modifying code
		AND		D
		RET
L72F3:	PUSH	DE
		CALL	GetCharObj
		EX		DE,HL
		LD		BC,L0012
		PUSH	BC
		LDIR
		CALL	C7314
		POP		BC
		POP		DE
		LDIR
L7305:		LD		HL,(LAF92) 	; NB: Referenced as data.
		LD		(ObjDest),HL
		LD		HL,ObjList5
		LD		BC,L0008
		JP		FillZero
	
C7314:		LD		HL,Character
		BIT		0,(HL) 		; Heels?
		LD		HL,HeelsObj	; No Heels case
		RET		Z
		LD		HL,HeadObj 	; Have Heels case
		RET

C7321:	POP		IX
		LD		C,(IX+$00)
		INC		IX
		LD		B,(IX+$00)
		INC		IX
		EX		AF,AF'
		AND		A
		JR		Z,L733B
		LD		E,(IX+$00)
		INC		IX
		LD		D,(IX+$00)
		JR		L7343
L733B:	LD		L,(IX+$00)
		INC		IX
		LD		H,(IX+$00)
L7343:	INC		IX
		EX		AF,AF'
		PUSH	IX
L7348:	JP		L7355	; Self-modifying code
L734B:	LD		A,(DE)
		LDI
		DEC		HL
		LD		(HL),A
		INC		HL
		JP		PE,L734B
		RET
L7355:	LDIR
		RET
C7358:	XOR		A
		RET

	;; Installs the interrupt hook
IrqInstall:	DI
		IM	2
		LD	A,$39		; Page full of FFhs.
		LD	I,A
		LD	A,$18
		LD	(LFFFF),A 	; JR 0xFFF4
		LD	A,$C3		; JP ...
		LD	($FFF4),A
		LD	HL,IrqHandler 	; to IrqHandler
		LD	(LFFF5),HL
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
	
C7395:		LD	A,$08
		CALL	SetAttribs 	; Set all black attributes
		LD	HL,L4048
		LD	DE,L4857
L73A0:		PUSH	HL
		PUSH	DE
		CALL	CheckYAndDraw
		POP	DE
		POP	HL
		LD	H,L
		LD	A,L
		ADD	A,$14
		LD	L,A
		CP	$C1
		JR	C,L73A0
		LD	HL,L4048
		LD	D,E
		LD	A,E
		ADD	A,$2A
		LD	E,A
		JR	NC,L73A0
		RET

#include "attr_scheme.asm"
	
CHAR_ARR1:	EQU $21
CHAR_ARR2:	EQU $22
CHAR_ARR3:	EQU $23
CHAR_ARR4:	EQU $24
CHAR_LIGHTNING:	EQU $25
CHAR_SPRING:	EQU $26
CHAR_SHIELD:	EQU $27
	
	;; Look up character code (- 0x20 already) to a pointer to the character in DE.
CharCodeToAddr:	CP	$08
		JR	C,CC2A 		; Space ! " # $ % & '
		SUB	$07
		CP	$13
		JR	C,CC2A		; / 0-9
		SUB	$07 		; Alphabetical characters.
CC2A:		ADD	A,A
		ADD	A,A
		LD	L,A
		LD	H,$00
		ADD	HL,HL
		LD	DE,IMG_CHARS - 360
		ADD	HL,DE
		EX	DE,HL
		RET

#include "controls.asm"

	;; In multiples of 6, apparently half the pixel height.
ColHeight:	DEFB $00

	;; Re-fills the column sprite buffer.
FillColBuf:	PUSH	DE
		PUSH	BC
		PUSH	HL
		LD	A,(ColHeight)
		CALL	DrawColBuf
		POP	HL
		POP	BC
		POP	DE
		RET

	;; Pass the column height in A, redraws the column, returns result in DE.
SetColHeight:	LD	(ColHeight),A
	;; NB: Fall through!
	
DrawColBuf:	PUSH	AF
	;; Clear out buffer
		LD	HL,ColBuf
		LD	BC,ColBufLen
		CALL	FillZero
	;; Drawing buffer, reset flip flag.
		XOR	A
		LD	(IsColBufFlipped),A
	;; And set the 'filled' lag.
		DEC	A
		LD	(IsColBufFilled),A
		POP	AF
	;; Zero height? Draw nothing
		AND	A
		RET	Z
	;; Otherwise, draw in reverse from end of buffer...
		LD	DE,ColBuf + ColBufLen - 1
		PUSH	AF
		CALL	DrawColBottom
DrawColLoop:	POP	AF
		SUB	$06
		JR	Z,DrawColTop
		PUSH	AF
		CALL	DrawColMid
		JR	DrawColLoop

DrawColTop:	LD	HL,IMG_ColTop + $23 - MAGIC_OFFSET
		LD	BC,$24
		JR	DrawColLDDR

DrawColMid:	LD	HL,IMG_ColMid + $17 - MAGIC_OFFSET
		LD	BC,L0018
		JR	DrawColLDDR

DrawColBottom:	LD	HL,IMG_ColBottom + $0F - MAGIC_OFFSET
		LD	BC,L0010

DrawColLDDR:	LDDR
		RET

        ;; Pointer into stack for current origin coordinates
DecodeOrgPtr:	DEFW L76E0
L76E0:	DEFB $00
L76E1:	DEFB $00
L76E2:	DEFB $00
L76E3:	DEFB $00
L76E4:	DEFB $00
L76E5:	DEFB $00
L76E6:	DEFB $00
L76E7:	DEFB $00
L76E8:	DEFB $00
L76E9:	DEFB $00
L76EA:	DEFB $00
L76EB:	DEFB $00
L76EC:	DEFB $00
L76ED:	DEFB $00

        ;; Buffer for an object used during unpacking
TmpObj:	DEFB $00,$00,$00,$00,$00,$00,$00,$00
	DEFB $00,$00,$00,$FF,$FF,$00,$00,$00
        DEFB $00,$00

UnpackFlags:	DEFB $00

	;; Current pointer to bit-packed data
DataPtr:	DEFW $0000
	;; The remaining bits to read at the current address.
CurrData:	DEFB $00

	;; FIXME: Decode remaining DataPtr/CurrData references...
	
ExpandDone:	DEFB $00
L7705:	DEFB $00
L7706:	DEFB $00
L7707:	DEFB $27
L7708:	DEFB $26
L7709:	DEFB $17
L770A:	DEFB $15
L770B:	DEFB $05
L770C:	DEFB $04
L770D:	DEFB $36
L770E:	DEFB $34
DoorwayTest:	DEFB $00
L7710:	DEFB $00
FloorCode:	DEFB $00
L7712:	DEFB $00
        ;; Do we skip processing the objects?
SkipObj:	DEFB $00
AttribScheme:	DEFB $00
WorldId:	DEFB $00	; Range 0..7 (I think 7 is 'same as last')
L7716:	DEFB $00
L7717:	DEFB $00
L7718:	DEFB $00
L7719:	DEFB $00
L771A:	DEFB $00
L771B:	DEFB $00
L771C:	DEFB $00
L771D:	DEFB $00
L771E:	DEFB $00
L771F:	DEFB $00
L7720:	DEFB $00
L7721:	DEFB $00
L7722:	DEFB $00
L7723:	DEFB $00

L7724:	DEFB $08,$08,$48,$48
	DEFB $08,$10,$48,$40
	DEFB $08,$18,$48,$38
	DEFB $08,$20,$48,$30
	DEFB $10,$08,$40,$48
	DEFB $18,$08,$38,$48
	DEFB $20,$08,$30,$48
	DEFB $10,$10,$40,$40

L7744:	DEFB $00
L7745:	DEFB $00
L7746:	DEFB $00
L7747:	DEFB $00
L7748:	DEFB $00
L7749:	DEFB $00
L774A:	DEFB $00
L774B:	DEFB $00
L774C:	DEFB $C0
C774D:		LD		A,$FF
		LD		(SkipObj),A
	;; NB: Fall through

	;; Guess that this is redraw screen, based on setting sprite extend to full screen...
DrawScreen:	LD	IY,L7718 		; FIXME: ???
	;; Initialise the sprite extents to cover the full screen.
		LD	HL,L40C0
		LD	(ViewXExtent),HL
		LD	HL,L00FF
		LD	(ViewYExtent),HL
	;;  FIXME: ???
		LD	HL,LC0C0
		LD	(L7748),HL
		LD	(L774A),HL
		LD	HL,L0000
		LD	BC,(RoomId)
		CALL	EnterRoom
		XOR	A
		LD	(SkipObj),A
		LD	(L774C),A
		LD	HL,(ObjDest)
		LD	(LAF92),HL
		LD	A,(L7710)
		LD	(DoorwayTest),A
		LD	DE,L7744
		LD	HL,L7748
		LD	BC,L0004
		LDIR
	;; Clear the backdrop info...
		LD	HL,BkgndData
		LD	BC,L0040
		CALL	FillZero
		CALL	CA260
		CALL	SomeExport
		LD		A,$00
		RLA
		LD		(L7712),A
		CALL	C84CB
		LD		HL,(L7716)
		PUSH	HL
		LD		A,L
		AND		$08
		JR		Z,L77D0
		LD		A,$01
		CALL	CAF96
		LD		BC,(RoomId)
		LD		A,B
		INC		A
		XOR		B
		AND		$0F
		XOR		B
		LD		B,A
		LD		A,(L771B)
		LD		H,A
		LD		L,$00
		CALL	EnterRoom
		CALL	CA260
L77D0:	LD		IY,L7720
		POP		HL
		PUSH	HL
		LD		A,L
		AND		$04
		JR		Z,L77F8
		LD		A,$02
		CALL	CAF96
		LD		BC,(RoomId)
		LD		A,B
		ADD		A,$10
		XOR		B
		AND		$F0
		XOR		B
		LD		B,A
		LD		A,(L771A)
		LD		L,A
		LD		H,$00
		CALL	EnterRoom
		CALL	CA260
L77F8:		LD	A,(L774C)
		LD	HL,(L7705)
		PUSH	AF
		CALL	OccludeDoorway
		POP	AF
		CALL	SetColHeight
		POP	HL
		LD	(L7716),HL
		XOR	A
		JP	CAF96

#include "procdata.asm"

InitStuff:	CALL	IrqInstall
		JP	InitRevTbl

InitNewGame:	XOR	A
		LD	(WorldMask),A
		LD	(LB218),A
		LD	(Continues),A
		LD	A,$18
		LD	(LA2C8),A
		LD	A,$1F
		LD	(LA2DA),A
		CALL	InitNewGame1
		CALL	Reinitialise
		DEFW	StatusReinit
		CALL	InitNewGame2
		LD	HL,L8940
		LD	(RoomId),HL
		LD	A,$01
		CALL	C7B43
		LD	HL,L8A40
		LD	(RoomId),HL
		XOR	A
		LD	(LB218),A
		RET

C7B43:		LD	(Character),A
		PUSH	AF
		LD	(LFB28),A
		CALL	C7BBF
		XOR	A
		LD	(LA297),A
		CALL	CharThing15
		JR	L7B59		; Tail call

L7B56:		CALL	CharThing
L7B59:		LD	A,(LA2BC)
		AND	A
		JR	NZ,L7B56
		POP	AF
		XOR	$03
		LD	(Character),A
		CALL	CharThing3
		JP	C72A0		; Tail call

InitContinue:	CALL	Reinitialise
		DEFW	StatusReinit
		LD	A,$08
		CALL	UpdateAttribs	; Blacked-out attributes
		JP	DoContinue	; Tail call

L7B78:		CALL	C774D
		CALL	Reinitialise
		DEFW	ReinitThing
		CALL	SetCharThing
		CALL	C7C1A
		CALL	C7395
		XOR	A
		LD	(LA295),A
		JR	C7BB3		; Tail call

L7B8F:	DEFB $00
WorldIdSnd:	DEFB $00

	;; NB: Called from main loop...
C7B91:		CALL	C7BBF
		LD	A,(MENU_SOUND)
		AND	A
		JR	NZ,L7BAD
		LD	A,(WorldId)
		CP	$07
		JR	NZ,L7BA4
		LD	A,(WorldIdSnd)
L7BA4:		LD	(WorldIdSnd),A
		OR	$40
		LD	B,A
		CALL	PlaySound
L7BAD:		CALL	C7395
		CALL	CharThing15
	;; NB: Fall through

C7BB3:		LD	A,(AttribScheme)
		CALL	UpdateAttribs
		CALL	PrintStatus
		JP	DrawScreenPeriphery		; Tail call

C7BBF:		CALL	Reinitialise
		DEFW	LAF5B
		CALL	Reinitialise
		DEFW	ReinitThing
		LD	A,(Character)
		CP	$03
		JR	NZ,L7BDC
		LD	HL,LFB28
		SET	0,(HL)
		CALL	DrawScreen
		LD	A,$01
		JR	L7C14
L7BDC:		CALL	C728C
		JR	NZ,L7C10
		CALL	C72A3
		CALL	C774D
		LD	HL,HeelsObj
		CALL	GetUVZExtents
		EXX
		LD	HL,HeadObj
		CALL	GetUVZExtents
		CALL	CheckOverlap
		JR	NC,L7C0C
		LD	A,(Character)
		RRA
		JR	C,L7C00
		EXX
L7C00:		LD	A,B
		ADD	A,$05
		EXX
		CP	B
		JR	C,L7C0C
		LD	A,$FF
		LD	(L7B8F),A
L7C0C:		LD	A,$01
		JR	L7C14
L7C10:		CALL	DrawScreen
		XOR	A
L7C14:		LD	(LA295),A
		JP	C7C1A


	;;    ^
	;;   / \
	;;  /   \
	;; H     L
	
C7C1A:		LD	HL,(L7718)
		LD	A,(L7717)
		PUSH	AF
		BIT	1,A
		JR	Z,L7C29
		DEC	H
		DEC	H
		DEC	H
		DEC	H
L7C29:		RRA
		LD		A,L
		JR		NC,L7C30
		SUB		$04
		LD		L,A
L7C30:		SUB		H
	;; X coordinate of the play area bottom corner is in A.
	;; 
	;; We write out the corner position, and the appropriate
	;; overall vertical adjustments.
		ADD		A,$80
		LD		(CornerPos+1),A
		LD		C,A
		LD		A,$FC
		SUB		H
		SUB		L
		LD		B,A			; B = $FC - H - L
		NEG
		LD		E,A			; E = H + L - $FC
		ADD		A,C 			; 
		LD		(LeftAdj+1),A		; E + CornerPos
		LD		A,C
		NEG
		ADD		A,E
		LD		(RightAdj+1),A 		; E - CornerPos
	;; FIXME: Next bit.
		CALL		FloorFn
		POP		AF
		RRA
		PUSH		AF
		CALL		NC,NukeColL
		POP		AF
		RRA
		RET		C
	;; Scan from the right for the first drawn column
		LD	HL,BkgndData + 31*2
ScanR:		LD	A,(HL)
		AND	A
		JR	NZ,NukeCol
		DEC	HL
		DEC	HL
		JR	ScanR

	;; If the current screen column sprite isn't a door column, delete it.
NukeCol:	INC	HL
		LD	A,(HL)
		OR	~5
		INC	A
		RET	NZ
		LD	(HL),A
		DEC	HL
		LD	(HL),A
		RET

	;; Scan from the left for the first drawn column
NukeColL:	LD	HL,BkgndData
ScanL:		LD	A,(HL)
		AND	A
		JR	NZ,NukeCol
		INC	HL
		INC	HL
		JR	ScanL

	;; A funky shuffle routine: Load a pointer from the top of stack.
	;; (i.e. our return address contains data to skip over)
	;; The pointed value points to a size. We copy that much data
	;; from directly after it to a size later.
	;; i.e. 5 A B C D E M N O P Q becomes 5 A B C D E A B C D E.
	;; Useful for reinitialising structures.
Reinitialise:
	;; Dereference top of stack into HL, incrementing pointer
		POP	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		INC	HL
		PUSH	HL
		EX	DE,HL
	;; Dereference /that/ into bottom of BC
		LD		C,(HL)
		LD		B,$00
	;; Then increment HL and set DE = HL + BC
		INC		HL
		LD		D,H
		LD		E,L
		ADD		HL,BC
		EX		DE,HL
	;; Finally LDIR
		LDIR
		RET
	
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

CurrObject:	DEFW $0000
ObjDir: 	DEFB $FF
L822E:	DEFW $3D00,$3D8E

ProcDataStart:	LD		(IY+$09),$00
		LD		L,A
		LD		E,A
		LD		D,$00
		LD		H,D
		ADD		HL,HL
		ADD		HL,DE
		LD		DE,L8406
		ADD		HL,DE
		LD		B,(HL)
		INC		HL
		LD		A,(HL)
		AND		$3F
		LD		(IY+$0A),A
		LD		A,(HL)
		INC		HL
		RLCA
		RLCA
		AND		$03
		JR		Z,L8264
		ADD		A,L822E & $FF
		LD		E,A
		ADC		A,L822E >> 8
		SUB		E
		LD		D,A
		LD		A,(DE)
		SET		5,(IY+$09)
		BIT		2,(HL)
		JR		Z,L8264
		LD		C,B
		LD		B,A
		LD		A,C
L8264:		LD		(L822E),A
		LD		A,B
		CALL	C828B
		LD		A,(HL)
		OR		$9F
		INC		A
		LD		A,(HL)
		JR		NZ,L8278
		SET		7,(IY+$09)
		AND		$BF
L8278:		AND		$FB
		CP		$80
		RES		7,A
		LD		(IY-$01),A
		LD		(IY-$02),$02
		RET		C
		SET		4,(IY+$09)
		RET
C828B:		LD		(IY+$0F),$00
		LD		(IY+$08),A
		CP		$80
		RET		C
		ADD		A,A
		ADD		A,A
		ADD		A,A
		LD		(IY+$0F),A
		PUSH	HL
		CALL	C82E8
		POP		HL
		RET

	;; Takes an object pointer in DE, and index thing in A
CallObjFn:	LD	(CurrObject),DE
		PUSH	DE
		POP	IY
		DEC	A
	;; Get word from ObjFnTbl[A] into HL.
		ADD	A,A
		ADD	A, ObjFnTbl & $FF
		LD	L,A
		ADC	A,ObjFnTbl >> 8
		SUB	L
		LD	H,A
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
	;; Do some stuff...
		XOR	A
		LD	(L8ED8),A
		LD	A,(IY+$0B)
		LD	(ObjDir),A
		LD	(IY+$0B),$FF
		BIT	6,(IY+$09)
		RET	NZ
	;; And function table jump
		JP	(HL)

C82C9:		BIT		5,(IY+$09)
		JR		Z,C82E8
		CALL	C82E8
		EX		AF,AF'
		LD		C,(IY+$10)
		LD		DE,L0012
		PUSH	IY
		ADD		IY,DE
		CALL	C938D
		CALL	C82E8
		POP		IY
		RET		C
		EX		AF,AF'
		RET
	
C82E8:		LD		C,(IY+$0F)
		LD		A,C
		AND		$F8
		CP		$08
		CCF
		RET		NC
		RRCA
		RRCA
		SUB		$02
		ADD		A,$30
		LD		L,A
		ADC		A,$83
		SUB		L
		LD		H,A
		LD		A,C
		INC		A
		AND		$07
		LD		B,A
		ADD		A,(HL)
		LD		E,A
		INC		HL
		ADC		A,(HL)
		SUB		E
		LD		D,A
		LD		A,(DE)
		AND		A
		JR		NZ,L8313
		LD		B,$00
		LD		A,(HL)
		DEC		HL
		LD		L,(HL)
		LD		H,A
		LD		A,(HL)
L8313:		LD		(IY+$08),A
		LD		A,B
		XOR		C
		AND		$07
		XOR		C
		LD		(IY+$0F),A
		AND		$F0
		CP		$80
		LD		C,$02
		JR		Z,L832A
		CP		$90
		LD		C,$01
L832A:		LD		A,C
		CALL		Z,SetSound
		SCF
		RET
L8330:	DEFB $6E,$83,$73,$83,$75,$83,$77,$83,$77,$83,$7C,$83,$7C,$83,$81,$83
L8340:	DEFB $81,$83,$84,$83,$84,$83,$8A,$83,$8F,$83,$94,$83,$94,$83,$9B,$83
L8350:	DEFB $9D,$83,$9F,$83,$9F,$83,$A4,$83,$A4,$83,$A7,$83,$A9,$83,$AB,$83
L8360:	DEFB $AD,$83,$AF,$83,$B1,$83,$B3,$83,$B5,$83,$B7,$83,$B7,$83,$A4,$24
L8370:	DEFB $25,$26,$00,$10,$00,$11,$00,$24,$25,$25,$24,$00,$2D,$2D,$2E,$2E
L8380:	DEFB $00,$57,$D7,$00,$2B,$2B,$2C,$2B,$2C,$00,$32,$32,$33,$33,$00,$34
L8390:	DEFB $34,$35,$35,$00,$26,$25,$26,$A6,$A5,$A6,$00,$36,$00,$37,$00,$38
L83A0:	DEFB $39,$B9,$B8,$00,$3A,$BA,$00,$3B,$00,$3C,$00,$3E,$00,$3F,$00,$40
L83B0:	DEFB $00,$41,$00,$42,$00,$43,$00,$44,$45,$C5,$C4,$00

	;; Table has base index of 1 in CallObjFn
ObjFnTbl:
	DEFW ObjFn1, ObjFn2, ObjFn3, ObjFn4
	DEFW ObjFn5, ObjFn6, ObjFn7, ObjFn8
	DEFW ObjFn9, ObjFn10,ObjFn11,ObjFn12
	DEFW ObjFn13,ObjFn14,ObjFn15,ObjFn16
	DEFW ObjFn17,ObjFn18,ObjFn19,ObjFn20
	DEFW ObjFn21,ObjFn22,ObjFn23,ObjFn24
	DEFW ObjFnFire,ObjFn26,ObjFn27,ObjFn28
	DEFW ObjFn29,ObjFn30,ObjFn31,ObjFn32
	DEFW ObjFn33,ObjFn34,ObjFn35,ObjFn36
	DEFW ObjFn37

L8406:	DEFB $88,$1B,$01,$2B,$1C,$40,$31,$00,$02,$4A
L8410:	DEFB $01,$40,$9E,$17,$00,$5D,$00,$01,$56,$02,$11,$56,$03,$11,$56,$04
L8420:	DEFB $01,$56,$05,$01,$46,$01,$40,$4B,$01,$40,$90,$8F,$6C,$4C,$0A,$00
L8430:	DEFB $58,$00,$21,$5E,$00,$21,$30,$0E,$00,$94,$09,$60,$96,$4F,$6C,$9A
L8440:	DEFB $DD,$0C,$49,$1E,$00,$5A,$01,$01,$5F,$00,$01,$5F,$14,$01,$48,$00
L8450:	DEFB $00,$92,$0B,$60,$31,$18,$02,$82,$06,$68,$84,$CC,$6C,$47,$0A,$20
L8460:	DEFB $5C,$1F,$01,$55,$15,$01,$96,$CD,$6C,$5B,$00,$21,$5D,$14,$01,$59
L8470:	DEFB $14,$01,$59,$00,$01,$3D,$20,$60,$92,$21,$60,$9E,$12,$00,$55,$01
L8480:	DEFB $01,$5F,$13,$01,$8C,$07,$60,$5A,$16,$01,$5D,$08,$01,$55,$23,$01
L8490:	DEFB $9C,$CD,$6C,$42,$00,$20,$47,$0A,$00,$2D,$00,$20,$56,$14,$01,$5D
L84A0:	DEFB $0A,$01,$5D,$01,$01,$98,$4F,$6C,$98,$CD,$6C,$82,$08,$68,$36,$00
L84B0:	DEFB $20,$37,$00,$20,$1E,$00,$00,$18,$00,$00,$4C,$24,$00,$4C,$A5,$2C
L84C0:	DEFB $84,$21,$60
PanelBase:	DEFW $0000
PanelFlipsPtr:	DEFW $0000	; Pointer to byte full of whether panels need to flip
L84C7:	DEFB $00
L84C8:	DEFB $00
L84C9:	DEFB $00
L84CA:	DEFB $00
C84CB:	CALL	C8603
		LD		A,C
		SUB		$06
		LD		C,A
		ADD		A,B
		RRA
		LD		(L84C7),A
		LD		A,B
		NEG
		ADD		A,C
		RRA
		LD		(L84C8),A
		LD		A,B
		LD		(L84C9),A
		RET
	
L84E4:		LD	(L84CA),A
		CALL	C8506
		LD	A,(L7716)
		AND	$04
		RET	NZ
		LD	B,$04
		EXX
		LD	A,$80
		LD	(L8591+1),A
		CALL	C8603
		LD	DE,L0002
		LD	A,(IY-$01)
		SUB	(IY-$03)
		JR	L8521
C8506:		LD	A,(L7716)
		AND	$08
		RET	NZ
		LD	B,$08
		EXX
		XOR	A
		LD	(L8591+1),A
		CALL	C8603
		DEC	L
		DEC	L
		LD	DE,LFFFE
		LD	A,(IY-$02)
		SUB	(IY-$04)
	;; NB: Fall through

L8521:		RRA
		RRA
		RRA
		RRA
		AND	$0F
		PUSH	HL
		POP	IX
		EXX
		LD	C,A
		LD	A,(L7717)
		AND	B
		CP	$01
		EX	AF,AF'
	;; WorldId-based configuration...
		LD	A,(WorldId)
		LD	B,A
	;; Put $C038 + WorldId into $84C5.
		ADD	A,$38
		LD	L,A
		ADC	A,$C0
		SUB	L
		LD	H,A
		LD	(PanelFlipsPtr),HL
	;; We use the FetchData mechanism to unpack the WorldData. Set it up.
		LD	A,B
		ADD	A,A
		LD	B,A 		; B updated to 2x
		ADD	A,A
		ADD	A,A   		; A is 8x
		ADD	A,+((WorldData - 1) & $FF)
		LD	L,A
		ADC	A,+((WorldData - 1) >> 8)
		SUB	L
		LD	H,A   		; HL is WorldData - 1 + 8xWorldId
		LD	(DataPtr),HL
		LD	A,$80
		LD	(CurrData),A
	;; Update PanelBase
		LD	A,$1B
		ADD	A,B
		LD	L,A
		ADC	A,$86
		SUB	L
		LD	H,A 		; HL is $861B (aka PanelBases) + 2xWorldId
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		LD	(PanelBase),HL	; Set the panel codes for the current world.
	;; FIXME
		LD	A,$FF
		EX	AF,AF'
		LD	A,C
		PUSH	AF
		SUB	$04
		LD	B,$01
		JR	Z,L857B
		LD	B,$0F
		INC	A
		JR	Z,L857B
		LD	B,$19
		INC	A
		JR	Z,L857B
		LD	B,$1F
L857B:		POP	AF
		JR	C,L8584
		LD	A,C
		ADD	A,A
		ADD	A,B
		LD	B,A
		LD	A,C
		EX	AF,AF'
L8584:		CALL	FetchData2b
		DJNZ	L8584
		LD	B,C
		SLA	B
L858C:		EX	AF,AF'
		DEC	A
		JR	Z,L85C2
		EX	AF,AF'
L8591:		OR	$00	; NB: Target of self-modifying code.
		LD	(IX+$01),A
		EXX
		LD	A,C
		ADD	A,$08
		LD	(IX+$00),C
		LD	C,A
		ADD	IX,DE
		EXX
		CALL	FetchData2b
L85A4:		DJNZ	L858C
		EXX
		PUSH	IX
		POP	HL
		LD	A,L
		CP	$40
		RET	NC
		LD	A,(IX+$00)
		AND	A
		RET	NZ
		LD	A,(L8591+1)
		OR	$05
		LD	(IX+$01),A
		LD	A,C
		SUB	$10
		LD	(IX+$00),A
		RET
L85C2:		EXX
		LD	A,(L84CA)
		AND	A
		LD	A,C
		JR	Z,L85CD
		ADD	A,$10
		LD	C,A
L85CD:		SUB	$10
		LD	(IX+$00),A
		LD	A,(L8591+1)
		OR	$04
		LD	(IX+$01),A
		ADD	IX,DE
		LD	(IX+$01),A
		LD	A,C
		SUB	$08
		LD	(IX+$00),A
		ADD	A,$18
		LD	C,A
		LD	A,(L84CA)
		AND	A
		JR	Z,L85F2
		LD	A,C
		SUB	$10
		LD	C,A
L85F2:		ADD	IX,DE
		LD	A,$FF
		EX	AF,AF'
		EXX
		DEC	B
		JR	L85A4

	;; Call FetchData for 2 bits
FetchData2b:	PUSH	BC
		LD	B,$02
		CALL	FetchData
		POP	BC
		RET

C8603:	LD		A,(IY-$02)
		LD		D,A
		LD		E,(IY-$01)
		SUB		E
		ADD		A,$80
		LD		B,A
		RRA
		RRA
		AND		$3E
		LD		L,A
		LD		H,BkgndData >> 8
		LD		A,$07
		SUB		E
		SUB		D
		LD		C,A
		RET

PanelBases:	DEFW $C050,$C1A0,$C2F0,$C3D0,$C4B0,$C670,$C750,$C8A0
	;; 8-byte chunks referenced by setting DataPtr etc.
        ;; Consists of packed 2-bit values.
WorldData:	DEFB $46,$91,$65,$94,$A1,$69,$69,$AA
		DEFB $49,$24,$51,$49,$12,$44,$92,$A4
		DEFB $04,$10,$10,$41,$04,$00,$44,$00
		DEFB $04,$10,$10,$41,$04,$00,$10,$00
		DEFB $4E,$31,$B4,$E7,$4E,$42,$E4,$99
		DEFB $45,$51,$50,$51,$54,$55,$55,$55
		DEFB $64,$19,$65,$11,$A4,$41,$28,$55
		DEFB $00,$00,$00,$00,$00,$00,$00,$00
        ;; Bit mask of worlds visited.
WorldMask:	DEFB $00
L866C:	DEFB $70,$14,$00,$72,$60,$30,$01,$40,$B0,$2E,$09,$34,$B0,$00,$1A
L867B:	DEFB $00,$F0,$9A,$0B,$70,$40,$A7,$1C,$44,$30,$37,$7D,$37,$70,$15,$68
L868B:	DEFB $34,$60,$89,$48,$47,$60,$C5,$68,$76,$80,$1B,$68,$76,$D0,$BC,$28
L869B:	DEFB $35,$D0,$1C,$28,$71,$F0,$87,$38,$74,$20,$FB,$28,$71,$60,$31,$48
L86AB:	DEFB $05,$C0,$E2,$38,$54,$20,$69,$68,$07,$60,$52,$62,$77,$60,$47,$72
L86BB:	DEFB $27,$C0,$E3,$42,$07,$F0,$63,$12,$70,$20,$AA,$22,$05,$30,$6C,$22
L86CB:	DEFB $46,$60,$47,$73,$57,$80,$FA,$63,$67,$F0,$70,$13,$60,$10,$7B,$73
L86DB:	DEFB $31,$60,$64,$74,$70,$80,$1A,$44,$45,$F0,$46,$74,$74,$60,$C5,$66
L86EB:	DEFB $74,$70,$98,$76,$00,$00,$32,$76,$50,$80,$29,$76,$40,$A0,$E0,$16
L86FB:	DEFB $40,$A0,$0F,$66,$47,$B0,$03,$26,$44,$F0,$83,$36,$17,$40,$8A,$06
L870B:	DEFB $06,$20,$99,$76,$14,$60,$C5,$65,$75,$60,$77,$75,$44,$00,$36,$75
L871B:	DEFB $66,$A0,$FE,$75,$22,$F0,$42,$65,$61,$20,$AE,$75,$04
L8728:	DEFB $30,$8D,$7E
L872B:	DEFB $47,$30,$8D,$6E,$17,$30,$8D,$7E,$07,$30,$8D,$6E,$37,$30,$8D,$3E
L873B:	DEFB $27,$27,$28,$29,$2A,$2A,$2A,$2A,$00,$86,$2F,$2F,$2F,$2F,$2F,$2F

C874B:	LD		BC,(RoomId)
C874F:	LD		HL,L866C
		LD		E,$34
L8754:	LD		A,C
		CP		(HL)
		INC		HL
		JR		NZ,C875C
		LD		A,B
		CP		(HL)
		RET		Z
C875C:	INC		HL
		INC		HL
		INC		HL
		DEC		E
		JR		NZ,L8754
		DEC		E
L8763:		RET		; FIXME: Self-modifying code??
C8764:	INC		HL
		XOR		A
		RLD
		LD		E,A
		RLD
		LD		D,A
		RLD
		INC		HL
		RLD
		LD		B,A
		RLD
		LD		C,A
		RLD
		RET

BPDEnd:		PUSH	BC
		LD		HL,L8728
		LD		A,(WorldMask)
		CPL
		LD		B,$05
		LD		DE,L0004
BPDE1:		RR		(HL)
		RRA
		RL		(HL)
		ADD		HL,DE
		DJNZ	BPDE1
		POP		BC
		CALL	C874F
BPDE2:		RET		NZ
		PUSH	HL
		PUSH	DE
		PUSH	BC
		PUSH	IY
		CALL	C8764
		LD		IY,TmpObj
		LD		A,D
		CP		$0E
		LD		A,$60
		JR		NZ,BPDE3
		XOR		A
BPDE3:		LD		(IY+$04),A
		LD		(IY+$11),D
		LD		(IY+$0A),$1A
		LD		A,D
		ADD		A,$3C
		LD		L,A
		ADC		A,$87
		SUB		L
		LD		H,A
		LD		A,(HL)
		PUSH	BC
		PUSH	DE
		CALL	C828B
		POP		DE
		POP		BC
		POP		IY
		LD		A,E
		CALL	SetTmpObjUVZ
		CALL	ProcTmpObj
		POP		BC
		POP		DE
		POP		HL
		CALL	C875C
		JR		BPDE2

InitNewGame2:	LD		HL,L866C
		LD		DE,L0004
		LD		B,$34
L87D9:	RES		0,(HL)
		ADD		HL,DE
		DJNZ	L87D9
		RET
L87DF:	LD		D,A
		CALL	C874B
L87E3:	RET		NZ
		INC		HL
		LD		A,(HL)
		DEC		HL
		AND		$0F
		CP		D
		JR		Z,L87F1
		CALL	C875C
		JR		L87E3
L87F1:	DEC		HL
		SET		0,(HL)
		ADD		A,A
		ADD		A,$0A
		LD		L,A
		ADC		A,$88
		SUB		L
		LD		H,A
		LD		E,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,E
		LD		IX,L8805
		JP		(HL)
L8805:		LD		B,$C5 ; Self-modifying code?
		JP		PlaySound
L880A:	LD		H,$88
		LD		H,$88
		DEC		(HL)
		ADC		A,B
		LD		B,H
		ADC		A,B
		LD		C,L
		ADC		A,B
		LD		E,C
		ADC		A,B
		LD		E,L
		ADC		A,B
		NOP
		NOP
		AND		(HL)
		ADC		A,B
		SUB		L
		ADC		A,B
		SUB		L
		ADC		A,B
		SUB		L
		ADC		A,B
		SUB		L
		ADC		A,B
		SUB		L
		ADC		A,B
		LD		A,D
	;; NB: Fall through

	;; Pick up an inventory item. Item number in A.
PickUp:		LD	HL,Inventory
		CALL	SetBit
		CALL	DrawScreenPeriphery
		LD	B,$C2
		JP	PlaySound

#include "status.asm"
	
L8ADC:	DEFB $00,$00
L8ADE:	DEFB $00
L8ADF:	DEFB $00,$00,$00

NUM_ROOMS:      EQU 301
RoomMask:       DEFS NUM_ROOMS, $00

;; Clear donut count and then count number of inventory items we have
EmptyDonuts:    LD      HL,Inventory
                RES     2,(HL)
ED1:            EXX
                LD      BC,L0001
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
                LD      DE,L0000
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

InitNewGame1:	LD		HL,RoomMask
		LD		BC,NUM_ROOMS
		JP		FillZero
C8C50:	CALL	C708B
		PUSH	AF
		CALL	RoomCount
		POP		AF
		LD		HL,L0000
		JR		NZ,L8C69
		LD		HL,L0501
		LD		A,(LA295)
		AND		A
		JR		Z,L8C69
		LD		HL,L1002
L8C69:	LD		BC,L0010
		CALL	C8C82
		PUSH	HL
		CALL	EmptyDonuts ; Alternatively, score inventory minus donuts?
		POP		HL
		LD		BC,L01F4
		CALL	C8C82
		PUSH	HL
		CALL	WorldCount
		POP		HL
		LD		BC,L027C
C8C82:	LD		A,E
		ADD		A,L
		DAA
		LD		L,A
		LD		A,H
		ADC		A,D
		DAA
		LD		H,A
		DEC		BC
		LD		A,B
		OR		C
		JR		NZ,C8C82
		RET

	;; Given a direction bitmask in A, return a direction code.
LookupDir:	AND		$0F
		ADD		A,DirTable & $FF
		LD		L,A
		ADC		A,DirTable >> 8
		SUB		L
		LD		H,A
		LD		A,(HL)
		RET

	;; Input into this look-up table is the 4-bit bitmask:
	;; Left Right Down Up.
	;;
	;; Combinations are mapped to the following directions:
	;;
	;; $05 $04 $03
	;; $06 $FF $02
	;; $07 $00 $01
	;;
DirTable:	DEFB $FF,$00,$04,$FF,$06,$07,$05,$06
		DEFB $02,$01,$03,$02,$FF,$00,$04,$FF
	
	
C8CAB:	LD		L,A
		ADD		A,A
		ADD		A,L
		ADD		A,$BB
		LD		L,A
		ADC		A,$8C
		SUB		L
		LD		H,A
		LD		C,(HL)
		INC		HL
		LD		B,(HL)
		INC		HL
		LD		A,(HL)
		RET
L8CBB:	DEFB $FF,$00,$0D,$FF,$FF,$09,$00,$FF,$0B,$01,$FF,$0A,$01,$00,$0E,$01
L8CCB:	DEFB $01,$06,$00,$01,$07,$FF,$01,$05
C8CD3:	LD		HL,(CurrObject)
C8CD6:	PUSH	HL
		CALL	C8CAB
		LD		DE,L000B
		POP		HL
		ADD		HL,DE
		XOR		(HL)
		AND		$0F
		XOR		(HL)
		LD		(HL),A
		LD		DE,LFFFA
		ADD		HL,DE
		LD		A,(HL)
		ADD		A,C
		LD		(HL),A
		INC		HL
		LD		A,(HL)
		ADD		A,B
		LD		(HL),A
		RET
C8CF0:	INC		(HL)
		LD		A,(HL)
		ADD		A,L
		LD		E,A
		ADC		A,H
		SUB		E
		LD		D,A
		LD		A,(DE)
		AND		A
		RET		NZ
		LD		(HL),$01
		INC		HL
		LD		A,(HL)
		RET
L8CFF:	LD		A,(HL)
		INC		(HL)
		ADD		A,A
		ADD		A,L
		LD		E,A
		ADC		A,H
		SUB		E
		LD		D,A
		INC		DE
		LD		A,(DE)
		AND		A
		JR		Z,L8D11
		EX		DE,HL
		LD		E,A
		INC		HL
		LD		D,(HL)
		RET
L8D11:	LD		(HL),$01
		INC		HL
		LD		E,(HL)
		INC		HL
		LD		D,(HL)
		RET
	
C8D18:		LD		HL,(L8D49)
		LD		D,L
		ADD		HL,HL
		ADC		HL,HL
		LD		C,H
		LD		HL,(L8D47)
		LD		B,H
		RL		B
		LD		E,H
		RL		E
		RL		D
		ADD		HL,BC
		LD		(L8D47),HL
		LD		HL,(L8D49)
		ADC		HL,DE
		RES		7,H
		LD		(L8D49),HL
		JP		M,L8D43
		LD		HL,L8D47
L8D3F:		INC		(HL)
		INC		HL
		JR		Z,L8D3F
L8D43:		LD		HL,(L8D47)
		RET

L8D47:	DEFB $4A,$6F
L8D49:	DEFB $6E,$21

	;; Pointer to object in HL
RemoveObject:	PUSH	HL
		PUSH	HL
		PUSH	IY
		PUSH	HL
		POP	IY
		CALL	ProcObjUnk5
		POP	IY
		POP	HL
		CALL	C8D6F
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

C8D6F:	PUSH	IY
		INC		HL
		INC		HL
		CALL	GetObjExtents2
		EX		DE,HL
		LD		H,B
		LD		L,C
		CALL	CheckAndDraw
		POP		IY
		RET
	
InsertObject:	PUSH	HL
		PUSH	HL
		PUSH	IY
		PUSH	HL
		POP	IY
		CALL	ProcObjUnk2
		POP	IY
		POP	HL
		CALL	C8D6F
		POP	IX
		RES	7,(IX+$04)
		LD	(IX+$0B),$FF
		LD	(IX+$0C),$FF
		RET
	
#include "sprite_stuff.asm"
	
L8ED8:	DEFB $00
L8ED9:	DEFB $FF
L8EDA:	DEFB $FF

#include "obj_fns.asm"
	
L9376:	DEFB $FD,$F9,$FB,$FA,$FE,$F6,$F7,$F5
C937E:	LD		C,(IY+$10)
		BIT		1,C
		RES		4,(IY+$04)
		JR		NZ,C938D
		SET		4,(IY+$04)
C938D:	LD		A,(IY+$0F)
		AND		A
		RET		Z
		BIT		2,C
		LD		C,A
		JR		Z,L939E
		BIT		3,C
		RET		NZ
		LD		A,$08
		JR		L93A2
L939E:	BIT		3,C
		RET		Z
		XOR		A
L93A2:	XOR		C
		AND		$0F
		XOR		C
		LD		(IY+$0F),A
		RET
L93AA:	DEFB $00,$00,$00,$00,$00,$00

	;; The phase mechanism allows an object to not get processed
	;; for one frame.
DoObjects:	LD	A,(Phase)
		XOR	$80
		LD	(Phase),A 		; Toggle top bit of Phase
		CALL	CharThing
	;; Loop over object list...
		LD	HL,(ObjectList)
		JR	DO_3
DO_1:		PUSH	HL
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		EX	(SP),HL			; Next item on top of stack, curr item in HL
		EX	DE,HL
		LD	HL,L000A
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

	;; Room origin, in double-pixel coordinates, for attrib-drawing
RoomOrigin:	DEFW $0000
	
Attrib0:	DEFB $00
Attrib3:	DEFB $43
Attrib4:	DEFB $45
Attrib5:	DEFB $46

#include "blit_screen.asm"

#include "screen_bits.asm"

#include "controls2.asm"

#include "sound.asm"

#include "blit_mask.asm"

#include "background.asm"

#include "blit_rot.asm"

#include "scene.asm"

	;; Fetch bit-packed data.
	;; Expects number of bits in B.
	
	;; End marker is the set bit rotated in from carry: The
	;; current byte is all read when only that bit remains.
FetchData:	LD	DE,CurrData
		LD	A,(DE)
		LD	HL,(DataPtr)
		LD	C,A
		XOR	A
FD_1:		RL	C
		JR	Z,FD_3
FD_2:		RLA
		DJNZ	FD_1
		EX	DE,HL
		LD	(HL),C
		RET
	;; Next character case: Load/initially rotate the new character, and jump back.
FD_3:		INC	HL
		LD	(DataPtr),HL
		LD	C,(HL)
		SCF
		RL	C
		JP	FD_2

	
CA260:	LD		HL,(L7748)
		LD		A,L
		CP		H
		JR		C,LA268
		LD		A,H
LA268:	NEG
		ADD		A,$C0
		LD		HL,L774C
		CP		(HL)
		JR		C,LA273
		LD		(HL),A
LA273:	LD		A,(HL)
		JP		L84E4

FillZero:	LD	E,$00
	;; HL = Dest, BC = Size, E = value
FillValue:	LD	(HL),E
		INC	HL
		DEC	BC
		LD	A,B
		OR	C
		JR	NZ,FillValue
		RET

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
LA2A0:		DEFB $FF
	
LA2A1:	DEFB $02
LA2A2:	DEFB $00
LA2A3:	DEFB $00,$00,$00
LA2A6:	DEFB $03
Carrying:	DEFW $0000	 ; Pointer to carried object.
	
FiredObj:	DEFB $00,$00,$00,$00,$20
		DEFB $28,$0B,$C0
		DEFB $24,$08
		DEFB $12
		DEFB $FF,$FF,$00,$00
		DEFB $08,$00,$00
	
LA2BB:	DEFB $0F
LA2BC:	DEFB $00
OtherSoundId:	DEFB $00
SoundId:	DEFB $00	 ; Id of sound, +1 (0 = no sound)
LA2BF:	DEFB $FF
	
HeelsObj:	DEFB $00
LA2C1:	DEFB $00,$00,$00,$08
LA2C5:	DEFB $28,$0B,$C0
LA2C8:	DEFB $18,$21,$00,$FF,$FF
LA2CD:	DEFB $00,$00,$00,$00
LA2D1:	DEFB $00
	
HeadObj:	DEFB $00,$00,$00,$00,$08
LA2D7:	DEFB $28,$0B,$C0
LA2DA:	DEFB $1F,$25,$00,$FF,$FF
LA2DF:	DEFB $00,$00
LA2E1:	DEFB $00,$00,$00
	
LA2E4:	DEFB $00,$18,$19,$18,$1A,$00
LA2EA:	DEFB $00,$1B,$1C,$1B,$1D,$00
LA2F0:	DEFB $00
LA2F1:	DEFB $1E,$1F,$1E,$20,$00
LA2F6:	DEFB $00,$21,$22,$21,$23,$00
LA2FC:	DEFB $00,$24,$A4,$A5,$25
LA301:	DEFB $A5,$A6,$26,$26,$A6,$A6,$26,$26,$00
LA30A:	DEFB $00,$26,$A6,$26,$A6,$A5,$25
LA311:	DEFB $24,$A5,$00
LA314:	DEFB $00
LA315:	DEFB $40
LA316:	LD		HL,LA314
		LD		A,$80
		XOR		(HL)
		LD		(HL),A
		LD		A,(LC043)
		BIT		0,A
		LD		HL,LD12D
		LD		DE,LA355
		JR		Z,LA32E
		DEC		HL
		LD		DE,LA349
LA32E:	PUSH	DE
		PUSH	HL
		CALL	CA339
		LD		DE,L0048
		POP		HL
		ADD		HL,DE
		POP		DE
CA339:	LD		C,$06
LA33B:	LD		B,$02
LA33D:	LD		A,(DE)
		XOR		(HL)
		LD		(HL),A
		INC		DE
		INC		HL
		DJNZ	LA33D
		INC		HL
		DEC		C
		JR		NZ,LA33B
		RET
LA349:	DEFB $00,$C0,$01,$D8,$00,$1C,$00,$84,$00,$10,$00,$20
LA355:	DEFB $03,$00,$1B,$80,$38,$00,$21,$00,$08,$00,$04,$00

#include "character.asm"
	
LAA72:	DEFB $00
LAA73:	DEFB $00

CAA74:		CALL	CAA7E
		LD		A,(IY+$07)
		SUB		C
		JP		LAB0B
CAA7E:	LD		C,$C0
		LD		A,(LA2BC)
		AND		A
		RET		Z
		LD		IX,L7744
		LD		C,(IX+$00)
		LD		A,(L771B)
		SUB		$03
		CP		A,(IY+$06)
		RET		C
		LD		C,(IX+$02)
		LD		A,(L7719)
		ADD		A,$02
		CP		A,(IY+$06)
		RET		NC
		LD		C,(IX+$01)
		LD		A,(L771A)
		SUB		$03
		CP		A,(IY+$05)
		RET		C
		LD		C,(IX+$03)
		RET

FloorThing1:	CP	$FF
	;; NB: Fall through.
FloorThing2:	SCF
		LD	(IY+$0D),A
		LD	(IY+$0E),A
		RET	NZ
		BIT	0,(IY+$09)
		JR	Z,FloorCheck
		LD	A,(LA2BC)
		AND	A
		JR	NZ,RetZeroC
		LD	A,(FloorCode)
		CP	$06 		; Deadly floor?
		JR	Z,DeadlyFloorCase
		CP	$07 		; No floor?
		JR	NZ,RetZeroC
	;; Code to handle no floor...
		CALL	GetCharObj
		PUSH	IY
		POP	DE
		AND	A
		SBC	HL,DE
		JR	Z,FloorThing3
		LD	HL,SwopPressed
		LD	A,(HL)
		OR	$03
		LD	(HL),A
		JR	RetZeroC

FloorThing3:	LD	A,$05
		LD	(LB218),A
		AND	A
		RET

DeadlyFloorCase:LD	C,(IY+$09)
		LD	B,(IY+$04)
		CALL	CB2F8

	;; Return with 0 in A, and carry flag set.
RetZeroC:	XOR	A
		SCF
		RET

FloorCheck:	LD	A,(FloorCode)
		CP	$07 		; No floor?
		JR	NZ,RetZeroC
		LD	(IY+$0A),$22 	; Update this, then.
		JR	RetZeroC

CAB06:		LD	A,(IY+$07)
		SUB	$C0
LAB0B:		LD	BC,L0000
		LD	(LAA72),BC
		JR	Z,FloorThing2
		INC	A
		JR	Z,FloorThing1
		CALL	GetUVZExtentsE
		LD	C,B
		INC	C
		EXX
		LD	A,(IY+$0E)
		AND	A
		JR	Z,LAB64
		LD	H,A
		LD	L,(IY+$0D)
		PUSH	HL
		POP	IX
		BIT	7,(IX+$04)
		JR	NZ,LAB64
		LD	A,(IX+$07)
		SUB	$06
		EXX
		CP	B
		EXX
		JR	NZ,LAB64
		CALL	CheckWeOverlap
		JR	NC,LAB64
LAB3F:		BIT	1,(IX+$09)
		JR	Z,LAB4E
		RES	5,(IX-$06)
		LD	A,(IX-$07)
		JR	LAB55

LAB4E:		RES		5,(IX+$0C)
		LD		A,(IX+$0B)

LAB55:		OR		$E0
		LD		C,A
		LD		A,(IY+$0C)
		AND		C
		LD		(IY+$0C),A
LAB5F:	XOR		A
		SCF
		JP		LB2BF
	;; Run through all the objects
LAB64:		LD	HL,ObjectList
LAB67:		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		OR	H
		JR	Z,LABA6
		PUSH	HL
		POP	IX
		BIT	7,(IX+$04)
		JR	NZ,LAB67 	; Bit set? Skip this item
		LD	A,(IX+$07)
		SUB	$06
		EXX
		CP	B
		JR	NZ,LAB90
		EXX
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,LAB67
LAB88:		LD	(IY+$0D),L
		LD	(IY+$0E),H
		JR	LAB3F
LAB90:		CP	C
		EXX
		JR	NZ,LAB67
		LD	A,(LAA73)
		AND	A
		JR	NZ,LAB67
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,LAB67
		LD	(LAA72),HL
		JR	LAB67
	;; Completed object list traversal
LABA6:	LD		A,(LA2BC)
		AND		A
		JR		Z,LABE7
		CALL	GetCharObjIX
		LD		A,(Character)
		CP		$03
		LD		A,$F4
		JR		Z,LABBA
		LD		A,$FA
LABBA:	ADD		A,(IX+$07)
		EXX
		CP		B
		JR		NZ,LABCB
		EXX
		PUSH	HL
		CALL	CheckWeOverlap
		POP		HL
		JR		NC,LABE7
		JR		LAB88
LABCB:	CP		C
		EXX
		JR		NZ,LABE7
		LD		A,(LAA73)
		AND		A
		JR		NZ,LABE7
		CALL	GetCharObjIX
		CALL	CheckWeOverlap
		JR		NC,LABE7
		LD		(IY+$0D),$00
		LD		(IY+$0E),$00
		JR		LAC0E
LABE7:	LD		HL,(LAA72)
		LD		(IY+$0D),$00
		LD		(IY+$0E),$00
		LD		A,H
		AND		A
		RET		Z
		PUSH	HL
		POP		IX
		BIT		1,(IX+$09)
		JR		Z,LAC04
		BIT		4,(IX-$07)
		JR		LAC08
LAC04:	BIT		4,(IX+$0B)
LAC08:	JR		NZ,LAC0E
		RES		4,(IY+$0C)
LAC0E:	XOR		A
		SUB		$01
		RET

	;; Called by the purse routine to find something to pick up.
	;; Carry flag set if something is found, and thing returned in HL.
	;;
	;; Loop through all items, finding ones which match on B or C
	;; Then call CheckWeOverlap to see if ok candidate. Return it
	;; in HL if it is.
GetStoodUpon:	CALL	GetUVZExtentsE		; Perhaps getting height as a filter?
		LD	A,B
		ADD	A,$06
		LD	B,A
		INC	A
		LD	C,A
		EXX
	;; Traverse list of objects
		LD	HL,ObjectList
GSU_1:		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		OR	H
		RET	Z
		PUSH	HL
		POP	IX
		BIT	6,(IX+$04)
		JR	Z,GSU_1
		LD	A,(IX+$07)
		EXX
		CP	B
		JR	Z,GSU_2
		CP	C
GSU_2:		EXX
		JR	NZ,GSU_1
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,GSU_1
		RET

	;; FIXME: Looks suspiciously like we're checking contact with objects.
CAC41:		CALL	GetUVZExtentsE
		LD	B,C
		DEC	B
		EXX
		XOR	A
		LD	(LAA72),A
	;; Traverse list of objects
		LD	HL,ObjectList
LAC4E:		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		OR	H
		JR	Z,LAC97		; Reached end?
		PUSH	HL
		POP	IX
		BIT	7,(IX+$04)
		JR	NZ,LAC4E 	; Skip if bit set
		LD	A,(IX+$07)
		EXX
		CP	C
		JR	NZ,LAC7F
		EXX
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,LAC4E
LAC6D:		LD	A,(IY+$0B)
		OR	$E0
		AND	$EF
		LD	C,A
		LD	A,(IX+$0C)
		AND	C
		LD	(IX+$0C),A
		JP	LAB5F		; Tail call
LAC7F:		CP	B
		EXX
		JR	NZ,LAC4E
		LD	A,(LAA72)
		AND	A
		JR	NZ,LAC4E
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,LAC4E
		LD	A,$FF
		LD	(LAA72),A
		JR	LAC4E
	;; Finished traversing list
LAC97:		LD	A,(LA2BC)
		AND	A
		JR	Z,LACCC
		CALL	GetCharObjIX
		LD	A,(IX+$07)
		EXX
		CP	C
		JR	NZ,LACB6
		EXX
		CALL	CheckWeOverlap
		JR	NC,LACCC
		JR	LAC6D

GetCharObjIX:	CALL	GetCharObj
		PUSH	HL
		POP	IX
		RET

LACB6:	CP		B
		EXX
		JR		NZ,LACCC
		LD		A,(LAA72)
		AND		A
		JR		NZ,LACCC
		CALL	GetCharObjIX
		CALL	CheckWeOverlap
		JR		NC,LACCC
		LD		A,$FF
		JR		LACCF
LACCC:	LD		A,(LAA72)
LACCF:	AND		A
		RET		Z
		SCF
		RET

	;; Takes object point in IX and checks to see if we overlap with it.
	;; FIXME: May assume our coordinates are in DE',HL'.
CheckWeOverlap:	CALL	CACE6
	;; NB: Fall through
	
	;; Assuming X and Y extents in DE,HL and DE',HL', check two boundaries overlap.
	;; Sets carry flag if they do.
CheckOverlap:
	;; Check E < D' and E' < D
		LD	A,E
		EXX
		CP	D
		LD	A,E
		EXX
		RET	NC
		CP	D
		RET	NC
	;; Check L < H' and L' < H
		LD	A,L
		EXX
		CP	H
		LD	A,L
		EXX
		RET	NC
		CP	H
		RET

CACE6:		LD		A,(IX+$04)
		BIT		1,A
		JR		NZ,LAD03
		RRA
		LD		A,$03
		ADC		A,$00
		LD		C,A
		ADD		A,(IX+$05)
		LD		D,A
		SUB		C
		SUB		C
		LD		E,A
		LD		A,C
		ADD		A,(IX+$06)
		LD		H,A
		SUB		C
		SUB		C
		LD		L,A
		RET
LAD03:	RRA
		JR		C,LAD16
		LD		A,(IX+$05)
		ADD		A,$04
		LD		D,A
		SUB		$08
		LD		E,A
		LD		L,(IX+$06)
		LD		H,L
		INC		H
		DEC		L
		RET
LAD16:	LD		A,(IX+$06)
		ADD		A,$04
		LD		H,A
		SUB		$08
		LD		L,A
		LD		E,(IX+$05)
		LD		D,E
		INC		D
		DEC		E
		RET

CAD26:		LD	BC,(RoomId)
		LD	HL,LAD4C
		CALL	CAD35
		LD	(RoomId),DE
		RET

;; Scans array from HL, looking for BC, scanning in pairs. If the
;; first is equal, it returns the second. If the second is equal,
;; it returns it.

CAD35:		CALL	CmpBCHL
		JR	Z,CmpBCHL
		PUSH	DE
		CALL	CmpBCHL
		POP	DE
		JR	NZ,CAD35
		RET

;; Loads (HL) into DE, incrementing HL. Compares BC with DE, sets Z if equal.
CmpBCHL:        LD      A,C
                LD      E,(HL)
                INC     HL
                LD      D,(HL)
                INC     HL
                CP      E
                RET     NZ
                LD      A,B
                CP      D
                RET

LAD4C:	DEFW $8A40,$7150,$8940,$0480,$BA70,$1300,$4100,$2980
	DEFW $A100,$2600,$8100,$E980,$8400,$B100,$8500,$EF20
	DEFW $A400,$00F0,$A500,$88D0,$BCD0,$DED0,$2DB0,$8BD0
	DEFW $1190,$E1C0,$00B0,$E2C0,$10B0,$C100,$8BF0,$00F0
	DEFW $9730,$EF20,$1D00,$A800,$BA70,$4E00,$8800,$1B30
	DEFW $4C00,$3930,$8B30,$8D30

;; Width of sprite in bytes.
SpriteWidth:    DEFB $04
;; Current sprite we're drawing.
SpriteCode:     DEFB $00

RevTable:       EQU $B900

;; Initialise a look-up table of byte reverses.
InitRevTbl:     LD      HL,RevTable
RevLoop_1:      LD      C,L
                LD      A,$01
                AND     A
RevLoop_2:      RRA
                RL      C
                JR      NZ,RevLoop_2
                LD      (HL),A
                INC     L
                JR      NZ,RevLoop_1
                RET

;; Generates the X and Y extents, and sets the sprite code and sprite
;; width.
;;
;; Parameters: Sprite code is passed in in A.
;;             X coordinate in C, Y coordinate in B
;; Returns: X extent in BC, Y extent in HL
GetSprExtents:  LD      (SpriteCode),A
                AND     $7F
                CP      $10
                JR      C,Case3x56      ; Codes < $10 are 3x56
                LD      DE,L0606
                LD      H,$12
                CP      $54
                JR      C,SSW1
                LD      DE,L0808        ; Codes >= $54 are 4x28
                LD      H,$14
SSW1:           CP      $18
                JR      NC,SSW2
                LD      A,(SpriteFlags) ; 3x24 or 4x28
                AND     $02
                LD      D,$04
                LD      H,$0C
                JR      Z,SSW2
                LD      D,$00
                LD      H,$10
        ;; All cases but 3x56 join up here:
        ;; D is Y extent down, H is Y extent up
        ;; E is half-width (in double pixels)
        ;; 4x28: D = 8, E = 8, H = 20
        ;; 3x24: D = 6, E = 6, H = 18
        ;; 3x32: D = 4, E = 6, H = 12 if flags & 2
        ;; 3x32: D = 0, E = 6, H = 16 otherwise
SSW2:           LD      A,B
                ADD     A,D
                LD      L,A             ; L = B + D
                SUB     D
                SUB     H
                LD      H,A             ; H = B - H
                LD      A,C
                ADD     A,E
                LD      C,A             ; C = C + E
                SUB     E
                SUB     E
                LD      B,A             ; B = C - 2*E
                LD      A,E
                AND     A
                RRA                     ; And save width in bytes to SpriteWidth
                LD      (SpriteWidth),A
                RET
Case3x56:       LD      HL,(CurrObject2+1)
                INC     HL
                INC     HL
                BIT     5,(HL)          ; Check flag bit 0x20 for later
                EX      AF,AF'
                LD      A,(HL)
                SUB     $10
                CP      $20
                LD      L,$04
                JR      NC,C356_1
                LD      L,$08
C356_1:         LD      A,B             ; L = (Flag - $10) >= $20 ? 8 : 4
                ADD     A,L
                LD      L,A             ; L = B + L
                SUB     $38
                LD      H,A             ; H = L - 56
                EX      AF,AF'
                LD      A,C
                LD      B,$08
                JR      NZ,C356_2
                LD      B,$04
C356_2:         ADD     A,B             ; B = (Flag & 0x20) ? 8 : 4
                LD      C,A             ; C = C + B
                SUB     $0C
                LD      B,A             ; B = C - 12
                LD      A,$03           ; Always 3 bytes wide.
                LD      (SpriteWidth),A
                RET

#include "get_sprite.asm"
	
DoorwayFlipped:	DEFB $00
LAF5B:	DEFB $1B		; Reinitialisation size

	DEFB $00
	DEFW LBA40
	DEFW ObjList3
	DEFW ObjectList
	DEFW $0000
	DEFW $0000
	DEFW $0000,$0000
	DEFW $0000,$0000
	DEFW $0000,$0000
	DEFW $0000,$0000

LAF77:	DEFB $00
        ;; Current pointer for where we write objects into
ObjDest:	DEFW LBA40
LAF7A:	DEFW ObjList3
LAF7C:	DEFW ObjectList
ObjList3:	DEFW $0000
ObjectList:	DEFW $0000
ObjList5:	DEFW $0000,$0000
ObjList1:	DEFW $0000,$0000
ObjList2:	DEFW $0000,$0000
ObjList4:	DEFW $0000,$0000
	
LAF92:	DEFW LBA40
SortObj:	DEFW $0000
	
CAF96:		LD		(LAF77),A
		ADD		A,A
		ADD		A,A
		ADD		A,$7E
		LD		L,A
		ADC		A,$AF
		SUB		L
		LD		H,A
	;; HL = $AF7E + (LAF77) * 4
		LD		(LAF7A),HL
		INC		HL
		INC		HL
		LD		(LAF7C),HL
		RET

CAFAB:	LD		HL,L0012
		ADD		HL,DE
		PUSH	HL
		EX		DE,HL
		LD		BC,L0005
		LDIR
		LD		A,(HL)
		SUB		$06
		LD		(DE),A
		INC		DE
		INC		HL
		INC		HL
		BIT		5,(HL)
		JR		NZ,LAFC4
		DEC		HL
		LDI
LAFC4:	POP		HL
		RET

#include "procobj.asm"

#include "depthcmp.asm"

LB217:	DEFB $00
LB218:	DEFB $00
LB219:	DEFB $00
LB21A:	DEFB $00
LB21B:	DEFB $00
	
TableCall:	PUSH	AF
		CALL	GetUVZExtentsE
		EXX
		POP	AF
		LD	(LB21B),A
	;; NB: Fall through

        ;; Takes value in A etc. plus extra return value.
DoTableCall:	CALL	SomeTableCall
		LD	A,(LB21B)
		RET

	;; Takes value in A, indexes into table, writes variable, makes call...
SomeTableCall:	LD	DE,PostTableCall
        ;; Pop this on the stack to be called upon return.
		PUSH	DE
		LD	C,A
		ADD	A,A
		ADD	A,A
		ADD	A,C		; Multiply by 5
		ADD	A,FnTbl & $FF
		LD	L,A
		ADC	A,FnTbl >> 8
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

PostTableCall:    EXX
                        RET             Z
                        PUSH    HL
                        POP             IX
                        BIT             2,C
                        JR              NZ,LB269
                        LD              HL,ObjList3
LB257:    LD              A,(HL)
                        INC             HL
                        LD              H,(HL)
                        LD              L,A
                        OR              H
                        JR              Z,LB282
                        PUSH    HL
                        CALL    DoCopy
                        POP             HL
                        JR              C,LB2A0
                        JR              NZ,LB257
                        JR              LB282
LB269:    LD              HL,LAF80
LB26C:    LD              A,(HL)
                        INC             HL
                        LD              H,(HL)
                        LD              L,A
                        OR              H
                        JR              Z,LB27C
                        PUSH    HL
                        CALL    DoCopy
                        POP             HL
                        JR              C,LB2A2
                        JR              NZ,LB26C
LB27C:    CALL	GetCharObj
                        LD              E,L
                        JR              LB288
LB282:    CALL    GetCharObj
                        LD              E,L
                        INC             HL
                        INC             HL
LB288:    BIT             0,(IY+$09)
                        JR              Z,LB292
                        LD              A,YL
                        CP              E
                        RET             Z

LB292:    LD              A,(LA2BC)
                        AND             A
                        RET             Z
                        CALL    DoCopy
                        RET             NC
                        CALL    GetCharObj
                        INC             HL
                        INC             HL
LB2A0:    DEC             HL
                        DEC             HL
LB2A2:    PUSH    HL
                        POP             IX
                        LD              A,(LB217)
                        BIT             1,(IX+$09)
                        JR              Z,LB2B6
                        AND             A,(IX-$06)
                        LD              (IX-$06),A
                        JR              LB2BC
LB2B6:    AND             A,(IX+$0C)
                        LD              (IX+$0C),A
LB2BC:    XOR             A
                        SUB             $01
LB2BF:	PUSH	AF
		PUSH	IX
		PUSH	IY
		CALL	CB2CD
		POP		IY
		POP		IX
		POP		AF
		RET
CB2CD:	BIT		0,(IY+$09)
		JR		NZ,LB2DF
		BIT		0,(IX+$09)
		JR		Z,LB34F
		PUSH	IY
		EX		(SP),IX
		POP		IY
LB2DF:	LD		C,(IY+$09)
		LD		B,(IY+$04)
		BIT		5,(IX+$04)
		RET		Z
		BIT		6,(IX+$04)
		JR		NZ,LB333
		AND		A
		JR		Z,CB2F8
		BIT		4,(IX+$09)
		RET		NZ
CB2F8:		BIT		3,B
		LD		B,$03
		JR		NZ,LB304
		DEC		B
		BIT		2,C
		JR		NZ,LB304
		DEC		B
LB304:		XOR		A
		LD		HL,Invuln
		CP		(HL)
		JR		Z,LB30D
		RES		0,B
LB30D:		INC		HL
		CP		(HL)
		JR		Z,LB313
		RES		1,B
LB313:		LD		A,B
		AND		A
		RET		Z
		LD		HL,LB21A
		OR		(HL)
		LD		(HL),A
		DEC		HL
		LD		A,(HL)
		AND		A
		RET		NZ
		LD		A,(WorldMask)
		CP		$1F
		RET		Z
		LD		(HL),$0C
		LD		A,(LB218)
		AND		A
		CALL	NZ,BoostInvuln
		LD		B,$C6
		JP		PlaySound
LB333:	LD		(IX+$0F),$08
		LD		(IX+$04),$80
		LD		A,(IX+$0A)
		AND		$80
		OR		$11
		LD		(IX+$0A),A
		RES		6,(IX+$09)
		LD		A,(IX+$11)
		JP		L87DF
LB34F:	BIT		3,(IY+$09)
		JR		NZ,LB35E
		BIT		3,(IX+$09)
		RET		Z
		PUSH	IY
		POP		IX
LB35E:	BIT		1,(IX+$09)
		JR		Z,LB369
		LD		DE,LFFEE
		ADD		IX,DE
LB369:	BIT		7,(IX+$09)
		RET		Z
		SET		6,(IX+$09)
		LD		(IX+$0B),$FF
		RET

#include "fn_tbl_stuff.asm"
	
#include "print_char.asm"

	;; Called immediately after installing interrupt handler.
ShuffleMem:	; Zero end of top page
		LD	HL,LFFFE
		XOR	A
		LD	(HL),A
		; Switch to bank 1, write top of page
		LD	BC,L7FFD
		LD	D,$10
		LD	E,$11
		OUT	(C),E
		LD	(HL),$FF
		; Switch back, see if original overwritten...
		OUT	(C),D
		CP	(HL)
		JR	NZ,Have48K
		; Ok, we're 128K...
		; Zero screen attributes, so no-one can see we're using it as temp space...
		LD	B,$03
		LD	HL,L5800
ShuffleMem_1:	LD	(HL),$00
		INC	L
		JR	NZ,ShuffleMem_1
		INC	H
		DJNZ	ShuffleMem_1
		; Stash data in display memory
		LD	BC,L091B
		LD	DE,L4000
		LD	HL,LB884
		LDIR
		; Switch to bank 1
		LD	A,$11
		LD	BC,L7FFD
		OUT	(C),A
		; Reinitialise IRQ handler there.
		LD	A,$18
		LD	(LFFFF),A
		LD	A,$C3
		LD	($FFF4),A
		LD	HL,IrqHandler
		LD	(LFFF5),HL
		; FIXME: Another memory chunk copy.
		LD	BC,L0043
		LD	DE,AltPlaySound
		LD	HL,LB824
		LDIR
		; FIXME: Repoint interrupt vector.
		DEC	DE
		LD	E,$00
		INC	D
		LD	A,D
		LD	I,A
		LD	A,$FF
ShuffleMem_2:	LD	(DE),A
		INC	E
		JR	NZ,ShuffleMem_2
		INC	D
		LD	(DE),A
		; Unstash from display memory
		LD	BC,L091B
		LD	DE,LC000
		LD	HL,L4000
		LDIR
		; Switch to bank 0.
		LD	BC,L7FFD
		LD	A,$10
		OUT	(C),A
Have48K:	; Move the data end of things down by 360 bytes...
		LD	HL,LC1A0
		LD	DE,LC038
		LD	BC,L390C ; Up to 0xFAAC
		LDIR
		RET

#include "data_trailer.asm"

#end
