	;; 
	;; background.asm
	;;
	;; Code to do with drawing the floor and walls
	;; 
	;; FIXME: Still needs plenty of work.
	;;

	;; Exported functions:
	;;  * DrawFloor
	;;  * FloorFn
	;;  * DoCopy
	;;  * SetFloorAddr
	
DrawFloor:	LD	HL,(SpriteXExtent)
		LD	A,H
		RRA
		RRA
		LD	C,A
		AND	$3E
		EXX
		LD	L,A
		LD	H,$BA
		EXX
		LD	A,L
		SUB	H
		RRA
		RRA
		AND	$07
		SUB	$02
		LD	DE,SpriteBuff
		RR	C
		JR	NC,DF_1
		LD	IY,ClearOne
		LD	IX,OneColBlitR
		LD	HL,BlitFloorR
		CALL	FloorCall
		CP	$FF
		RET	Z
		SUB	$01
		JR	DF_2
DF_1:		LD	IY,ClearTwo
		LD	IX,TwoColBlit
		LD	HL,BlitFloor
		CALL	FloorCall
		INC	E
		SUB	$02
DF_2:		JR	NC,DF_1
		INC	A
		RET	NZ
		LD	IY,ClearOne
		LD	IX,OneColBlitL
		LD	HL,BlitFloorL
		LD	(BlitFloorFnPtr+1),HL
		EXX
		JR	FloorCall2 		; Tail call.

	;; Performs register-saving and incrementing HL/E. Not needed
	;; for the last call from DrawFloor.
FloorCall:	LD	(BlitFloorFnPtr+1),HL
		PUSH	DE
		PUSH	AF
		EXX
		PUSH	HL
		CALL	FloorCall2
		POP	HL
		INC	L
		INC	L
		EXX
		POP	AF
		POP	DE
		INC	E
		RET

	;; Call inputs:
	;; * Reads from SpriteYExtent
	;; * Takes in:
	;;   HL' - Floor drawing function
	;;   IX  - Copying function
	;;   IY  - Clearing function
	;;   HL  - Pointer to some structure:
	;;           Y baseline (0 = clear)
FloorCall2:	LD	DE,(SpriteYExtent)
		LD	A,E
		SUB	D
		LD	E,A		; E now contains height
		LD	A,(HL)
		AND	A
		JR	Z,FC_Clear 	; Baseline of zero? Clear full height, then
		LD	A,D
		SUB	(HL)
		LD	D,A		; D now offset by Y baseline
		JR	NC,FC_Onscreen 	; Updated D is onscreen? Then jump...
		INC	HL
		LD	C,$38
		BIT	2,(HL)
		JR	Z,FC_Flag
		LD	C,$4A
FC_Flag:	ADD	A,C		; Add $38 or $4A to the start line, depending on flag.
		JR	NC,FC_2
		ADD	A,A
		CALL	L9D77
		EXX
		LD	A,D
		NEG
		JP	FC_3
FC_2:		NEG
		CP	E
		JR	NC,FC_Clear
		LD	B,A
		NEG
		ADD	A,E
		LD	E,A
		LD	A,B
		CALL	DoClear
		LD	A,(HL)
		EXX
		CALL	GetWall
		EXX
		LD	A,$38
		BIT	2,(HL)
		JR	Z,FC_3
		LD	A,$4A
FC_3:		CP	E
		JR	NC,FC_Copy
		LD	B,A
		NEG
		ADD	A,E
		EX	AF,AF'
		LD	A,B
		CALL	DoCopy
		EX	AF,AF'
		LD	D,$00
		JR	FC_7
FC_Copy:	LD	A,E
		JP	(IX)		; Copy A rows from HL' to DE'.
FC_Clear:	LD	A,E
		JP	(IY)		; Clear A rows at DE'.
FC_Onscreen:	LD	A,E
		INC	HL
	;; At this point, HL has been incremented by 1, A contains height.
	;; D contains baseline.
FC_7:		LD	B,A
		DEC	HL
		LD	A,L
		ADD	A,A
		ADD	A,A
		ADD	A,$04
	;; Compare A with the position of the corner, to determine the
	;; play area edge graphic to use, by overwriting the WhichEdge
	;; operand. A itself is adjusted around the corner position.
CornerPos:	CP	$00		; NB: Target of self-modifying code.
		JR	C,FC_Left
		LD	E,$00		; Right edge graphic case
		JR	NZ,FC_Right
		LD	E,$05		; Corner edge graphic case
FC_Right:	SUB	$04
RightAdj:	ADD	A,$00 		; NB: Target of self-modifying code.
		JR	FC_CrnrJmp
FC_Left:	ADD	A,$04
		NEG
LeftAdj:	ADD	A,$00 		; NB: Target of self-modifying code.
		LD	E,$08		; Left edge graphic case
	;; Store height in C, write out edge graphic
FC_CrnrJmp:	NEG
		ADD	A,$0B
		LD	C,A
		LD	A,E
		LD	(WhichEdge+1),A
	;; FIXME: Next section?
		LD	A,(HL)		; Load Y baseline
		ADD	A,D
		INC	HL
		SUB	C		; Calculate D - C
		JR	NC,FC_Clear2	; <= 0 -> Clear B rows
		ADD	A,$0B
		JR	NC,FC_14 	; <= 11 -> Call ting
		LD	E,A
		SUB	$0B
		ADD	A,B
		JR	C,FC_11
		LD	A,B
		JR	DrawBottomEdge
FC_11:		PUSH	AF
		SUB	B
		NEG
FC_12:		CALL	DrawBottomEdge
		POP	AF
		RET	Z
		JP	(IY)		; Clear A rows at DE'
FC_Clear2:	LD	A,B
		JP	(IY)		; Clear A rows at DE'
FC_14:		ADD	A,B
		JR	C,FloorCall5
		LD	A,B
	;; NB: Fall through

BlitFloorFnPtr:	JP	L0000		; NB: Target of self-modifying code

FloorCall5:	PUSH	AF
		SUB	B
		NEG
		CALL	BlitFloorFnPtr
		POP	AF
		RET	Z
		SUB	$0B
		LD	E,$00
		JR	NC,FC_16
		ADD	A,$0B
		JR	DrawBottomEdge
FC_16:		PUSH	AF
		LD	A,$0B
		JR	FC_12
	;; NB: Fall through

	;; Takes starting row number in E, number of rows in A, destination in DE'
DrawBottomEdge:	PUSH	DE
		EXX
		POP	HL
		LD	H,$00
		ADD	HL,HL
		LD	BC,LeftEdge
WhichEdge:	JR	FC_18		; NB: Target of self-modifying code.
FC_17:		LD	BC,RightEdge
		JR	FC_18
		LD	BC,CornerEdge 	; FIXME: Maybe gets rewritten?
FC_18:		ADD	HL,BC
		EXX
	;; Copies from HL' to DE', number of rows in A.
		JP	(IX)		; NB: Tail call to copy data

	;; FIXME: Export as images?
LeftEdge:	DEFB $40,$00,$70,$00,$74,$00,$77,$00,$37,$40,$07
		DEFB $70,$03,$74,$00,$77,$00,$37,$00,$07,$00,$03
RightEdge:	DEFB $00,$01,$00,$0d,$00,$3d,$00,$7d,$01,$7c,$0d
		DEFB $70,$3d,$40,$7d,$00,$7c,$00,$70,$00,$40,$00
CornerEdge:	DEFB $40,$01,$70,$0d,$74,$3d,$77,$7d,$37,$7c,$07
		DEFB $70,$03,$40,$00,$00,$00,$00,$00,$00,$00,$00

	;; FIXME: Some function to do with floor stuff
	;; Floor tiles are 2x24
	;; I think it may be stitching together a corner-case sprite?
FloorFn:	LD		HL,(FloorAddr)
		LD		(RoomOrigin),BC
		LD		BC,2*5
		ADD		HL,BC 		; Move 5 rows into the tile
		LD		C,2*8
		LD		A,(L7717)
		RRA
		PUSH		HL 		; Push this address.
		JR		NC,FF_1		; If bottom bit of L7717 is set...
		ADD		HL,BC
		EX		(SP),HL 	; Move 8 rows further on the stack-saved pointer
FF_1:		ADD		HL,BC		; In any case, move 8 rows on HL...
		RRA
		JR		NC,FF_2 	; Unless the next bit of L7717 was set
		AND		A
		SBC		HL,BC
FF_2:		LD		DE,RightEdge 	; Call once...
		CALL		FloorFnInner
		POP		HL
		INC		HL
		LD		DE,LeftEdge+1 	; then again with saved address.
	;; NB: Fall through

	;; Copy 4 bytes, skipping every second byte.
FloorFnInner:	LD		A,$04
FF_3:		LDI
		INC		HL
		INC		DE
		DEC		A
		JR		NZ,FF_3
		RET

L9D77:	PUSH	AF
		LD		A,(HL)
		EXX
		CALL	GetWall
		POP		AF
		ADD		A,L
		LD		L,A
		RET		NC
		INC		H
		RET
	
IsColBufFilled:	DEFB $00

	;; Returns ColBuf in HL.
	;; If IsColBufFilled is non-zero, it zeroes the buffer, and the flag.
GetEmptyColBuf:	LD	A,(IsColBufFilled)
		AND	A
		LD	HL,ColBuf
		RET	Z
		PUSH	HL
		PUSH	BC
		PUSH	DE
		LD	BC,ColBufLen
		CALL	FillZero
		POP	DE
		POP	BC
		POP	HL
		XOR	A
		LD	(IsColBufFilled),A
		RET

	;; Called by GetWall for high-index sprites.
GetHighWall:	BIT	0,A			; Low bit zero? Return cleared buffer.
		JR	NZ,GetEmptyColBuf	; Tail call
		LD	L,A
	;; Otherwise, we're drawing a column
		LD	A,(IsColBufFilled)
		AND	A
		CALL	Z,FillColBuf
		LD	A,(IsColBufFlipped)
		XOR	L
		RLA
	;; Carry set if we need to flip and update flag to match request...
		LD	HL,ColBuf
		RET	NC			; Return ColBuf if no flip required...
		LD	A,(IsColBufFlipped)	; Otherwise, flip flag and buffer.
		XOR	$80
		LD	(IsColBufFlipped),A
		LD	B,$4A
		JP	FlipSprite 		; Tail call

	
	;; Get a wall section thing.
	;; Index in A. Top bit represents whether flip is required.
	;; Destination returned in HL.
GetWall:	BIT	2,A		; 4-7 handled by GetHighWall.
		JR	NZ,GetHighWall
		PUSH	AF
		CALL	NeedsFlip2 	; Check if flip is required
		EX	AF,AF'
		POP	AF
		CALL	GetPanelAddr 	; Get the address
		EX	AF,AF'
		RET	NC		; Flip the data only if required.
		JP	FlipPanel 	; Tail call


	;; Takes a sprite index in A. Looks up low three bits in the bitmap.
	;; If the top bit was set, we flip the bit if necessary to match,
	;; and return carry if a bit flip was needed.
	;;
	;; Rather similar to 'NeedsFlip'.
NeedsFlip2:	LD		C,A
		LD		HL,(PanelFlipsPtr)
		AND		$03
	;; A = 1 << A
		LD		B,A
		INC		B
		LD		A,$01
NF2_1:		RRCA
		DJNZ		NF2_1
	;; Check if that bit of (HL) is set
		LD		B,A
		AND		(HL)
		JR		NZ,NF2_2
	;; It isn't. Was top bit if param set?
		RL		C
		RET		NC 	; No - return with carry reset
	;; It was. So, set bit and return with carry flag set.
		LD		A,B
		OR		(HL)
		LD		(HL),A
		SCF
		RET
	;; Top bit was set. Is bit set?
NF2_2:		RL		C
		CCF
		RET		NC 	; Yes - return with carry reset
	;; No. So reset bit and return with carry flag set.
		LD		A,B
		CPL
		AND		(HL)
		LD		(HL),A
		SCF
		RET

DoCopy:		JP	(IX)	; Call the copying function
DoClear:	JP	(IY)	; Call the clearing function

	;; Zero a single column of the 6-byte-wide buffer at DE'.
ClearOne:	EXX
		LD	B,A
		EX	DE,HL
		LD	E,$00
CO_1:		LD	(HL),E
		LD	A,L
		ADD	A,$06
		LD	L,A
		DJNZ	CO_1
		EX	DE,HL
		EXX
		RET

	;; Zero two columns of the 6-byte-wide buffer at DE'.
ClearTwo:	EXX
		LD	B,A
		EX	DE,HL
		LD	E,$00
CT_1:		LD	(HL),E
		INC	L
		LD	(HL),E
		LD	A,L
		ADD	A,$05
		LD	L,A
		DJNZ	CT_1
		EX	DE,HL
		EXX
		RET

	;; Set FloorAddr to the floor sprite indexed in A.
SetFloorAddr:	LD	C,A
		ADD	A,A
		ADD	A,C
		ADD	A,A
		ADD	A,A
		ADD	A,A
		LD	L,A
		LD	H,$00
		ADD	HL,HL		; x $30 (floor tile size)
		LD	DE,IMG_2x24 - MAGIC_OFFSET	; The floor tile images.
		ADD	HL,DE	 	; Add to floor tile base.
		LD	(FloorAddr),HL
		RET

	;; Address of the sprite used to draw the floor.
FloorAddr:	DEFW IMG_2x24 - MAGIC_OFFSET + 2 * $30

	;; HL points to some thing we read the bottom two bits of.
	;; If they're set, we return the blank tile.
	;; Otherwise we return the current tile address pointer, plus C, in BC.
GetFloorAddr:	PUSH	AF
		EXX
		LD	A,(HL)
		OR	$FA	
		INC	A	; If bottom two bits are set...
		EXX
		JR	Z,GFA_1	; jump.
		LD	A,C
		LD	BC,(FloorAddr)
		ADD	A,C	; Add old C to FloorAddr and return in BC.
		LD	C,A
		ADC	A,B
		SUB	C
		LD	B,A
		POP	AF
		RET
GFA_1:		LD	BC,IMG_2x24 - MAGIC_OFFSET + 7 * $30
		POP	AF
		RET

	;; Fill a 6-byte-wide buffer at DE' with both columns of a background tile.
	;; A  contains number of rows to generate.
	;; D  contains initial offset in rows.
	;; HL and HL' contain pointers to flags.
BlitFloor:	LD	B,A
		LD	A,D
	;; Move down 8 rows if top bit of (HL) is set.
		BIT	7,(HL)
		EXX
		LD	C,0
		JR	Z,BF_1
		LD	C,2*8
	;; Get the address (using HL' for flags)
BF_1:		CALL	GetFloorAddr
	;; Construct offset in HL from original D. Double it as tile is 2 wide.
		AND	$0F
		ADD	A,A
		LD	H,$00
		LD	L,A
		EXX
	;; At this point we have source in BC', destination in DE',
	;; offset of source in HL', and number of rows to copy in B.
BF_2:		EXX
		PUSH	HL
	;; Copy both bytes of the current row into the 6-byte-wide buffer.
		ADD	HL,BC
		LD	A,(HL)
		LD	(DE),A
		INC	HL
		INC	E
		LD	A,(HL)
		LD	(DE),A
		LD	A,E
		ADD	A,$05
		LD	E,A
		POP	HL
		LD	A,L
		ADD	A,$02
		AND	$1F
		LD	L,A
		EXX
		DJNZ	BF_2
		RET

	;; Fill a 6-byte-wide buffer at DE' with the right column of background tile.
	;; A  contains number of rows to generate.
	;; D  contains initial offset in rows.
	;; HL and HL' contain pointers to flags.
BlitFloorR:	LD	B,A
		LD	A,D
	;; Move down 8 rows if top bit of (HL) is set.
	;; Do the second column of the image (the extra +1)
		BIT	7,(HL)
		EXX
		LD	C,1
		JR	Z,BFL_1
		LD	C,2*8+1
		JR	BFL_1

	;; Fill a 6-byte-wide buffer at DE' with the left column of background tile.
	;; A  contains number of rows to generate.
	;; D  contains initial offset in rows.
	;; HL and HL' contain pointers to flags.
BlitFloorL:	LD	B,A
		LD	A,D
	;; Move down 8 rows if top bit of (HL) is set.	
		BIT	7,(HL)
		EXX
		LD	C,$00
		JR	Z,BFL_1
		LD	C,$10
	;; Get the address (using HL' for flags)
BFL_1:		CALL	GetFloorAddr
	;; Construct offset in HL from original D. Double it as tile is 2 wide.
		AND	$0F
		ADD	A,A
		LD	H,$00
		LD	L,A
		EXX
	;; At this point we have source in BC', destination in DE',
	;; offset of source in HL', and number of rows to copy in B.
BFL_2:		EXX
		PUSH	HL
	;; Copy 1 byte into 6-byte-wide buffer
		ADD	HL,BC
		LD	A,(HL)
		LD	(DE),A
		LD	A,E
		ADD	A,$06
		LD	E,A
		POP	HL
		LD	A,L
		ADD	A,$02
		AND	$1F
		LD	L,A	; Add 1 row to source offset pointer, mod 32
		EXX
		DJNZ	BFL_2
		RET

	;; Blit from HL' to DE', right byte of a 2-byte-wide sprite in a 6-byte wide buffer.
	;; Number of rows in A.
OneColBlitR:	EXX
		INC	HL
		JR	OCB_1
	
	;; Blit from HL' to DE', left byte of a 2-byte-wide sprite in a 6-byte wide buffer.
	;; Number of rows in A.
OneColBlitL:	EXX
OCB_1:		LD	B,A
OCB_2:		LD	A,(HL)
		LD	(DE),A
		INC	HL
		INC	HL
		LD	A,E
		ADD	A,$06
		LD	E,A
		DJNZ	OCB_2
		EXX
		RET


	;; Blit from HL' to DE', a 2-byte-wide sprite in a 6-byte wide buffer.
	;; Number of rows in A.
TwoColBlit:	EXX
		LD	B,A
TCB_1:		LD	A,(HL)
		LD	(DE),A
		INC	HL
		INC	E
		LD	A,(HL)
		LD	(DE),A
		INC	HL
		LD	A,E
		ADD	A,$05
		LD	E,A
		DJNZ	TCB_1
		EXX
		RET

	;; Flip a 56-byte-high wall panel
FlipPanel:	LD		B,$38
	;; Reverse a two-byte-wide image. Height in B, pointer to data in HL.
FlipSprite:	PUSH	DE
		LD	D,RevTable >> 8
		PUSH	HL
FS_1:		INC	HL
		LD	E,(HL)
		LD	A,(DE)
		DEC	HL
		LD	E,(HL)
		LD	(HL),A
		INC	HL
		LD	A,(DE)
		LD	(HL),A
		INC	HL
		DJNZ	FS_1
		POP	HL
		POP	DE
		RET

	;; Top bit is set if the column image buffer is flipped
IsColBufFlipped:	DEFB $00

	;; Return the panel address in HL, given panel index in A.
GetPanelAddr:	AND	$03	; Limit to 0-3
		ADD	A,A
		ADD	A,A
		LD	C,A 	; 4x
		ADD	A,A
		ADD	A,A
		ADD	A,A	; 32x
		SUB	C	; 28x
		ADD	A,A	; 56x
		LD	L,A
		LD	H,$00	; 112x
		ADD	HL,HL
		LD	BC,(PanelBase)
		ADD	HL,BC	; Add on to contents of PanelBase and return.
		RET
