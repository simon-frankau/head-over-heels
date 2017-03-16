	;; 
	;; Columns.asm
	;;
	;; TODO: Stuff to do with columns
	;;

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
