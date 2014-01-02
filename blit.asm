	;;
	;; blit.asm
	;;
	;; Masked blit into an offscreen buffer.
	;;

	;; Exported functions:
	;; * Blit3of3

	;; BlitNofM does a masked blit into a destination buffer assumed 6 bytes wide.
	;; The blit is from a source N bytes wide in a buffer M bytes wide.
	;; The height is in B.
	;; Destination is BC', source image is in DE', mask is in HL'.

Blit1of3:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		LD	A,C
		ADD	A,$06
		LD	C,A
		INC	HL
		INC	DE
		INC	HL
		INC	DE
		EXX
		DJNZ	Blit1of3
		RET

Blit2of3:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		LD	A,C
		ADD	A,$05
		LD	C,A
		INC	HL
		INC	DE
		EXX
		DJNZ	Blit2of3
		RET

Blit3of3:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		LD	A,C
		ADD	A,$04
		LD	C,A
		EXX
		DJNZ	Blit3of3
		RET

Blit1of4:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		LD	A,C
		ADD	A,$06
		LD	C,A
		INC	HL
		INC	DE
		INC	HL
		INC	DE
		INC	HL
		INC	DE
		EXX
		DJNZ	Blit1of4
		RET

Blit2of4:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		LD	A,C
		ADD	A,$05
		LD	C,A
		INC	HL
		INC	DE
		INC	HL
		INC	DE
		EXX
		DJNZ	Blit2of4
		RET
	
Blit3of4:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		LD	A,C
		ADD	A,$04
		LD	C,A
		INC	HL
		INC	DE
		EXX
		DJNZ	Blit3of4
		RET

Blit4of4:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		INC	C
		INC	C
		INC	C
		EXX
		DJNZ	Blit4of4
		RET

Blit1of5:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		LD	A,C
		ADD	A,$06
		LD	C,A
		INC	HL
		INC	DE
		INC	HL
		INC	DE
		INC	HL
		INC	DE
		INC	HL
		INC	DE
		EXX
		DJNZ	Blit1of5
		RET

Blit2of5:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		LD	A,C
		ADD	A,$05
		LD	C,A
		INC	HL
		INC	DE
		INC	HL
		INC	DE
		INC	HL
		INC	DE
		EXX
		DJNZ	Blit2of5
		RET

Blit3of5:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		LD	A,C
		ADD	A,$04
		LD	C,A
		INC	HL
		INC	DE
		INC	HL
		INC	DE
		EXX
		DJNZ	Blit3of5
		RET

Blit4of5:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		INC	C
		INC	C
		INC	C
		INC	HL
		INC	DE
		EXX
		DJNZ	Blit4of5
		RET

Blit5of5:	EXX
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	C
		INC	HL
		INC	DE
		LD	A,(BC)
		AND	(HL)
		EX	DE,HL
		OR	(HL)
		EX	DE,HL
		LD	(BC),A
		INC	HL
		INC	DE
		INC	C
		INC	C
		EXX
		DJNZ	Blit5of5
		RET
