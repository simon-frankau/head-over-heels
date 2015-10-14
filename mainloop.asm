	;;
	;;  mainloop.asm
	;;
	;;  The main game loop and some associated functions
	;;
	
	;; Main entry point
Entry:		LD	SP,$FFF4
		CALL	InitStuff
		CALL	InitStick
		JR	Main

L703B:		DEFB $00
L703C:		DEFB $00
L703D:		DEFB $00
LastDir:	DEFB $EF
CurrDir:	DEFB $FF
CarryPressed:	DEFB $00	; Bit 1 means 'currently pressed'. Bit 0 is 'newly triggered'.
SwopPressed:	DEFB $00	; Ditto
FirePressed:	DEFB $00	; Ditto
FrameCounter:	DEFB $01
L7044:		DEFB $FB,$FB
FinishGame:	CALL	GameOverScreen

Main:		LD	SP,$FFF4
		CALL	GoMainMenu
		JR	NC,MainContinue
		CALL	InitNewGame
		JR	MainStart
MainContinue:	CALL	AltPlaySound
		CALL	InitContinue
MainStart:	CALL	C8DC2
		LD	A,$40
		LD	(L8F18),A
MainB:		XOR	A
		LD	(L703D),A
		CALL	C7B91
	;; The main game-playing loop
MainLoop:	CALL	WaitFrame
		CALL	CheckCtrls
		CALL	MainLoop2
		CALL	DoObjects
		CALL	CheckPause
		CALL	CheckSwop
        ;; Play sound if there is one.
		LD	HL,SoundId
		LD	A,(HL)
		SUB	$01
		LD	(HL),$00
		LD	B,A
		CALL	NC,PlaySound
		JR	MainLoop

	;; FIXME: ???
C708B:		LD	HL,(L703B)
		LD	BC,$8D30 ; TODO
		XOR	A
		SBC	HL,BC
		RET

	;; FIXME: ???
MainLoop2:	CALL	C708B
		RET	NZ
		LD	(SwopPressed),A
		DEC	A
		LD	(CurrDir),A
		LD	HL,L8F18
		DEC	(HL)
		LD	A,(HL)
		INC	A
		JP	Z,FinishGame
		LD	B,$C1
		CP	$30
		PUSH	AF
		CALL	Z,PlaySound
		POP	AF
		AND	$01
		LD	A,STR_FREEDOM
		CALL	Z,PrintChar
		RET

	;; FIXME: ???
L70BA:		LD	HL,L703C
		LD	A,(LB218)
		DEC	A
		CP	$06
		JR	Z,L70EC
		JR	NC,L70E6
		CP	$04
		JR	C,L70CF
		ADD	A,A
		XOR	$02
		DEC	HL
L70CF:		LD	C,$01
		BIT	1,A
		JR	NZ,L70D7
		LD	C,$FF
L70D7:		RRA
		JR	C,L70E1
		RLD
		ADD	A,C
		RRD
		JR	L70E6
L70E1:		RRD
		ADD	A,C
		RLD
L70E6:		LD	SP,$FFF4
		JP	MainB
L70EC:		CALL	CAD26
		JR	L70E6

	;; Wait for the frame counter to reduce to zero
WaitFrame:	LD	A,(FrameCounter)
		AND	A
		JR	NZ,WaitFrame
	;; 12.5 FPS, then.
		LD	A,$04
		LD	(FrameCounter),A
		RET

	;; Checks for pausing key, and if it's pressed, pauses. 
CheckPause:	CALL	IsHPressed
		RET	NZ
	;; Play pause sound
		LD	B,$C0
		CALL	PlaySound
	;; Display pause message...
		CALL	WaitInputClear
		LD	A,STR_FINISH_RESTART
		CALL	PrintChar
	;; Wait for a key...
CP_1:		CALL	GetInputEntSh
		JR	C,CP_1
		DEC	C
		JP	Z,FinishGame		; Pressed a shift key.
	;; Continue
	;; FIXME: Interesting one to understand...
		CALL	WaitInputClear
		CALL	C7BB3
		LD	HL,L4C50
CP_2:		PUSH	HL
		LD	DE,L6088
		CALL	CA0A8
		POP	HL
		LD	A,L
		LD	H,A
		ADD	A,$14
		LD	L,A
		CP	$B5
		JR	C,CP_2
		RET

	;; Receives sensitivity in A
SetSens:	LD	HL,HighSensFn 		; High sensitivity routine
		AND	A
		JR	Z,SetSens_1		; Low sensitivity routine
		LD	HL,LowSensFn
SetSens_1:	LD	(SensFnCall+1),HL	; Modifies code
		RET

	;; Read all the inputs and set input variables
CheckCtrls:	CALL	GetInputCtrls
		BIT	7,A			; Carry pressed?
		LD	HL,CarryPressed
		CALL	KeyTrigger2
		BIT	5,A			; Swop pressed?
		CALL	KeyTrigger
		BIT	6,A			; Fire pressed?
		CALL	KeyTrigger
		LD	C,A
		RRA
		CALL	LookupDir
		CP	$FF
		JR	Z,NoKeysPressed
		RRA				; Lowest bit held 'is diagonal?'
SensFnCall:	JP	C,LowSensFn 		; NB: Self-modifying code target
		LD	A,C			; Not a diagonal move. Simple write.
		LD	(LastDir),A
		LD	(CurrDir),A
		RET

	;; If we receive diagonal input, set the new direction
HighSensFn:	LD	A,(LastDir)
		XOR	C
		CPL
		XOR	C
		AND	$FE
		XOR	C
		LD	(CurrDir),A
		RET

	;; If we receive diagonal input, prefer the old direction
LowSensFn:	LD	A,(LastDir)
		XOR	C
		AND	$FE
		XOR	C
		LD	B,A
		OR	C
		CP	B
		JR	Z,LSF
		LD	A,B
		XOR	$FE
LSF:		LD	(CurrDir),A
		RET

NoKeysPressed:	LD	A,C
		LD	(CurrDir),A
		RET

	;; Keytrigger: Writes to (HL+1), based on whether Z flag is set (meaning key pressed).
	;; Bit 1 is 'is currently set', bit 0 is 'newly pressed'.
KeyTrigger:	INC	HL
	;; Version without the inc
KeyTrigger2:	RES	0,(HL)
		JR	Z,KT
		RES	1,(HL) 		; Key not pressed, reset bits 0 and 1 and return.
		RET
	;; Key pressed:
KT:		BIT	1,(HL) 		; If bit 1 set, already processed already...
		RET	NZ		; so return (bit 0 reset).
		SET	1,(HL)		; Otherwise set both bits.
		SET	0,(HL)
		RET

	;; Played when we can't do something.
NopeNoise:	LD		B,$C4
		JP		PlaySound

	;; Checks if 'swop' has just been pressed, and if it has, do it.
CheckSwop:	LD		A,(SwopPressed)
		RRA
		RET		NC 		; Return if not pressed...
	;; FIXME: Don't know what these variables are that prevent us swopping
		LD		A,(LA2BC)
		LD		HL,LB219
		OR		(HL)
		LD		HL,(LA296)
		OR		H
		OR		L
		JR		NZ,NopeNoise 	; Tail call
	;; Can't swop if out of lives for the other character
		LD		HL,(Lives)
		CP		H
		JR		Z,NopeNoise 	; Tail call
		CP		L
		JR		Z,NopeNoise 	; Tail call
	;; NB: Fall through

	;; FIXME: Lots to reverse here
SwitchChar:	CALL	SwitchHelper
		LD	BC,(LA2BB)
		JR	NC,SwC_1
		LD	(HL),C
SwC_1:		INC	HL
		RRA
		JR	NC,SwC_2
		LD	(HL),C
SwC_2:		LD	HL,SwopPressed
		LD	IY,HeelsObj
		LD	A,E
		CP	$03
		JR	Z,SwC_6
		LD	A,(LA295)
		AND	A
		JR	Z,SwC_6
		LD	A,(IY+$05)
		INC	A
		SUB	(IY+$17)
		CP	$03
		JR	NC,SwC_6
		LD	C,A
		LD	A,(IY+$06)
		INC	A
		SUB	(IY+$18)
		CP	$03
		JR	NC,SwC_6
		LD	B,A
		LD	A,(IY+$07)
		SUB	$06
		CP	A,(IY+$19)
		JR	NZ,SwC_6
		LD	E,$FF
		RR	B
		JR	C,SwC_3
		RR	B
		CCF
		CALL	SwitchGet
SwC_3:		RR	C
		JR	C,SwC_4
		RR	C
		CALL	SwitchGet
		JR	SwC_5
SwC_4:		RLC	E
		RLC	E
SwC_5:		LD	A,$03
		INC	E
		JR	Z,SwC_7 	; Switch to Both
		DEC	E
		LD	(IY+$1E),E
		RES	1,(HL)
		RET
SwC_6:		LD	A,$04
		XOR	(HL)
		LD	(HL),A
		AND	$04
		LD	A,$02
		JR	Z,SwC_7       	; Zero: Switch to Head
		DEC	A             	; Otherwise Heels
SwC_7:		LD	(Character),A
		CALL	SetCharFlags
		CALL	SwitchHelper
		JR	C,SwC_8
		INC	HL
SwC_8:		LD	A,(HL)
		LD	(LA2BB),A
		LD	A,(LA295)
		AND	A
		JP	NZ,DrawScreenPeriphery
		JR	L72B1

SwitchGet:	PUSH	AF
		RL	E
		POP	AF
		CCF
		RL	E
		RET

SetCharThing:	LD	IY,HeelsObj
		LD	A,(Character)
	;; NB: Fall through
	
SetCharFlags:	LD	(IY+$0A),$00 	; Default to 0.
		RES	3,(IY+$04)
		BIT	0,A 		; Have a Heels?
		JR	NZ,SCF_1
		LD	(IY+$0A),$01 	; No, set to 1.
SCF_1:		LD	(IY+$1C),$00	; Default to 0.
		RES	3,(IY+$16)
		BIT	1,A 		; Have a Head?
		JR	NZ,SCF_2
		LD	(IY+$1C),$01 	; No, set to 1.
SCF_2:		RES	1,(IY+$1B)
		CP	$03
		RET	NZ
		SET	3,(IY+$04) 	; If Both, set these. Otherwise, was reset.
		SET	1,(IY+$1B)
		RET

C728C:		LD	HL,(L703B)
		LD	DE,(LFB28)
		AND	A
		SBC	HL,DE
		RET

SwitchHelper:	LD	A,(Character)
		LD	HL,L7044
		LD	E,A
		RRA
		RET
