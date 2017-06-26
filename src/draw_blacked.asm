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
		CALL	DrawXSafe       ; X extent known to be in range.
		POP	DE
		POP	HL
		LD	H,L
		LD	A,L
		ADD	A,$14           ; First window is 8 wide, subsequent are 20.
		LD	L,A
		CP	$C1             ; Loop across the visible core of the screen.
		JR	C,DBL_1
		LD	HL,$4048
		LD	D,E
		LD	A,E
		ADD	A,$2A           ; First window is 15, subsequent are 42.
		LD	E,A             ; Loop all the way to row 255!
		JR	NC,DBL_1
		RET
