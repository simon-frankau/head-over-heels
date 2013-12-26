	;; BlitScreenN copies an N-byte-wide image to the screen.
	;; Copy from HL to DE, height in B.
	
	;; Assumes HL buffer is 6 bytes wide, and DE is a screen
	;; location (no clipping).

BlitScreen1:	LDI
		INC	L
		INC	L
		INC	L
		INC	L
		INC	L
		DEC	DE
		INC	D
		LD	A,D
		AND	$07
		JR	Z,BlitScreen1Adj
		DJNZ	BlitScreen1
		RET
	;; This bit deals with the update every eight-line
	;; boundary. In short, it adds 32 onto the low-byte, and removes
	;; 8 onto the top byte (going back in the interleaved fashion)
	;; unless we had a carry, in which case it's onto the next screen
	;; third so we don't subtract anything.
BlitScreen1Adj:	LD	A,E
		ADD	A,$20
		LD	E,A
		CCF
		SBC	A,A
		AND	$F8
		ADD	A,D
		LD	D,A
		DJNZ	BlitScreen1
		RET

BlitScreen2:	LDI
		LDI
		INC	L
		INC	L
		INC	L
		INC	L
		DEC	DE
		DEC	E
		INC	D
		LD	A,D
		AND	$07
		JR	Z,BlitScreen2Adj
		DJNZ	BlitScreen2
		RET
BlitScreen2Adj:	LD	A,E
		ADD	A,$20
		LD	E,A
		CCF
		SBC	A,A
		AND	$F8
		ADD	A,D
		LD	D,A
		DJNZ	BlitScreen2
		RET

BlitScreen3:	LDI
		LDI
		LDI
		INC	L
		INC	L
		INC	L
		DEC	DE
		DEC	E
		DEC	E
		INC	D
		LD	A,D
		AND	$07
		JR	Z,BlitScreen3Adj
		DJNZ	BlitScreen3
		RET
BlitScreen3Adj:	LD	A,E
		ADD	A,$20
		LD	E,A
		CCF
		SBC	A,A
		AND	$F8
		ADD	A,D
		LD	D,A
		DJNZ	BlitScreen3
		RET

BlitScreen4:	LDI
		LDI
		LDI
		LDI
		INC	L
		INC	L
		DEC	DE
		DEC	E
		DEC	E
		DEC	E
		INC	D
		LD	A,D
		AND	$07
		JR	Z,BlitScreen4Adj
		DJNZ	BlitScreen4
		RET
BlitScreen4Adj:	LD	A,E
		ADD	A,$20
		LD	E,A
		CCF
		SBC	A,A
		AND	$F8
		ADD	A,D
		LD	D,A
		DJNZ	BlitScreen4
		RET

BlitScreen5:	PUSH	DE
		LDI
		LDI
		LDI
		LDI
		LDI
		INC	L
		POP	DE
		INC	D
		LD	A,D
		AND	$07
		JR	Z,BlitScreen5Adj
		DJNZ	BlitScreen5
		RET
BlitScreen5Adj:	LD	A,E
		ADD	A,$20
		LD	E,A
		CCF
		SBC	A,A
		AND	$F8
		ADD	A,D
		LD	D,A
		DJNZ	BlitScreen5
		RET
	
BlitScreen6:	PUSH	DE
		LDI
		LDI
		LDI
		LDI
		LDI
		LDI
		POP	DE
		INC	D
		LD	A,D
		AND	$07
		JR	Z,BlitScreen6Adj
		DJNZ	BlitScreen6
		RET
BlitScreen6Adj:	LD	A,E
		ADD	A,$20
		LD	E,A
		CCF
		SBC	A,A
		AND	$F8
		ADD	A,D
		LD	D,A
		DJNZ	BlitScreen6
		RET
