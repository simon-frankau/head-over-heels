	;; 
	;; controls.asm
	;;
	;; Control configuration and reading functions
	;;
	;; FIXME: Needs more analysis
	;; 


DELIM:	EQU $FF			; String delimiter
	
	;; Strings table for indices >= 0x60 (i.e. 0xE0 once the top bit is set).
Strings2:
STR_ENTER:	EQU $E0
			DEFB DELIM,"ENTER"
STR_SSH:	EQU $E1
			DEFB DELIM,CTRL_ATTR3,"SSH"
STR_JOY_MENU:	EQU $E2
			DEFB DELIM,CTRL_WIPE_SETPOS,$09,$00
			DEFB CTRL_ATTRMODE,$09,CTRL_ATTR2
			DEFB STR_SELECT,STR_JOYSTICK,STR_MENU_BLURB
STR_JOYSTICK:	EQU $E3
			DEFB DELIM," JOYSTICK"
	;; Joystick menu
STR_KEYSTICK:	EQU $E4
			DEFB DELIM,STR_KEY,"S/",STR_KEY,STR_JOYSTICK
STR_KEMPSTON:	EQU $E5
			DEFB DELIM,"KEMPSTON",STR_JOYSTICK
STR_FULLER:	EQU $E6
			DEFB DELIM,"FULLER",STR_JOYSTICK
	;; End of menu
STR_JOY:	EQU $E7
			DEFB DELIM,CTRL_ATTR1,"JOY"
STR_F:		EQU $E8
			DEFB DELIM,STR_JOY,"F"
STR_U:		EQU $E9
			DEFB DELIM,STR_JOY,"U"
STR_D:		EQU $EA
			DEFB DELIM,STR_JOY,"D"
STR_R:		EQU $EB
			DEFB DELIM,STR_JOY,"R"
STR_L:		EQU $EC
			DEFB DELIM,STR_JOY,"L"
STR_SPC:	EQU $ED
			DEFB DELIM,CTRL_ATTR3,"SPC"
			DEFB DELIM

CharSet:	DEFB STR_SHIFT,"ZXCVASDFGQWERT1234509876POIUY"
		DEFB STR_ENTER2,"LKJH",STR_SPC,STR_SSH,"MNB"
		DEFB STR_F,STR_U,STR_D,STR_R,STR_L

L74D2:	DEFB $FF,$FF,$FF,$FF,$FF,$FF,$E0,$FF
	DEFB $FF,$FF,$FE,$FF,$FF,$FF,$FF,$E1
	DEFB $FF,$FF,$FF,$FE,$FF,$FF,$FF,$FF
	DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	DEFB $EF,$F7,$FB,$FD,$FE,$FF,$FF,$FF
	DEFB $FD,$FE,$FF,$FF,$FF,$FF,$FF,$FF
	DEFB $FF,$FF,$FF,$FF,$FF,$F0,$FF,$FF
	DEFB $FF,$FF,$FF,$FF,$E0,$FE,$FF,$FF
	DEFB $EF,$F7,$FB,$FD,$FE,$FF,$FF,$FF

	;; FIXME: Suspect this is the stick-select screen
GoStickMenu:	LD	A,STR_JOY_MENU
		CALL	PrintChar
		LD	IX,MENU_STICK
		CALL	DrawMenu
SelSt_1:	CALL	MenuStep
		JR	C,SelSt_1
		RET
	
MENU_STICK:	DEFB $00		; Selected menu item
		DEFB $03		; 3 items
		DEFB $04		; Initial column
		DEFB $08		; Initial row
		DEFB STR_KEYSTICK	; Keyboard, Kempston, Fuller
	
InitStick:	LD	B,$04
IS_1:		IN	A,($1F)			; Kempston port
		AND	$1F
		CP	$1F
		JR	NC,IS_2
		DJNZ	IS_1
IS_2:		SBC	A,A
		AND	$01
		LD	(MENU_STICK),A
		CALL	GoStickMenu
		LD	A,(MENU_STICK)
		SUB	$01
		RET	C			; MENU_STICK = 0: Keyboard, return
		LD	HL,Kempston
		JR	Z,IS_3			; MENU_STICK = 1: Kempston
		LD	HL,Fuller		; MENU_STICK = 2: Fuller
IS_3:		LD	(InputThingJoy+1),HL	; Install joystick hooks
		LD	(StickCall+1),HL
		XOR	A
		LD	(GI_Noppable),A		; NOP the RET to fall through
		LD	A,$CD
		LD	(InputThing),A 		; Make it into a 'CALL', so that it returns.
		RET

	;;  Joystick handler for Kempston
Kempston:	IN	A,($1F)
		LD	B,A
		RRCA
		RRA
		RL	C
		RLCA
		RL	C
		RRA
		RRA
		RL	C
		RRA
		RL	C
		RRA
		RL	C
		LD	A,C
		CPL
		OR	$E0
		RET

	;;  Joystick handler for Fuller
Fuller:		IN	A,($7F)
		LD	C,A
		RLCA
		XOR	C
		AND	$F7
		XOR	C
		RL	C
		RL	C
		XOR	C
		AND	$EF
		XOR	C
		OR	$E0
		RET

	;; FIXME: Work out precisely what this is doing...
GetInput:	LD		HL,LBF20
		LD		BC,LFEFE
GI_1:		IN		A,(C)
		OR		$E0
		INC		A
		JR		NZ,GI_2
		INC		HL
		RLC		B
		JR		C,GI_1
		INC		A
GI_Noppable:	RET				; May get overwritten for fall-through.
StickCall:	CALL		Kempston
		INC		A
		JR		NZ,GI_2
		DEC		A
		RET
GI_2:		DEC		A
		LD		BC,LFF7F
GI_3:		RLC		C
		INC		B
		RRA
		JR		C,GI_3
		LD		A,L
		SUB		$20
		LD		E,A
		ADD		A,A
		ADD		A,A
		ADD		A,E
		ADD		A,B
		LD		B,A
		XOR		A
		RET

	;; Given an index in B, get the string identifier for it in A.
GetCharStrId:	LD		A,B
		ADD		A,CharSet & $FF
		LD		L,A
		ADC		A,CharSet >> 8
		SUB		L
		LD		H,A
		LD		A,(HL)
		RET

	;;  Like GetInput, but blocking.
GetInputWait:	CALL	GetInput
		JR	Z,GetInputWait
		RET

	;; Checks keys.
	;; Carry is set if nothing was detected
	;; Returns zero in C if enter was detected
	;;
	;; FIXME: Reverse how this actually works!
GetMaybeEnter:	CALL	GetInput
		SCF
		RET	NZ
		LD	A,B
		LD	C,$00
		CP	$1E
		RET	Z
		INC	C
		AND	A
		RET	Z
		CP	$24
		RET	Z
		INC	C
		XOR	A
		RET

L75E5:		LD	DE,L74D2
		LD	L,A
		LD	H,$00
		ADD	HL,DE
		RET

L75ED:		CALL	L75E5
		LD	C,$00
L75F2:		LD	A,(HL)
		LD	B,$FF
L75F5:		CP	$FF
		JR	Z,L760F
L75F9:		INC	B
		SCF
		RRA
		JR	C,L75F9
		PUSH	HL
		PUSH	AF
		LD	A,C
		ADD	A,B
		PUSH	BC
		LD	B,A
		CALL	GetCharStrId
		CALL	PrintCharAttr2
		POP	BC
		POP	AF
		POP	HL
		JR	L75F5
L760F:		LD	DE,L0008
		ADD	HL,DE
		LD	A,C
		ADD	A,$05
		LD	C,A
		CP	$2D
		JR	C,L75F2
		RET

L761C:		CALL	L75E5
		PUSH	HL
		CALL	GetInputWait
		LD	HL,LBF20
		LD	E,$FF
		LD	BC,L0009
		CALL	FillValue
L762E:		CALL	GetInput
		JR	NZ,L762E
		LD	A,B
		CP	$1E
		JR	Z,L765B
L7638:		LD	A,C
		AND	(HL)
		CP	(HL)
		LD	(HL),A
		JR	Z,L762E
		CALL	GetCharStrId
		CALL	PrintCharAttr2
		LD	HL,(CharCursor)
		PUSH	HL
		LD	A,STR_ENTER_TO_FINISH
		CALL	PrintChar
		CALL	GetInputWait
		POP	HL
		LD	(CharCursor),HL
		LD	A,$C0
		SUB	L
		CP	$14
		JR	NC,L762E
L765B:		EXX
		LD	HL,LBF20
		LD	A,$FF
		LD	B,$09
L7663:		CP	(HL)
		INC	HL
		JR	NZ,L766E
		DJNZ	L7663
		EXX
		LD	A,$1E
		JR	L7638
L766E:		POP	HL
		LD	BC,L0008
		LD	A,$09
		LD	DE,LBF20
L7677:		EX	AF,AF'
		LD	A,(DE)
		LD	(HL),A
		INC	DE
		ADD	HL,BC
		EX	AF,AF'
		DEC	A
		JR	NZ,L7677
		JP	GetInputWait

PrintCharAttr2:	PUSH	AF
		LD	A,CTRL_ATTR2
		CALL	PrintChar
		POP	AF
		JP	PrintChar
