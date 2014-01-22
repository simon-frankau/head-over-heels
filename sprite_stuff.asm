	;; 
	;; sprite_stuff.asm
	;;
	;; Various sprite-related pieces that need further investigation
	;;
	;; FIXME: To reverse!
	;; 

	;; FIXME: Win screen
L8D9E:		LD	A,(L866B)
		CP	$1F
		JR	NZ,L8DB9
		LD	A,STR_WIN_SCREEN
		CALL	PrintChar
		CALL	AltPlaySound
		LD	DE,L040F
		LD	HL,MainMenuSpriteList
		CALL	DrawFromList
		CALL	C8DDF
L8DB9:		CALL	C8DC2
		CALL	C7395
		JP	C7BB3

	;; FIXME: Crowns screen?
C8DC2:		LD	A,STR_EMPIRE_BLURB
		CALL	PrintChar
		CALL	AltPlaySound
		LD	HL,PlanetsSpriteList
		LD	DE,L05FF
		CALL	DrawFromList
		LD	HL,CrownsSpriteList
		LD	DE,(L866B)
		LD	D,$05
		CALL	DrawFromList
C8DDF:		CALL	WaitInputClear
		CALL	C8DED
		CALL	ScreenWipe
		LD	B,$C1
		JP	PlaySound

C8DED:		LD	HL,LA800
L8DF0:		PUSH	HL
		CALL	AltPlaySound
		CALL	GetInputEntSh
		POP	HL
		RET	NC		; Return if key was pressed.
		DEC	HL
		LD	A,H
		OR	L
		JR	NZ,L8DF0
		RET
	
PlanetsSpriteList:	DEFB SPR_BALL,$54,$78
			DEFB SPR_BALL,$A4,$78
			DEFB SPR_BALL,$54,$E8
			DEFB SPR_BALL,$A4,$E8
			DEFB SPR_BALL,$7C,$B0
	
CrownsSpriteList:	DEFB SPR_CROWN,$54,$60
			DEFB SPR_CROWN,$A4,$60
			DEFB SPR_CROWN,$54,$D0
			DEFB SPR_CROWN,$A4,$D0
			DEFB SPR_CROWN,$7C,$98

	;; FIXME: Draw the screen border stuff?
C8E1D:		CALL	CharThing17
		LD	HL,PeripherySpriteList
		LD	DE,(LA28B)
		LD	D,$03
		CALL	DrawFromList
		LD	DE,(Character)
	;; NB: Fall through
	
Draw2FromList:	LD	D,$02
	;; NB: Fall through

	;; Load D with number of sprites
	;; Load E with bitmask for doing some thing.
	;; Load HL with pointer to data
	;; Data should contain: Sprite code (1 byte), Coordinates (2 bytes)
DrawFromList:	LD	A,(HL)
		INC	HL
		LD	C,(HL)
		INC	HL
		LD	B,(HL)
		INC	HL
		PUSH	HL
		RR	E
		PUSH	DE
		JR	NC,L8E47
		CALL	Draw3x24
L8E41:		POP	DE
		POP	HL
		DEC	D
		JR	NZ,DrawFromList
		RET
L8E47:		LD	D,$01
		CALL	C8E5F
		JR	L8E41

	;; All the icons around the edge of the screen
PeripherySpriteList:	DEFB SPR_PURSE,            $B0,$F0
			DEFB SPR_HOOTER,           $44,$F0
			DEFB SPR_DONUTS,           $44,$D8
			DEFB SPR_HEELS1 | SPR_FLIP,$94,$F0
			DEFB SPR_HEAD1,            $60,$F0

	;; FIXME: Very spritey
L8E5D:		LD	D,$03
	
	;; Sprite code in A. Something in D moved to A, BC saved.
	;; We load HL with 180C, DE with image, A with thing, call DrawSprite
C8E5F:		LD	(SpriteCode),A
		LD	A,B
		SUB	$48
		LD	B,A
		PUSH	DE
		PUSH	BC
		CALL	GetSpriteAddr
		LD	HL,L180C
		POP	BC
		POP	AF
		AND	A
		JP	DrawSprite

	;; Draw a 3 byte x 24 row sprite on clear background.
	;; Takes sprite code in A, coordinates in BC.
Draw3x24:	LD	L,$00
		DEC	L
		INC	L
		JR	Z,L8E5D			; FIXME: Not sure what that's about
		LD	(SpriteCode),A
		CALL	SetExtents3x24
		CALL	ClearSpriteBuf
		CALL	GetSpriteAddr
		LD	BC,SpriteBuff
		EXX
		LD	B,$18
		CALL	BlitMask3of3
		JP	BlitScreen

	;; Takes coordinates in BC, and clears a 3x24 section of display
Clear3x24:	CALL	SetExtents3x24
		CALL	ClearSpriteBuf
		JP	BlitScreen

	;; Set up the extent information for a 3 byte x 24 row sprite
	;; Y coordinate in B, X coordinate in C
SetExtents3x24:	LD	H,C
		LD	A,H
		ADD	A,$0C
		LD	L,A
		LD	(SpriteXExtent),HL
		LD	A,B
		ADD	A,$18
		LD	C,A
		LD	(SpriteYExtent),BC
		RET

	;; Draw a 3 byte x 32 row sprite on clear background.
	;; Takes sprite code in A, coordinates in BC.
Draw3x32:	LD	(SpriteCode),A
		CALL	SetExtents3x24
		LD	A,B
		ADD	A,$20
		LD	(SpriteYExtent),A	; Set adjusted extents.
		CALL	ClearSpriteBuf 		; Clear buffer
		LD	A,$02
		LD	(SpriteFlags),A 	; FIXME: ?
		CALL	GetSpriteAddr
		LD	BC,SpriteBuff
		EXX
		LD	B,$20
		CALL	BlitMask3of3 		; Draw into buffer.
		JP	BlitScreen		; Buffer to screen.

ClearSpriteBuf:	LD	HL,SpriteBuff
		LD	BC,L0100
		JP	FillZero 	; Tail call
