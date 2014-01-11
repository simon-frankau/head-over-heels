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
	
#include "data_header.asm"

	;; Hack, should be removed.
#include "equs.asm"

MAGIC_OFFSET:	EQU 360 	; The offset high data is moved down by...
	
SpriteBuff:	EQU $B800

SomeBuff:	EQU $F944
SomeBuffLen:	EQU $94

BigSpriteBuf:	EQU $F9D8
	
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
MainStart:	CALL	L8DC2
		LD	A,$40
		LD	(L8F18),A
MainB:		XOR	A
		LD	(L703D),A
		CALL	L7B91
	;; The main game-playing loop
MainLoop:	CALL	WaitFrame
		CALL	CheckCtrls
		CALL	MainLoop2
		CALL	MainLoop3
		CALL	CheckPause
		CALL	CheckSwop
		LD	HL,LA2BE
		LD	A,(HL)
		SUB	$01
		LD	(HL),$00
		LD	B,A
		CALL	NC,PlaySound
		JR	MainLoop

	;; FIXME: ???
L708B:		LD	HL,(L703B)
		LD	BC,$8D30 ; TODO
		XOR	A
		SBC	HL,BC
		RET

	;; FIXME: ???
MainLoop2:	CALL	L708B
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
L70EC:		CALL	LAD26
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
		CALL	L7BB3
		LD	HL,L4C50
CP_2:		PUSH	HL
		LD	DE,L6088
		CALL	LA0A8
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
		LD	IY,LA2C0
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
		JP	NZ,L8E1D
		JR	L72B1

SwitchGet:	PUSH	AF
		RL	E
		POP	AF
		CCF
		RL	E
		RET

SetCharThing:	LD	IY,LA2C0
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

L728C:		LD	HL,(L703B)
		LD	DE,(LFB28)
		AND	A
		SBC	HL,DE
		RET

SwitchHelper:	LD	A,(Character)
		LD	HL,L7044
		LD	E,A
		RRA
		RET

L72A0:	XOR		A
		JR		L72A9
L72A3:	LD		A,$FF
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
		CALL	L7314
		LD		(L72F0),HL
		AND		A
		LD		HL,LFB28
		JR		NZ,L72CD
		EX		DE,HL
L72CD:	EX		AF,AF'
		CALL	L7321
		INC		B
		NOP
		DEC		SP
		LD		(HL),B
		CALL	L7321
		DEC		E
		NOP
		LD		(HL),A
		XOR		A
		CALL	L7321
		ADD		HL,DE
		NOP
		AND		D
		AND		D
		CALL	L7321
		RET		P
		INC		BC
		LD		B,B
		CP		D
		RET
L72EB:	CALL	L7321
		LD		(DE),A
		NOP			
L72F0:		RET		NZ 		; Self-modifying code
		AND		D
		RET
L72F3:	PUSH	DE
		CALL	LA94B
		EX		DE,HL
		LD		BC,L0012
		PUSH	BC
		LDIR
		CALL	L7314
		POP		BC
		POP		DE
		LDIR
L7305:		LD		HL,(LAF92) 	; NB: Referenced as data.
		LD		(LAF78),HL
		LD		HL,LAF82
		LD		BC,L0008
		JP		FillZero
	
L7314:		LD		HL,Character
		BIT		0,(HL) 		; Heels?
		LD		HL,LA2C0	; No Heels case
		RET		Z
		LD		HL,LA2D2 	; Have Heels case
		RET

L7321:	POP		IX
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
L7358:	XOR		A
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
	
L7395:		LD	A,$08
		CALL	SetAttribs 	; Set all black attributes
		LD	HL,L4048
		LD	DE,L4857
L73A0:		PUSH	HL
		PUSH	DE
		CALL	LA098
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

SomeBuffFaffCounter:	DEFB $00

RestoreSomeBuffFaff:	PUSH	DE
		PUSH	BC
		PUSH	HL
		LD	A,(SomeBuffFaffCounter)
		CALL	SomeBuffFaff
		POP	HL
		POP	BC
		POP	DE
		RET

SetSomeBuffFaff:	LD	(SomeBuffFaffCounter),A
	;; Appears to build something up in SomeBuffer, based on a
	;; prologue, middle section and end. Final pointer at DE.
SomeBuffFaff:	PUSH	AF
		LD	HL,SomeBuff
		LD	BC,SomeBuffLen
		CALL	FillZero
		XOR	A
		LD	(SomeBuffFlag2),A
		DEC	A
		LD	(SomeBuffFlag),A
		POP	AF
		AND	A
		RET	Z
		LD	DE,SomeBuff + SomeBuffLen - 1
		PUSH	AF
		CALL	SBF_4
SBF_1:		POP	AF
		SUB	$06
		JR	Z,SBF_2
		PUSH	AF
		CALL	SBF_3
		JR	SBF_1

SBF_2:		LD	HL,LF91B
		LD	BC,L0024
		JR	SBF_5

SBF_3:		LD	HL,LF933
		LD	BC,L0018
		JR	SBF_5

SBF_4:		LD	HL,LF943
		LD	BC,L0010

SBF_5:		LDDR
		RET

L76DE:	DEFW L76E0
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
L76EE:	DEFB $00
L76EF:	DEFB $00
L76F0:	DEFB $00
L76F1:	DEFB $00
L76F2:	DEFB $00
L76F3:	DEFB $00
L76F4:	DEFB $00
L76F5:	DEFB $00
L76F6:	DEFB $00
L76F7:	DEFB $00
L76F8:	DEFB $00
L76F9:	DEFB $FF
L76FA:	DEFB $FF
L76FB:	DEFB $00
L76FC:	DEFB $00
L76FD:	DEFB $00
L76FE:	DEFB $00
L76FF:	DEFB $00
L7700:	DEFB $00
	
	;; Current pointer to bit-packed data
DataPtr:	DEFW $0000
	;; The remaining bits to read at the current address.
CurrData:	DEFB $00

	;; FIXME: Decode remaining DataPtr/CurrData references...
	
L7704:	DEFB $00
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
BigSpriteTest:	DEFB $00
L7710:	DEFB $00
FloorCode:	DEFB $00
L7712:	DEFB $00
L7713:	DEFB $00
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
L7724:	DEFB $08
L7725:	DEFB $08
L7726:	DEFB $48
L7727:	DEFB $48
L7728:	DEFB $08
L7729:	DEFB $10
L772A:	DEFB $48
L772B:	DEFB $40
L772C:	DEFB $08
L772D:	DEFB $18
L772E:	DEFB $48
L772F:	DEFB $38
L7730:	DEFB $08
L7731:	DEFB $20
L7732:	DEFB $48
L7733:	DEFB $30
L7734:	DEFB $10
L7735:	DEFB $08
L7736:	DEFB $40
L7737:	DEFB $48
L7738:	DEFB $18
L7739:	DEFB $08
L773A:	DEFB $38
L773B:	DEFB $48
L773C:	DEFB $20
L773D:	DEFB $08
L773E:	DEFB $30
L773F:	DEFB $48
L7740:	DEFB $10
L7741:	DEFB $10
L7742:	DEFB $40
L7743:	DEFB $40
L7744:	DEFB $00
L7745:	DEFB $00
L7746:	DEFB $00
L7747:	DEFB $00
L7748:	DEFB $00
L7749:	DEFB $00
L774A:	DEFB $00
L774B:	DEFB $00
L774C:	DEFB $C0
L774D:		LD		A,$FF
		LD		(L7713),A
L7752:		LD		IY,L7718
		LD		HL,L40C0
		LD		(SpriteXExtent),HL
		LD		HL,L00FF
		LD		(SpriteYExtent),HL
		LD		HL,LC0C0
		LD		(L7748),HL
		LD		(L774A),HL
		LD		HL,L0000
		LD		BC,(L703B)
		CALL	L780E
		XOR		A
		LD		(L7713),A
		LD		(L774C),A
		LD		HL,(LAF78)
		LD		(LAF92),HL
		LD		A,(L7710)
		LD		(BigSpriteTest),A
		LD		DE,L7744
		LD		HL,L7748
		LD		BC,L0004
		LDIR
		LD		HL,LBA00
		LD		BC,L0040
		CALL	FillZero
		CALL	LA260
		CALL	L7A2E
		LD		A,$00
		RLA
		LD		(L7712),A
		CALL	L84CB
		LD		HL,(L7716)
		PUSH	HL
		LD		A,L
		AND		$08
		JR		Z,L77D0
		LD		A,$01
		CALL	LAF96
		LD		BC,(L703B)
		LD		A,B
		INC		A
		XOR		B
		AND		$0F
		XOR		B
		LD		B,A
		LD		A,(L771B)
		LD		H,A
		LD		L,$00
		CALL	L780E
		CALL	LA260
L77D0:	LD		IY,L7720
		POP		HL
		PUSH	HL
		LD		A,L
		AND		$04
		JR		Z,L77F8
		LD		A,$02
		CALL	LAF96
		LD		BC,(L703B)
		LD		A,B
		ADD		A,$10
		XOR		B
		AND		$F0
		XOR		B
		LD		B,A
		LD		A,(L771A)
		LD		L,A
		LD		H,$00
		CALL	L780E
		CALL	LA260
L77F8:		LD	A,(L774C)
		LD	HL,(L7705)
		PUSH	AF
		CALL	L81DC
		POP	AF
		CALL	SetSomeBuffFaff
		POP	HL
		LD	(L7716),HL
		XOR	A
		JP	LAF96

	;; FIXME: Called lots
L780E:		LD	(L76E0),HL
		XOR	A
		LD	(L76E2),A
		PUSH	BC
		CALL	L7A45
		LD	B,$03
		CALL	FetchData
		LD	(L7710),A
		ADD	A,A
		ADD	A,A
		ADD	A,$24
		LD	L,A
		ADC	A,$77
		SUB	L
		LD	H,A
		LD	B,$02
		LD	IX,L76E0
L7830:		LD	C,(HL)
		LD	A,(IX+$00)
		AND	A
		JR	Z,L7842
		SUB	C
		LD	E,A
		RRA
		RRA
		RRA
		AND	$1F
		LD	(IX+$00),A
		LD	A,E
L7842:		ADD	A,C
		LD	(IY+$00),A
		INC	HL
		INC	IX
		INC	IY
		DJNZ	L7830
	;; Do this bit twice:
		LD		B,$02
L784F:		LD		A,(IX-$02)
		ADD		A,A
		ADD		A,A
		ADD		A,A
		ADD		A,(HL)
		LD		(IY+$00),A
		INC		IY
		INC		IX
		INC		HL
		DJNZ		L784F
	;; Now update some stuff off FetchData:
		LD	B,$03
		CALL	FetchData
		LD	(AttribScheme),A	; Fetch the attribute scheme to use.
		LD	B,$03
		CALL	FetchData
		LD	(WorldId),A 		; Fetch the current world identifier
		CALL	L7934
		LD	B,$03
		CALL	FetchData
		LD	(FloorCode),A 		; And the floor pattern to use
		CALL	SetFloorAddr
	;; FIXME
L787E:		CALL	L78D4
		JR		NC,L787E
		POP		BC
		JP		L8778
L7887:	BIT		2,A
		JR		Z,L788D
		OR		$F8
L788D:	ADD		A,(HL)
		RET
L788F:	EX		AF,AF'
		CALL	L7AF3
		LD		HL,(L76DE)
		PUSH	AF
		LD		A,B
		CALL	L7887
		LD		B,A
		INC		HL
		LD		A,C
		CALL	L7887
		LD		C,A
		INC		HL
		POP		AF
		SUB		$07
		ADD		A,(HL)
		INC		HL
		LD		(L76DE),HL
		LD		(HL),B
		INC		HL
		LD		(HL),C
		INC		HL
		LD		(HL),A

	;; Save the current data pointer, do some stuff, restore.
		LD	A,(CurrData)
		LD	HL,(DataPtr)
		PUSH	AF
		PUSH	HL
		CALL	L7A1C
		LD	(DataPtr),HL
L78BE:		CALL	L78D4
		JR	NC,L78BE
		LD	HL,(L76DE)
		DEC	HL
		DEC	HL
		DEC	HL
		LD	(L76DE),HL
		POP	HL
		POP	AF
		LD	(DataPtr),HL
		LD	(CurrData),A
	;; NB: Fall through.
	
L78D4:		LD	B,$08
		CALL	FetchData
		CP	$FF
		SCF
		RET	Z
		CP	$C0
		JR	NC,L788F
		PUSH	IY
		LD	IY,L76EE
		CALL	L8232
		POP	IY
		LD	B,$02
		CALL	FetchData
		BIT	1,A
		JR	NZ,L78F9
		LD	A,$01
		JR	L7903
L78F9:		PUSH	AF
		LD	B,$01
		CALL	FetchData
		POP	BC
		RLCA
		RLCA
		OR	B
L7903:		LD	(L7700),A
L7906:		CALL	L7A8D
		CALL	L7AC1
		LD	A,(L7700)
		RRA
		JR	NC,L791D
		LD	A,(L7704)
		INC	A
		AND	A
		RET	Z
		CALL	L7922
		JR		L7906
L791D:		CALL	L7922
		AND	A
		RET

	
L7922:	LD		HL,L76EE
		LD		BC,L0012
		PUSH	IY
		LD		A,(L7713)
		AND		A
		CALL	Z,LAFC6
		POP		IY
		RET

L7934:		LD	B,$03
		CALL	FetchData
		CALL	L7358
		ADD	A,A
		LD	L,A
		LD	H,A
		INC	H
		LD	(L7705),HL
		LD	IX,L7707
		LD	HL,L7748
		EXX
		LD	A,(IY-$01)
		ADD	A,$04
		CALL	L79B1
		LD	HL,L7749
		EXX
		LD	A,(IY-$02)
		ADD	A,$04
		CALL	L79A5
		LD	HL,L774A
		EXX
		LD	A,(IY-$03)
		SUB	$04
		CALL	L79B1
		LD	HL,L774B
		EXX
		LD	A,(IY-$04)
		SUB	$04
		JP	L79A5		; Tail call
	
L7977:	LD		B,$03
		CALL	FetchData
		LD		HL,L7716
		SUB		$02
		JR		C,L799A
		RL		(HL)
		INC		HL
		SCF
		RL		(HL)
		SUB		$07
		NEG
		LD		C,A
		ADD		A,A
		ADD		A,C
		ADD		A,A
		ADD		A,$96
		LD		(L76F5),A
		SCF
		EXX
		LD		(HL),A
		RET
L799A:	CP		$FF
		CCF
		RL		(HL)
		AND		A
		INC		HL
		RL		(HL)
		AND		A
		RET
L79A5:	LD		(L76F3),A
		LD		HL,L76F4
		LD		A,(L76E1)
		JP		L79BA
L79B1:	LD		(L76F4),A
		LD		HL,L76F3
		LD		A,(L76E0)
L79BA:	ADD		A,A
		ADD		A,A
		ADD		A,A
		PUSH	AF
		ADD		A,$24
		LD		(HL),A
		PUSH	HL
		CALL	L7977
		JR		NC,L7A15
		LD		A,(IX+$00)
		LD		(L76F2),A
		INC		IX
		LD		A,(L7705)
		LD		(L76F6),A
		CALL	L79EB
		LD		A,(IX+$00)
		LD		(L76F2),A
		INC		IX
		LD		A,(L7706)
		LD		(L76F6),A
		POP		HL
		POP		AF
		ADD		A,$2C
		LD		(HL),A
L79EB:	CALL	L7922
		LD		A,(L76F2)
		LD		C,A
		AND		$30
		RET		PO
		AND		$10
		OR		$01
		LD		(L76F2),A
		LD		A,(L76F5)
		CP		$C0
		RET		Z
		PUSH	AF
		ADD		A,$06
		LD		(L76F5),A
		LD		A,$54
		LD		(L76F6),A
		CALL	L7922
		POP		AF
		LD		(L76F5),A
		RET
L7A15:	POP		HL
		POP		AF
		INC		IX
		INC		IX
		RET

	
L7A1C:		LD		A,$80
		LD		(CurrData),A 	; Clear buffered byte.
	;; Get the size of some buffer thing: Start at L5B00, just after attributes.
	;; Take first byte as step size, then scan at that step size until we find a zero.
	;; Return in HL.
		LD		HL,L5B00
		EX		AF,AF'
		LD		D,$00
L7A27:		LD		E,(HL)
		INC		HL
		CP		(HL)
		RET		Z
		ADD		HL,DE
		JR		L7A27

	
L7A2E:	LD		BC,(L703B)
		LD		A,C
		DEC		A
		AND		$F0
		LD		C,A
		CALL	L7A4E
		RET		C
		INC		DE
		INC		DE
		INC		DE
		LD		A,(DE)
		OR		$F1
		INC		A
		RET		Z
		SCF
		RET
	
L7A45:	CALL	L7A4E
		EXX
		LD		A,C
		OR		(HL)
		LD		(HL),A
		EXX
		RET

L7A4E:	LD		D,$00
		LD		HL,L5C71
		CALL	L7A5C
		RET		NC
		LD		HL,L6B16
		JR		L7A63
	
L7A5C:		EXX
		LD		HL,L8AE2
		LD		C,$01
		EXX
	
L7A63:		LD		E,(HL)
		INC		E
		DEC		E
		SCF
		RET		Z
		INC		HL
		LD		A,B
		CP		(HL)
		JR		Z,L7A77

L7A6D:		ADD		HL,DE
		EXX
		RLC		C
		JR		NC,L7A74
		INC		HL
L7A74:		EXX
		JR		L7A63
	
L7A77:		INC		HL
		DEC		E
		LD		A,(HL)
		AND		$F0
		CP		C
		JR		NZ,L7A6D
		DEC		HL
	;; Initialise DataPtr and CurrData for new data.
		LD		(DataPtr),HL
		LD		A,$80
		LD		(CurrData),A
		LD		B,$04
		JP		FetchData

L7A8D:		LD		A,(L7700)
		RRA
		RRA
		JR		C,L7A99
		LD		B,$01
		CALL	FetchData
L7A99:	AND		$01
		RLCA
		RLCA
		RLCA
		RLCA
		AND		$10
		LD		C,A
		LD		A,(L76ED)
		XOR		C
		LD		(L76F2),A
		LD		BC,(L76EC)
		BIT		4,A
		JR		Z,L7ABC
		BIT		1,A
		JR		Z,L7ABA
		XOR		$01
		LD		(L76F2),A
L7ABA:	DEC		C
		DEC		C
L7ABC:	LD		A,C
		LD		(L76FE),A
		RET
L7AC1:	CALL	L7AF3
L7AC4:	EX		AF,AF'
		LD		HL,(L76DE)
		LD		DE,L76F3
L7ACB:	LD		A,B
		CALL	L7AEB
		LD		(DE),A
		LD		A,C
		CALL	L7AEB
		INC		DE
		LD		(DE),A
		EX		AF,AF'
		PUSH	AF
		ADD		A,(HL)
		LD		L,A
		ADD		A,A
		ADD		A,L
		ADD		A,A
		ADD		A,$96
		INC		DE
		LD		(DE),A
		POP		AF
		CPL
		AND		C
		AND		B
		OR		$F8
		LD		(L7704),A
		RET
L7AEB:	ADD		A,(HL)
		INC		HL
		RLCA
		RLCA
		RLCA
		ADD		A,$0C
		RET
L7AF3:	LD		B,$03
		CALL	FetchData
		PUSH	AF
		LD		B,$03
		CALL	FetchData
		PUSH	AF
		LD		B,$03
		CALL	FetchData
		POP		HL
		POP		BC
		LD		C,H
		RET
	
InitStuff:	CALL	IrqInstall
		JP	InitRevTbl

InitNewGame:	XOR	A
		LD	(L866B),A
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
		LD	(L703B),HL
		LD	A,$01
		CALL	L7B43
		LD	HL,L8A40
		LD	(L703B),HL
		XOR	A
		LD	(LB218),A
		RET

L7B43:		LD	(Character),A
		PUSH	AF
		LD	(LFB28),A
		CALL	L7BBF
		XOR	A
		LD	(LA297),A
		CALL	LA958
		JR	L7B59		; Tail call

L7B56:		CALL	LA361
L7B59:		LD	A,(LA2BC)
		AND	A
		JR	NZ,L7B56
		POP	AF
		XOR	$03
		LD	(Character),A
		CALL	LA58B
		JP	L72A0		; Tail call

InitContinue:	CALL	Reinitialise
		DEFW	StatusReinit
		LD	A,$08
		CALL	UpdateAttribs	; Blacked-out attributes
		JP	DoContinue	; Tail call

L7B78:		CALL	L774D
		CALL	Reinitialise
		DEFW	ReinitThing
		CALL	SetCharThing
		CALL	L7C1A
		CALL	L7395
		XOR	A
		LD	(LA295),A
		JR	L7BB3		; Tail call

L7B8F:	DEFB $00
WorldIdSnd:	DEFB $00

	;; NB: Called from main loop...
L7B91:		CALL	L7BBF
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
L7BAD:		CALL	L7395
		CALL	LA958
	;; NB: Fall through

L7BB3:		LD	A,(AttribScheme)
		CALL	UpdateAttribs
		CALL	PrintStatus
		JP	L8E1D		; Tail call

L7BBF:		CALL	Reinitialise
		DEFW	LAF5B
		CALL	Reinitialise
		DEFW	ReinitThing
		LD	A,(Character)
		CP	$03
		JR	NZ,L7BDC
		LD	HL,LFB28
		SET	0,(HL)
		CALL	L7752
		LD	A,$01
		JR	L7C14
L7BDC:		CALL	L728C
		JR	NZ,L7C10
		CALL	L72A3
		CALL	L774D
		LD	HL,LA2C0
		CALL	LB104
		EXX
		LD	HL,LA2D2
		CALL	LB104
		CALL	LACD6
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
L7C10:		CALL	L7752
		XOR	A
L7C14:		LD	(LA295),A
		JP	L7C1A
L7C1A:		LD	HL,(L7718)
		LD	A,(L7717)
		PUSH	AF
		BIT	1,A
		JR	Z,L7C29
		DEC	H
		DEC	H
		DEC	H
		DEC	H
L7C29:	RRA
		LD		A,L
		JR		NC,L7C30
		SUB		$04
		LD		L,A
L7C30:	SUB		H
		ADD		A,$80
		LD		(L9C8B+1),A
		LD		C,A
		LD		A,$FC
		SUB		H
		SUB		L
		LD		B,A
		NEG
		LD		E,A
		ADD		A,C
		LD		(L9C9F+1),A
		LD		A,C
		NEG
		ADD		A,E
		LD		(L9C97+1),A
		CALL	L9D45
		POP		AF
		RRA
		PUSH	AF
		CALL	NC,L7C6B
		POP		AF
		RRA
		RET		C
		LD		HL,LBA3E
L7C59:	LD		A,(HL)
		AND		A
		JR		NZ,L7C61
		DEC		HL
		DEC		HL
		JR		L7C59
L7C61:	INC		HL
		LD		A,(HL)
		OR		$FA
		INC		A
		RET		NZ
		LD		(HL),A
		DEC		HL
		LD		(HL),A
		RET

L7C6B:	LD		HL,LBA00
L7C6E:	LD		A,(HL)
		AND		A
		JR		NZ,L7C61
		INC		HL
		INC		HL
		JR		L7C6E

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
	
L81DC:	PUSH	AF
		LD		A,L
		LD		H,$00
		LD		(SpriteCode),A
		CALL	Sprite3x56
		EX		DE,HL
		LD		DE,BigSpriteBuf
		PUSH	DE
		LD		BC,L0150
		LDIR
		POP		HL
		POP		AF
		ADD		A,A
		ADD		A,$08
		CP		$39
		JR		C,L81FB
		LD		A,$38
L81FB:	LD		B,A
		ADD		A,A
		ADD		A,B
		LD		E,A
		LD		D,$00
		ADD		HL,DE
		EX		DE,HL
		LD		HL,L00A8
		ADD		HL,DE
		LD		A,B
		NEG
		ADD		A,$39
		LD		B,A
		LD		C,$FC
		JR		L8224
L8211:	LD		A,(DE)
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
L8224:	DJNZ	L8211
		XOR		A
		LD		(BigSpriteFlipped),A
		RET
L822B:	DEFB $00,$00
L822D: 	DEFB $FF
L822E:	DEFB $00,$3D,$8E,$3D
L8232:	LD		(IY+$09),$00
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
		ADD		A,$2E
		LD		E,A
		ADC		A,$82
		SUB		E
		LD		D,A
		LD		A,(DE)
		SET		5,(IY+$09)
		BIT		2,(HL)
		JR		Z,L8264
		LD		C,B
		LD		B,A
		LD		A,C
L8264:	LD		(L822E),A
		LD		A,B
		CALL	L828B
		LD		A,(HL)
		OR		$9F
		INC		A
		LD		A,(HL)
		JR		NZ,L8278
		SET		7,(IY+$09)
		AND		$BF
L8278:	AND		$FB
		CP		$80
		RES		7,A
		LD		(IY-$01),A
		LD		(IY-$02),$02
		RET		C
		SET		4,(IY+$09)
		RET
L828B:	LD		(IY+$0F),$00
		LD		(IY+$08),A
		CP		$80
		RET		C
		ADD		A,A
		ADD		A,A
		ADD		A,A
		LD		(IY+$0F),A
		PUSH	HL
		CALL	L82E8
		POP		HL
		RET
	
L82A1:		LD		(L822B),DE
		PUSH	DE
		POP		IY
		DEC		A
		ADD		A,A
		ADD		A,$BC
		LD		L,A
		ADC		A,$83
		SUB		L
		LD		H,A
		LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		XOR		A
		LD		(L8ED8),A
		LD		A,(IY+$0B)
		LD		(L822D),A
		LD		(IY+$0B),$FF
		BIT		6,(IY+$09)
		RET		NZ
		JP		(HL)
L82C9:		BIT		5,(IY+$09)
		JR		Z,L82E8
		CALL	L82E8
		EX		AF,AF'
		LD		C,(IY+$10)
		LD		DE,L0012
		PUSH	IY
		ADD		IY,DE
		CALL	L938D
		CALL	L82E8
		POP		IY
		RET		C
		EX		AF,AF'
		RET
	
L82E8:	LD		C,(IY+$0F)
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
L8313:	LD		(IY+$08),A
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
L832A:	LD		A,C
		CALL	Z,LA92C
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
L83B0:	DEFB $00,$41,$00,$42,$00,$43,$00,$44,$45,$C5,$C4,$00,$CC,$90,$36,$90
L83C0:	DEFB $3A,$90,$3E,$90,$42,$90,$E3,$90,$E8,$90,$ED,$90,$01,$91,$76,$8F
L83D0:	DEFB $F2,$90,$F7,$90,$FC,$90,$C6,$8F,$06,$91,$72,$91,$70,$90,$21,$90
L83E0:	DEFB $2B,$90,$56,$90,$DD,$90,$D7,$90,$1E,$90,$53,$90,$66,$8F,$BF,$90
L83F0:	DEFB $08,$8F,$88,$90,$EB,$8E,$DB,$8E,$4C,$90,$4E,$8F,$26,$92,$82,$90
L8400:	DEFB $2F,$8F,$19,$8F,$0B,$91
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
L84C5:	DEFB $00,$00
L84C7:	DEFB $00
L84C8:	DEFB $00
L84C9:	DEFB $00
L84CA:	DEFB $00
L84CB:	CALL	L8603
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
		CALL	L8506
		LD	A,(L7716)
		AND	$04
		RET	NZ
		LD	B,$04
		EXX
		LD	A,$80
		LD	(L8591+1),A
		CALL	L8603
		LD	DE,L0002
		LD	A,(IY-$01)
		SUB	(IY-$03)
		JR	L8521
L8506:		LD	A,(L7716)
		AND	$08
		RET	NZ
		LD	B,$08
		EXX
		XOR	A
		LD	(L8591+1),A
		CALL	L8603
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
		LD	(L84C5),HL
	;; Update DataPtr etc. for FetchData.
		LD	A,B
		ADD	A,A
		LD	B,A 		; B updated to 2x
		ADD	A,A
		ADD	A,A   		; A is 8x
		ADD	A,$2A
		LD	L,A
		ADC	A,$86
		SUB	L
		LD	H,A   		; HL is $862A + 8xWorldId (data starts at $862B=WorldData)
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

L8603:	LD		A,(IY-$02)
		LD		D,A
		LD		E,(IY-$01)
		SUB		E
		ADD		A,$80
		LD		B,A
		RRA
		RRA
		AND		$3E
		LD		L,A
		LD		H,$BA
		LD		A,$07
		SUB		E
		SUB		D
		LD		C,A
		RET

PanelBases:	DEFW $C050,$C1A0,$C2F0,$C3D0,$C4B0,$C670,$C750,$C8A0
	;; 8-byte chunks referenced by setting DataPtr etc.
WorldData:	DEFB $46,$91,$65,$94,$A1,$69,$69,$AA
		DEFB $49,$24,$51,$49,$12,$44,$92,$A4
		DEFB $04,$10,$10,$41,$04,$00,$44,$00
		DEFB $04,$10,$10,$41,$04,$00,$10,$00
		DEFB $4E,$31,$B4,$E7,$4E,$42,$E4,$99
		DEFB $45,$51,$50,$51,$54,$55,$55,$55
		DEFB $64,$19,$65,$11,$A4,$41,$28,$55
		DEFB $00,$00,$00,$00,$00,$00,$00,$00
L866B:	DEFB $00
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

L874B:	LD		BC,(L703B)
L874F:	LD		HL,L866C
		LD		E,$34
L8754:	LD		A,C
		CP		(HL)
		INC		HL
		JR		NZ,L875C
		LD		A,B
		CP		(HL)
		RET		Z
L875C:	INC		HL
		INC		HL
		INC		HL
		DEC		E
		JR		NZ,L8754
		DEC		E
L8763:		RET		; FIXME: Self-modifying code??
L8764:	INC		HL
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
L8778:	PUSH	BC
		LD		HL,L8728
		LD		A,(L866B)
		CPL
		LD		B,$05
		LD		DE,L0004
L8785:	RR		(HL)
		RRA
		RL		(HL)
		ADD		HL,DE
		DJNZ	L8785
		POP		BC
		CALL	L874F
L8791:	RET		NZ
		PUSH	HL
		PUSH	DE
		PUSH	BC
		PUSH	IY
		CALL	L8764
		LD		IY,L76EE
		LD		A,D
		CP		$0E
		LD		A,$60
		JR		NZ,L87A6
		XOR		A
L87A6:	LD		(IY+$04),A
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
		CALL	L828B
		POP		DE
		POP		BC
		POP		IY
		LD		A,E
		CALL	L7AC4
		CALL	L7922
		POP		BC
		POP		DE
		POP		HL
		CALL	L875C
		JR		L8791
InitNewGame2:	LD		HL,L866C
		LD		DE,L0004
		LD		B,$34
L87D9:	RES		0,(HL)
		ADD		HL,DE
		DJNZ	L87D9
		RET
L87DF:	LD		D,A
		CALL	L874B
L87E3:	RET		NZ
		INC		HL
		LD		A,(HL)
		DEC		HL
		AND		$0F
		CP		D
		JR		Z,L87F1
		CALL	L875C
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
	
L8827:		LD	HL,LA28B
		CALL	SetBit
		CALL	L8E1D
		LD	B,$C2
		JP	PlaySound

#include "status.asm"
	
L8ADC:	DEFB $00,$00
L8ADE:	DEFB $00
L8ADF:	DEFB $00,$00,$00
L8AE2:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8AEE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8AFE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B0E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B1E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B2E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B3E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B4E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B5E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B6E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B7E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B8E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B9E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BAE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BBE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BCE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BDE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BEE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BFE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8C0E:	DEFB $00
L8C0F:	LD		HL,LA28B
		RES		2,(HL)
L8C14:	EXX
		LD		BC,L0001
		JR		L8C26
L8C1A:	LD		HL,L866B
		JR		L8C14
L8C1F:	LD		HL,L8AE2
		EXX
		LD		BC,L012D
L8C26:	EXX
		LD		DE,L0000
		EXX
L8C2B:	EXX
		LD		C,(HL)
		SCF
		RL		C
L8C30:	LD		A,E
		ADC		A,$00
		DAA
		LD		E,A
		LD		A,D
		ADC		A,$00
		DAA
		LD		D,A
		SLA		C
		JR		NZ,L8C30
		INC		HL
		EXX
		DEC		BC
		LD		A,B
		OR		C
		JR		NZ,L8C2B
		EXX
		RET
InitNewGame1:	LD		HL,L8AE2
		LD		BC,L012D
		JP		FillZero
L8C50:	CALL	L708B
		PUSH	AF
		CALL	L8C1F
		POP		AF
		LD		HL,L0000
		JR		NZ,L8C69
		LD		HL,L0501
		LD		A,(LA295)
		AND		A
		JR		Z,L8C69
		LD		HL,L1002
L8C69:	LD		BC,L0010
		CALL	L8C82
		PUSH	HL
		CALL	L8C0F
		POP		HL
		LD		BC,L01F4
		CALL	L8C82
		PUSH	HL
		CALL	L8C1A
		POP		HL
		LD		BC,L027C
L8C82:	LD		A,E
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
		JR		NZ,L8C82
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
	
	
L8CAB:	LD		L,A
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
L8CD3:	LD		HL,(L822B)
L8CD6:	PUSH	HL
		CALL	L8CAB
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
L8CF0:	INC		(HL)
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
	
L8D18:		LD		HL,(L8D49)
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

L8D4B:		PUSH	HL
		PUSH	HL
		PUSH	IY
		PUSH	HL
		POP		IY
		CALL	LB0C6
		POP		IY
		POP		HL
		CALL	L8D6F
		POP		IX
		SET		7,(IX+$04)
		LD		A,(L703D)
		LD		C,(IX+$0A)
		XOR		C
		AND		$80
		XOR		C
		LD		(IX+$0A),A
		RET
L8D6F:	PUSH	IY
		INC		HL
		INC		HL
		CALL	LA1D8
		EX		DE,HL
		LD		H,B
		LD		L,C
		CALL	LA0A8
		POP		IY
		RET
L8D7F:	PUSH	HL
		PUSH	HL
		PUSH	IY
		PUSH	HL
		POP		IY
		CALL	LB03B
		POP		IY
		POP		HL
		CALL	L8D6F
		POP		IX
		RES		7,(IX+$04)
		LD		(IX+$0B),$FF
		LD		(IX+$0C),$FF
		RET
	
#include "sprite_stuff.asm"
	
L8ED8:	DEFB $00
L8ED9:	DEFB $FF
L8EDA:	DEFB $FF
L8EDB:	LD		A,(IY+$0C)
		LD		(IY+$0C),$FF
		OR		$F0
		CP		$FF
		RET		Z
		LD		(L8EDA),A
		RET
L8EEB:	CALL	L9319
		LD		HL,L8EDA
		LD		A,(HL)
		LD		(HL),$FF
		PUSH	AF
		CALL	LookupDir
		INC		A
		SUB		$01
		CALL	NC,L921B
		POP		AF
		CALL	L92DF
		CALL	L92CF
		JP		L92B7
L8F08:	BIT		5,(IY+$0C)
		RET		NZ
		CALL	L92CF
		CALL	L92B7
		LD		B,$47
		JP		PlaySound
L8F18:	LD		H,B
		LD		HL,L8F18
		LD		A,(HL)
		AND		A
		RET		NZ
		LD		(HL),$60
		LD		(IY+$0B),$F7
		LD		(IY+$0A),$19
		LD		A,$05
		JP		LA92C
L8F2E:	NOP
		LD		HL,L8F2E
		LD		(HL),$FF
		PUSH	HL
		CALL	L8F3C
		POP		HL
		LD		(HL),$00
		RET
L8F3C:	LD		A,(L822D)
		INC		A
		JR		NZ,L8F82
		LD		A,(IY+$0C)
		AND		$20
		RET		NZ
		LD		BC,(LA2BB)
		JR		L8F61
L8F4E:	LD		A,(L822D)
		INC		A
		JR		NZ,L8F82
		CALL	L9269
		OR		$F3
		CP		C
		JR		Z,L8F61
		LD		A,C
		OR		$FC
		CP		C
		RET		NZ
L8F61:	LD		(IY+$0C),C
		JR		L8F82
L8F66:	CALL	L92D2
		CALL	L8F97
		JR		C,L8F71
		CALL	L8F97
L8F71:	JP		C,L905D
		JR		L8F88
L8F76:	LD		A,(L822D)
		INC		A
		JR		NZ,L8F82
		LD		A,(IY+$0C)
		INC		A
		JR		Z,L8F8B
L8F82:	CALL	L9319
		CALL	L8F97
L8F88:	JP		L92B7
L8F8B:	PUSH	IY
		CALL	L90CC
		POP		IY
		LD		(IY+$0B),$FF
		RET
L8F97:	LD		A,(L822D)
		AND		A,(IY+$0C)
		CALL	LookupDir
		CP		$FF
		SCF
		RET		Z
		CALL	L8FC0
		RET		C
		PUSH	AF
		CALL	L92A6
		POP		AF
		PUSH	AF
		CALL	L8CD3
		POP		AF
		LD		HL,(L8F2E)
		INC		L
		RET		Z
		CALL	L8FC0
		RET		C
		CALL	L8CD3
		AND		A
		RET
L8FC0:	LD		HL,(L822B)
		JP		LB21C
L8FC6:	LD		A,(IY+$0C)
		OR		$C0
		INC		A
		JR		NZ,L8FD2
		LD		(IY+$11),A
		RET
L8FD2:	LD		A,(IY+$11)
		AND		A
		JR		Z,L8FDD
		LD		(IY+$0C),$FF
		RET
L8FDD:	DEC		(IY+$11)
		CALL	L9314
		LD		HL,LAF80
L8FE6:	LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		OR		H
		JR		Z,L8FF7
		PUSH	HL
		PUSH	HL
		POP		IX
		CALL	L9005
		POP		HL
		JR		L8FE6
L8FF7:	CALL	L92D6
		LD		A,(IY+$04)
		XOR		$10
		LD		(IY+$04),A
		JP		L92B7
L9005:	LD		A,(IX+$0A)
		AND		$7F
		CP		$0E
		RET		Z
		CP		$11
		RET		Z
		LD		A,(IX+$09)
		LD		C,A
		AND		$09
		RET		NZ
		LD		A,C
		XOR		$40
		LD		(IX+$09),A
		RET
L901E:	LD		A,$90
		LD		BC,L523E
		LD		(IY+$11),A
		LD		(IY+$0A),$10
		RET
L902B:	BIT		5,(IY+$0C)
		RET		NZ
		CALL	L931F
		JP		L92B7
L9036:	LD		A,$FE
		JR		L9044
L903A:	LD		A,$FD
		JR		L9044
L903E:	LD		A,$F7
		JR		L9044
L9042:	LD		A,$FB
L9044:	LD		(IY+$0B),A
		LD		(IY+$0A),$00
		RET
	
L904C:		LD	A,(Character)
		AND	$02			; Test if we have Head (returns early if not)
		JR	L905C

L9053:		LD	A,$C0
		LD	BC,LCF3E
		OR	A,(IY+$0C)
		INC	A
	;; NB: Fall through

L905C:		RET	Z	
L905D:		LD	A,$05
		CALL	LA92C
		LD	A,(IY+$0A)
		AND	$80
		OR	$11
		LD	(IY+$0A),A
		LD	(IY+$0F),$08
		LD	(IY+$04),$80
		CALL	L92A6
		CALL	L92D2
		LD	A,(IY+$0F)
		AND	$07
		JP	NZ,L92B7
		LD	HL,(L822B)
		JP	L8D4B

L9088:	LD		B,(IY+$08)
		BIT		5,(IY+$0C)
		SET		5,(IY+$0C)
		LD		A,$2C
		JR		Z,L90B3
		LD		A,(IY+$0F)
		AND		A
		JR		NZ,L90AD
		LD		A,$2C
		CP		B
		JR		NZ,L90CC
		LD		(IY+$0F),$50
		LD		A,$04
		CALL	LA92C
		JR		L90C6
L90AD:	AND		$07
		JR		NZ,L90C6
		LD		A,$2B
L90B3:	LD		(IY+$08),A
		LD		(IY+$0F),$00
		CP		B
		JR		Z,L90CC
		JR		L90C6
L90BF:	LD		A,(IY+$0F)
		AND		$F0
		JR		Z,L90CC
L90C6:	CALL	L92A6
		CALL	L92D2
L90CC:	CALL	L9319
		LD		A,$FF
		CALL	L92DF
		JP		L92B7
L90D7:		LD		HL,L921F
		JP		L911B
L90DD:		LD		HL,L920D
		JP		L911B
L90E3:		LD		HL,L921F
		JR		L9121
L90E8:		LD		HL,L920D
		JR		L9121
L90ED:		LD		HL,L9214
		JR		L9121
L90F2:		LD		HL,L9200
		JR		L9121
L90F7:		LD		HL,L9200
		JR		L9155
L90FC:		LD		HL,L91E4
		JR		L9155
L9101:		LD		HL,L91F1
		JR		L9155
L9106:		LD		HL,L9245
		JR		L9141

L910B:	LD		A,(L866B)
		OR		$F0
		INC		A
		LD		HL,L925D
		JR		Z,L9119
		LD		HL,L9264
L9119:	JR		L9141
L911B:	PUSH	HL
		CALL	L92CF
		JR		L912C
L9121:	PUSH	HL
L9122:	CALL	L92CF
		CALL	L9319
		LD		A,$FF
		JR		C,L912F
L912C:	CALL	L936A
L912F:	CALL	L92DF
		POP		HL
		LD		A,(L8ED9)
		INC		A
		JP		Z,L92B7
		CALL	L9140
		JP		L92B7
L9140:	JP		(HL)
L9141:	PUSH	HL
		CALL	L9319
		POP		HL
		CALL	L9140
L9149:	CALL	L92CF
		CALL	L936A
		CALL	L92DF
		JP		L92B7
L9155:	PUSH	HL
		CALL	L8D18
		LD		A,L
		AND		$0F
		JR		NZ,L9122
		CALL	L9319
		POP		HL
		CALL	L9140
		CALL	L92CF
		CALL	L936A
		CALL	L92DF
		JP		L92B7
L9171:	NOP
		LD		A,$01
		CALL	LA92C
		CALL	L92CF
		LD		A,(IY+$11)
		LD		B,A
		BIT		3,A
		JR		Z,L91BE
		RRA
		RRA
		AND		$3C
		LD		C,A
		RRCA
		ADD		A,C
		NEG
		ADD		A,$C0
		CP		A,(IY+$07)
		JR		NC,L91A8
		LD		HL,(L822B)
		CALL	LAC41
		RES		4,(IY+$0B)
		JR		NC,L91A0
		JR		Z,L91E1
L91A0:	CALL	L92A6
		DEC		(IY+$07)
		JR		L91E1
L91A8:	LD		HL,L9171
		LD		A,(HL)
		AND		A
		JR		NZ,L91B1
		LD		(HL),$02
L91B1:	DEC		(HL)
		JR		NZ,L91E1
		LD		A,B
		XOR		$08
		LD		(IY+$11),A
		AND		$08
		JR		L91E1
L91BE:	AND		$07
		ADD		A,A
		LD		C,A
		ADD		A,A
		ADD		A,C
		NEG
		ADD		A,$BF
		CP		A,(IY+$07)
		JR		C,L91A8
		LD		HL,(L822B)
		CALL	LAB06
		JR		NC,L91D7
		JR		Z,L91E1
L91D7:	CALL	L92A6
		RES		5,(IY+$0B)
		INC		(IY+$07)
L91E1:	JP		L92B7
L91E4:	CALL	L8D18
		LD		A,L
		AND		$06
		CP		A,(IY+$10)
		JR		Z,L91E4
		JR		L921B
L91F1:	CALL	L8D18
		LD		A,L
		AND		$06
		OR		$01
		CP		A,(IY+$10)
		JR		Z,L91F1
		JR		L921B
L9200:	CALL	L8D18
		LD		A,L
		AND		$07
		CP		A,(IY+$10)
		JR		Z,L9200
		JR		L921B
L920D:	LD		A,(IY+$10)
		SUB		$02
		JR		L9219
L9214:	LD		A,(IY+$10)
		ADD		A,$02
L9219:	AND		$07
L921B:	LD		(IY+$10),A
		RET
L921F:	LD		A,(IY+$10)
		ADD		A,$04
		JR		L9219
L9226:	CALL	L9319
		CALL	L9269
		LD		A,$18
		CP		D
		JR		C,L923F
		CP		E
		JP		C,L923F
		LD		A,C
		CALL	LookupDir
		LD		(IY+$10),A
		JP		L9149
L923F:	CALL	L92CF
		JP		L92B7
L9245:	CALL	L9269
		LD		A,D
		CP		E
		LD		B,$F3
		JR		C,L9251
		LD		A,E
		LD		B,$FC
L9251:	AND		A
		LD		A,B
		JR		NZ,L9257
		XOR		$0F
L9257:	OR		C
L9258:	CALL	LookupDir
		JR		L921B
L925D:	CALL	L9269
		XOR		$0F
		JR		L9258
L9264:	CALL	L9269
		JR		L9258
L9269:	CALL	LA94B
		LD		DE,L0005
		ADD		HL,DE
		LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		LD		C,$FF
		LD		A,H
		SUB		(IY+$06)
		LD		D,A
		JR		Z,L928A
		JR		NC,L9283
		NEG
		LD		D,A
		SCF
L9283:	PUSH	AF
		RL		C
		POP		AF
		CCF
		RL		C
L928A:	LD		A,(IY+$05)
		SUB		L
		LD		E,A
		JR		Z,L92A0
		JR		NC,L9297
		NEG
		LD		E,A
		SCF
L9297:	PUSH	AF
		RL		C
		POP		AF
		CCF
		RL		C
		LD		A,C
		RET
L92A0:	RLC		C
		RLC		C
		LD		A,C
		RET
L92A6:	LD		A,(L8ED8)
		BIT		0,A
		RET		NZ
		OR		$01
		LD		(L8ED8),A
		LD		HL,(L822B)
		JP		LA05D
L92B7:	LD		(IY+$0C),$FF
		LD		A,(L8ED8)
		AND		A
		RET		Z
		CALL	L92A6
		LD		HL,(L822B)
		CALL	LB0BE
		LD		HL,(L822B)
		JP		LA0A5
L92CF:	CALL	L937E
L92D2:	CALL	L82C9
		RET		NC
L92D6:	LD		A,(L8ED8)
		OR		$02
		LD		(L8ED8),A
		RET
L92DF:	AND		A,(IY+$0C)
		CP		$FF
		LD		(L8ED9),A
		RET		Z
		CALL	LookupDir
		CP		$FF
		LD		(L8ED9),A
		RET		Z
		PUSH	AF
		LD		(L8ED9),A
		CALL	L8FC0
		POP		BC
		CCF
		JP		NC,L930F
		PUSH	AF
		CP		B
		JR		NZ,L9306
		LD		A,$FF
		LD		(L8ED9),A
L9306:	CALL	L92A6
		POP		AF
		CALL	L8CD3
		SCF
		RET
L930F:	LD		A,(L822D)
		INC		A
		RET		Z
L9314:	LD		A,$06
		JP		LA92C
L9319:	BIT		4,(IY+$0C)
		JR		Z,L9354
L931F:	LD		HL,(L822B)
		CALL	LAB06
		JR		NC,L933D
		CCF
		JR		NZ,L9331
		BIT		4,(IY+$0C)
		RET		NZ
		JR		L9354
L9331:	BIT		4,(IY+$0C)
		SCF
		JR		NZ,L933D
		RES		4,(IY+$0B)
		RET
L933D:	PUSH	AF
		CALL	L92A6
		RES		5,(IY+$0B)
		INC		(IY+$07)
		LD		A,$03
		CALL	LA92C
		POP		AF
		RET		C
		INC		(IY+$07)
		SCF
		RET
L9354:	LD		HL,(L822B)
		CALL	LAC41
		RES		4,(IY+$0B)
		JR		NC,L9362
		CCF
		RET		Z
L9362:	CALL	L92A6
		DEC		(IY+$07)
		SCF
		RET
L936A:	LD		A,(IY+$10)
		ADD		A,$76
		LD		L,A
		ADC		A,$93
		SUB		L
		LD		H,A
		LD		A,(HL)
		RET
L9376:	DEFB $FD,$F9,$FB,$FA,$FE,$F6,$F7,$F5
L937E:	LD		C,(IY+$10)
		BIT		1,C
		RES		4,(IY+$04)
		JR		NZ,L938D
		SET		4,(IY+$04)
L938D:	LD		A,(IY+$0F)
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
	
MainLoop3:	LD	A,(L703D)
		XOR	$80
		LD	(L703D),A 		; Toggle top bit of L703D
		CALL	LA361
		LD	HL,(LAF80) 		; Init pointer...
		JR	ML3_3			; and jump to test part
ML3_1:		PUSH	HL
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A			; Read pointer in
		EX	(SP),HL			; FIXME: Starts to get a bit mysterious
		EX	DE,HL
		LD	HL,L000A
		ADD	HL,DE
		LD	A,(L703D)
		XOR	(HL)
		CP	$80
		JR	C,ML3_2
		LD	A,(HL)
		XOR	$80
		LD	(HL),A
		AND	$7F
		CALL	NZ,L82A1
ML3_2:		POP	HL
ML3_3:		LD	A,H			; loop until null pointer.
		OR	L
		JR	NZ,ML3_1
		RET

L93E2:	DEFW $0000
	
Attrib0:	DEFB $00
Attrib3:	DEFB $43
Attrib4:	DEFB $45
Attrib5:	DEFB $46

#include "blit_screen.asm"

#include "screen_bits.asm"

#include "controls2.asm"

#include "sound.asm"
	
#include "blit_mask.asm"
	
L9BBE:		LD	HL,(SpriteXExtent)
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
		JR	NC,L9BF0
		LD	IY,L9DF8
		LD	IX,L9EA9
		LD	HL,Thingie3
		CALL	L9C16
		CP	$FF
		RET	Z
		SUB	$01
		JR	L9C01
L9BF0:		LD	IY,L9E07
		LD	IX,L9EBB
		LD	HL,Thingie1
		CALL	L9C16
		INC	E
		SUB	$02
L9C01:		JR	NC,L9BF0
		INC	A
		RET	NZ
		LD	IY,L9DF8
		LD	IX,L9EAD
		LD	HL,Thingie2
		LD	(L9CD1+1),HL
		EXX
		JR	L9C28 		; Tail call.

	
L9C16:		LD	(L9CD1+1),HL
		PUSH	DE
		PUSH	AF
		EXX
		PUSH	HL
		CALL	L9C28
		POP	HL
		INC	L
		INC	L
		EXX
		POP	AF
		POP	DE
		INC	E
		RET

	
L9C28:		LD		DE,(SpriteYExtent)
		LD		A,E
		SUB		D
		LD		E,A
		LD		A,(HL)
		AND		A
		JR		Z,L9C7F
		LD		A,D
		SUB		(HL)
		LD		D,A
		JR		NC,L9C82
		INC		HL
		LD		C,$38
		BIT		2,(HL)
		JR		Z,L9C41
		LD		C,$4A
L9C41:	ADD		A,C
		JR		NC,L9C4F
		ADD		A,A
		CALL	L9D77
		EXX
		LD		A,D
		NEG
		JP		L9C6B
L9C4F:	NEG
		CP		E
		JR		NC,L9C7F
		LD		B,A
		NEG
		ADD		A,E
		LD		E,A
		LD		A,B
		CALL	L9DF6
		LD		A,(HL)
		EXX
		CALL	L9DBF
		EXX
		LD		A,$38
		BIT		2,(HL)
		JR		Z,L9C6B
		LD		A,$4A
L9C6B:	CP		E
		JR		NC,L9C7C
		LD		B,A
		NEG
		ADD		A,E
		EX		AF,AF'
		LD		A,B
		CALL	L9DF4
		EX		AF,AF'
		LD		D,$00
		JR		L9C84
L9C7C:	LD		A,E
		JP		(IX)
L9C7F:	LD		A,E
		JP		(IY)
L9C82:	LD		A,E
		INC		HL
L9C84:	LD		B,A
		DEC		HL
		LD		A,L
		ADD		A,A
		ADD		A,A
		ADD		A,$04
L9C8B:	CP		$00	; NB: Target of self-modifying code.
		JR		C,L9C9B
		LD		E,$00
		JR		NZ,L9C95
		LD		E,$05
L9C95:	SUB		$04
L9C97:	ADD		A,$00 	; NB: Target of self-modifying code.
		JR		L9CA3
L9C9B:	ADD		A,$04
		NEG
L9C9F:	ADD		A,$00 	;NB: Target of self-modifying code.
		LD		E,$08
L9CA3:	NEG
		ADD		A,$0B
		LD		C,A
		LD		A,E
		LD		(L9CF5+1),A
		LD		A,(HL)
		ADD		A,D
		INC		HL
		SUB		C
		JR		NC,L9CCA
		ADD		A,$0B
		JR		NC,L9CCD
		LD		E,A
		SUB		$0B
		ADD		A,B
		JR		C,L9CBF
		LD		A,B
		JR		L9CEC
L9CBF:	PUSH	AF
		SUB		B
		NEG
L9CC3:	CALL	L9CEC
		POP		AF
		RET		Z
		JP		(IY)
L9CCA:	LD		A,B
		JP		(IY)
L9CCD:	ADD		A,B
		JR		C,L9CD4
		LD		A,B
L9CD1:	JP		L0000
L9CD4:	PUSH	AF
		SUB		B
		NEG
		CALL	L9CD1
		POP		AF
		RET		Z
		SUB		$0B
		LD		E,$00
		JR		NC,L9CE7
		ADD		A,$0B
		JR		L9CEC
L9CE7:	PUSH	AF
		LD		A,$0B
		JR		L9CC3
L9CEC:	PUSH	DE
		EXX
		POP		HL
		LD		H,$00
		ADD		HL,HL
		LD		BC,L9D03
L9CF5:	JR		L9CFF	; NB: Target of self-modifying code.
L9CF7:	LD		BC,L9D19
		JR		L9CFF
L9CFC:	LD		BC,L9D2F
L9CFF:	ADD		HL,BC
		EXX
		JP		(IX)
L9D03:	LD		B,B	; NB: Target of self-modifying code.
L9D04:	NOP			; NB: Target of self-modifying code.
		LD		(HL),B
		NOP
		LD		(HL),H
		NOP
		LD		(HL),A
		NOP
		SCF
		LD		B,B
		RLCA
		LD		(HL),B
		INC		BC
		LD		(HL),H
		NOP
		LD		(HL),A
		NOP
		SCF
		NOP
		RLCA
		NOP
		INC		BC
L9D19:	NOP			; NB: Target of self-modifying code.
		LD		BC,L0D00
		NOP
		DEC		A
		NOP
		LD		A,L
		LD		BC,L0D7C
		LD		(HL),B
		DEC		A
		LD		B,B
		LD		A,L
		NOP
		LD		A,H
		NOP
		LD		(HL),B
		NOP
		LD		B,B
		NOP
L9D2F:	LD		B,B 	; NB: Target of self-modifying code? Perhaps just data?
		LD		BC,L0D70
		LD		(HL),H
		DEC		A
		LD		(HL),A
		LD		A,L
		SCF
		LD		A,H
		RLCA
		LD		(HL),B
		INC		BC
		LD		B,B
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
L9D45:		LD		HL,(FloorAddr)
		LD		(L93E2),BC
		LD		BC,L000A
		ADD		HL,BC
		LD		C,$10
		LD		A,(L7717)
		RRA
		PUSH	HL
		JR		NC,L9D5B
		ADD		HL,BC
		EX		(SP),HL
L9D5B:	ADD		HL,BC
		RRA
		JR		NC,L9D62
		AND		A
		SBC		HL,BC
L9D62:	LD		DE,L9D19
		CALL	L9D6D
		POP		HL
		INC		HL
		LD		DE,L9D04
L9D6D:	LD		A,$04
L9D6F:	LDI
		INC		HL
		INC		DE
		DEC		A
		JR		NZ,L9D6F
		RET
L9D77:	PUSH	AF
		LD		A,(HL)
		EXX
		CALL	L9DBF
		POP		AF
		ADD		A,L
		LD		L,A
		RET		NC
		INC		H
		RET
	
SomeBuffFlag:	DEFB $00
	
GetSomeBuff:	LD	A,(SomeBuffFlag)
		AND	A
		LD	HL,SomeBuff
		RET	Z
		PUSH	HL
		PUSH	BC
		PUSH	DE
		LD	BC,SomeBuffLen
		CALL	FillZero
		POP	DE
		POP	BC
		POP	HL
		XOR	A
		LD	(SomeBuffFlag),A
		RET

L9D9D:		BIT	0,A
		JR	NZ,GetSomeBuff		; Tail call
		LD	L,A
		LD	A,(SomeBuffFlag)
		AND	A
		CALL	Z,RestoreSomeBuffFaff
		LD	A,(SomeBuffFlag2)
		XOR	L
		RLA
		LD	HL,SomeBuff
		RET	NC
		LD	A,(SomeBuffFlag2)
		XOR	$80
		LD	(SomeBuffFlag2),A
		LD	B,$4A
		JP	FlipSprite 		; Tail call

L9DBF:		BIT	2,A
		JR	NZ,L9D9D
		PUSH	AF
		CALL	L9DD1
		EX	AF,AF'
		POP	AF
		CALL	GetPanelAddr
		EX	AF,AF'
		RET	NC
		JP	FlipPanel 	; Tail call

	
L9DD1:	LD		C,A
		LD		HL,(L84C5)
		AND		$03
		LD		B,A
		INC		B
		LD		A,$01
L9DDB:	RRCA
		DJNZ	L9DDB
		LD		B,A
		AND		(HL)
		JR		NZ,L9DEA
		RL		C
		RET		NC
		LD		A,B
		OR		(HL)
		LD		(HL),A
		SCF
		RET
L9DEA:	RL		C
		CCF
		RET		NC
		LD		A,B
		CPL
		AND		(HL)
		LD		(HL),A
		SCF
		RET
L9DF4:	JP		(IX)
L9DF6:	JP		(IY)
L9DF8:	EXX			; Self-modifying code, or actually just data!
		LD		B,A
		EX		DE,HL
		LD		E,$00
L9DFD:	LD		(HL),E
		LD		A,L
		ADD		A,$06
		LD		L,A
		DJNZ	L9DFD
		EX		DE,HL
		EXX
		RET
L9E07:	EXX
		LD		B,A
		EX		DE,HL
		LD		E,$00
L9E0C:	LD		(HL),E
		INC		L
		LD		(HL),E
		LD		A,L
		ADD		A,$05
		LD		L,A
		DJNZ	L9E0C
		EX		DE,HL
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

	;; Given the 'Thingie's are the only things to call
	;; GetFloorAddr, I must conclude they are involved in actually
	;; drawing the floor...
	
	;; FIXME: Very similar to Thingie2!
Thingie1:	LD	B,A
		LD	A,D
		BIT	7,(HL)
		EXX
		LD	C,$00
		JR	Z,Thingie1b
		LD	C,$10
Thingie1b:	CALL	GetFloorAddr
		AND	$0F
		ADD	A,A
		LD	H,$00
		LD	L,A
		EXX
Thingie1c:	EXX
		PUSH	HL
		ADD	HL,BC
		LD	A,(HL)
		LD	(DE),A
	;; Start of diff with Thingie2
		INC	HL
		INC	E
		LD	A,(HL)
		LD	(DE),A
		LD	A,E
		ADD	A,$05
	;; End of diff with Thingie2
		LD	E,A
		POP	HL
		LD	A,L
		ADD	A,$02
		AND	$1F
		LD	L,A
		EXX
		DJNZ	Thingie1c
		RET

	;; Like Thingie2, but we set the bottom bit on C.
Thingie3:	LD	B,A
		LD	A,D
		BIT	7,(HL)
		EXX
		LD	C,$01
		JR	Z,Thingie2b
		LD	C,$11
		JR	Thingie2b

Thingie2:	LD	B,A
		LD	A,D
		BIT	7,(HL)
		EXX
		LD	C,$00
		JR	Z,Thingie2b
		LD	C,$10
Thingie2b:	CALL	GetFloorAddr
		AND	$0F
		ADD	A,A
		LD	H,$00
		LD	L,A
		EXX
Thingie2c:	EXX
		PUSH	HL
		ADD	HL,BC
		LD	A,(HL)
		LD	(DE),A
	;; Start of diff with Thingie1
		LD	A,E
		ADD	A,$06
	;; End of diff with Thingie1
		LD	E,A
		POP	HL
		LD	A,L
		ADD	A,$02
		AND	$1F
		LD	L,A
		EXX
		DJNZ	Thingie2c
		RET

L9EA9:	EXX
		INC		HL
		JR		L9EAE
L9EAD:	EXX
L9EAE:	LD		B,A
L9EAF:	LD		A,(HL)
		LD		(DE),A
		INC		HL
		INC		HL
		LD		A,E
		ADD		A,$06
		LD		E,A
		DJNZ	L9EAF
		EXX
		RET
L9EBB:	EXX
		LD		B,A
L9EBD:	LD		A,(HL)
		LD		(DE),A
		INC		HL
		INC		E
		LD		A,(HL)
		LD		(DE),A
		INC		HL
		LD		A,E
		ADD		A,$05
		LD		E,A
		DJNZ	L9EBD
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

SomeBuffFlag2:	DEFB $00

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

#include "blit_rot.asm"
	
SpriteXExtent:	DEFW $6066
SpriteYExtent:	DEFW $5070
LA056:	DEFB $00
SpriteByteCount:	DEFB $00
LA058:	DEFB $00
LA059:	DEFB $00
LA05A:	DEFB $00
LA05B:	DEFB $00
SpriteFlags:	DEFB $00
LA05D:	INC		HL
		INC		HL
		CALL	LA1D8
		LD		(LA058),BC
		LD		(LA05A),HL
		RET

	
LA06A:		INC		HL
		INC		HL
		CALL		LA1D8
		LD		DE,(LA05A)
		LD		A,H
		CP		D
		JR		NC,LA078
		LD		D,H
LA078:		LD		A,E
		CP		L
		JR		NC,LA07D
		LD		E,L
LA07D:		LD		HL,(LA058)
		LD		A,B
		CP		H
		JR		NC,LA085
		LD		H,B
LA085:		LD		A,L
		CP		C
		RET		NC
		LD		L,C
		RET


LA08A:		LD		A,L
		ADD		A,$03
		AND		$FC
		LD		L,A
		LD		A,H
		AND		$FC
		LD		H,A
		LD		(SpriteXExtent),HL
		RET


LA098:		CALL	LA08A
		JR	LA0AF

LA09D:		LD	A,$48
		CP	E
		RET	NC
		LD	D,$48
		JR	LA0B6

LA0A5:		CALL	LA06A
LA0A8:		CALL	LA08A
		LD	A,E
		CP	$F1
		RET	NC
LA0AF:		LD	A,D
		CP	E
		RET	NC
		CP	$48
		JR	C,LA09D

LA0B6:		LD	(SpriteYExtent),DE
		CALL	L9BBE
		LD	A,(L7716)
		AND	$0C
		JR	Z,LA109
		LD	E,A
		AND	$08
		JR	Z,LA0EC
		LD	BC,(SpriteXExtent)
		LD	HL,L84C9
		LD	A,B
		CP	(HL)
		JR	NC,LA0EC
		LD	A,(SpriteYExtent+1)
		ADD	A,B
		RRA
		LD	D,A
		LD	A,(L84C7)
		CP	D
		JR	C,LA0EC
		LD	HL,LAF82
		PUSH	DE
		CALL	LA11E
		POP	DE
		BIT	2,E
		JR	Z,LA109
LA0EC:		LD	BC,(SpriteXExtent)
		LD	A,(L84C9)
		CP	C
		JR	NC,LA109
		LD	A,(SpriteYExtent+1)
		SUB	C
		CCF
		RRA
		LD	D,A
		LD	A,(L84C8)
		CP	D
		JR	C,LA109
		LD	HL,LAF86
		CALL	LA11E
LA109:		LD	HL,LAF8A
		CALL	LA11E
		LD	HL,LAF7E
		CALL	LA11E
		LD	HL,LAF8E
		CALL	LA11E
		JP	BlitScreen

	;; TODO: This function is seriously epic...	
LA11E:		LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		OR		H
		RET		Z
		LD		(BigSpriteThing+1),HL
		CALL	LA12F
BigSpriteThing:		LD		HL,L0000 	; NB: Self-modifying code
		JR		LA11E
LA12F:		CALL	LA1BD
		RET		NC
		LD		(SpriteByteCount),A
		LD		A,H
		ADD		A,A
		ADD		A,H
		ADD		A,A
		EXX
		SRL		H
		SRL		H
		ADD		A,H
		LD		E,A
		LD		D,SpriteBuff >> 8
		PUSH	DE
		PUSH	HL
		EXX
		LD		A,L
		NEG
		LD		B,A
		LD		A,(SpriteWidth)
		AND		$04
		LD		A,B
		JR		NZ,LA156
		ADD		A,A
		ADD		A,B
		JR		LA158
LA156:		ADD		A,A
		ADD		A,A
LA158:		PUSH	AF
		CALL	GetSpriteAddr
		POP		BC
		LD		C,B
		LD		B,$00
		ADD		HL,BC
		EX		DE,HL
		ADD		HL,BC
		LD		A,(LA056)
		AND		$03
		CALL	NZ,BlitRot
		POP		BC
		LD		A,C
		NEG
		ADD		A,$03
		RRCA
		RRCA
		AND		$07
		LD		C,A
		LD		B,$00
		ADD		HL,BC
		EX		DE,HL
		ADD		HL,BC
		POP		BC
		EXX
		LD		A,(SpriteWidth)
		SUB		$03
		ADD		A,A
		LD		E,A
		LD		D,$00
		LD		HL,LA19F
		ADD		HL,DE
		LD		E,(HL)
		INC		HL
		LD		D,(HL)
		EX		AF,AF'
		DEC		A
		RRA
		AND		$0E
		LD		L,A
		LD		H,$00
		ADD		HL,DE
		LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		LD		A,(SpriteByteCount)
		LD		B,A
		JP		(HL)
LA19F:		AND		L 	; FIXME: Might just be data?!
		AND		C
		XOR		E
		AND		C
		OR		E
		AND		C
		DEC		H
		SBC		A,D
		LD		A,(L569A)
		SBC		A,D
		LD		A,C
		SBC		A,D
		SUB		B
		SBC		A,D
		XOR		(HL)
		SBC		A,D
		OUT		($9A),A
		CP		$9A
		RLA
		SBC		A,E
		SCF
		SBC		A,E
		LD		E,(HL)
		SBC		A,E
		ADC		A,E
		SBC		A,E
LA1BD:		CALL	LA1F0
		LD		A,B
		LD		(LA056),A
		PUSH	HL
		LD		DE,(SpriteXExtent)
		CALL	LA20C
		EXX
		POP		BC
		RET		NC
		EX		AF,AF'
		LD		DE,(SpriteYExtent)
		CALL	LA20C
		RET


	
LA1D8:	INC		HL
		INC		HL
		LD		A,(HL)
		BIT		3,A
		JR		Z,LA1F3
		CALL	LA1F3
		LD		A,(SpriteFlags)
		BIT		5,A
		LD		A,$F0
		JR		Z,LA1ED
		LD		A,$F4
LA1ED:	ADD		A,H
		LD		H,A
		RET
LA1F0:	INC		HL
		INC		HL
		LD		A,(HL)
LA1F3:	BIT		4,A
		LD		A,$00
		JR		Z,LA1FB
		LD		A,$80
LA1FB:	EX		AF,AF'
		INC		HL
		CALL	LA231
		INC		HL
		INC		HL
		LD		A,(HL)
		LD		(SpriteFlags),A
		DEC		HL
		EX		AF,AF'
		XOR		(HL)
		JP		LADB7
LA20C:	LD		A,D
		SUB		C
		RET		NC
		LD		A,B
		SUB		E
		RET		NC
		NEG
		LD		L,A
		LD		A,B
		SUB		D
		JR		C,LA224
		LD		H,A
		LD		A,C
		SUB		B
		LD		C,L
		LD		L,$00
		CP		C
		RET		C
		LD		A,C
		SCF
		RET
LA224:	LD		L,A
		LD		A,C
		SUB		D
		LD		C,A
		LD		A,E
		SUB		D
		CP		C
		LD		H,$00
		RET		C
		LD		A,C
		SCF
		RET
LA231:	LD		A,(HL)
		LD		D,A
		INC		HL
		LD		E,(HL)
		SUB		E
		ADD		A,$80
		LD		C,A
		INC		HL
		LD		A,(HL)
		ADD		A,A
		SUB		E
		SUB		D
		ADD		A,$7F
		LD		B,A
		RET

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

	
LA260:	LD		HL,(L7748)
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
	
		DEFB $00	; FIXME
		DEFB $00	; Speed reset
		DEFB $00	; Springs reset
		DEFB $00	; Heels invuln reset
		DEFB $00	; Head invuln reset
		DEFB $08	; Heels lives reset
		DEFB $08	; Head lives reset
		DEFB $00	; Donuts reset
		DEFB $00	; FIXME
	
LA28B:		DEFB $00
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
LA298:	DEFB $03
LA299:	DEFB $02
	
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
LA2A7:	DEFB $00
LA2A8:	DEFB $00
LA2A9:	DEFB $00,$00,$00,$00,$20
LA2AE:	DEFB $28,$0B,$C0
LA2B1:	DEFB $24,$08
LA2B3:	DEFB $12
LA2B4:	DEFB $FF,$FF,$00,$00
LA2B8:	DEFB $08,$00,$00
LA2BB:	DEFB $0F
LA2BC:	DEFB $00
LA2BD:	DEFB $00
LA2BE:	DEFB $00
LA2BF:	DEFB $FF
LA2C0:	DEFB $00
LA2C1:	DEFB $00,$00,$00,$08
LA2C5:	DEFB $28,$0B,$C0
LA2C8:	DEFB $18,$21,$00,$FF,$FF
LA2CD:	DEFB $00,$00,$00,$00
LA2D1:	DEFB $00
LA2D2:	DEFB $00,$00,$00,$00,$08
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
		CALL	LA339
		LD		DE,L0048
		POP		HL
		ADD		HL,DE
		POP		DE
LA339:	LD		C,$06
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

	;; Something of an epic function...
	;; Think it involves general movement/firing etc.
LA361:		LD	A,(LA314)
		RLA
		CALL	C,LA316
		LD	HL,LB219
		LD	A,(HL)
		AND	A
		JR	Z,LA37E
		EXX
		LD	HL,Character
		LD	A,(LB21A)
		AND	(HL)
		EXX
		JP	NZ,LA4B8
		CALL	LA4B8
LA37E:		LD	HL,LA296
		LD	A,(HL)
		AND	A
		JP	NZ,LA4A9
		INC	HL
		OR	(HL)
		JP	NZ,LA4A2
		LD	HL,LA298
		DEC	(HL)
		JR	NZ,LA3A8
		LD	(HL),$03
		LD	HL,(Character)
		LD	A,H
		ADD	A,A
		OR	H
		OR	L
		RRA
		PUSH	AF
		LD	A,$02
		CALL	C,DecCount
		POP	AF
		RRA
		LD	A,$03
		CALL	C,DecCount
LA3A8:		LD	A,$FF
		LD	(LA2BF),A
		LD	A,(LB218)
		AND	A
		JR	Z,LA3C6
		LD	A,(LA2BC)
		AND	A
		JR	Z,LA3C3
		LD	A,(LA2BB)
		SCF
		RLA
		LD	(CurrDir),A
		JR	LA3C6
LA3C3:		LD	(LB218),A
LA3C6:		CALL	LA597
LA3C9:		CALL	LA94B
		PUSH	HL
		POP	IY
		LD	A,(IY+$07)
		CP	$84
		JR	NC,LA3E5
		XOR	A
		LD	(LA29F),A
		LD	A,(L7712)
		AND	A
		JR	NZ,LA3E5
		LD	A,$06
		LD	(LB218),A
	;; Check for Fire being pressed
LA3E5:		LD	A,(FirePressed)
		RRA
		JR	NC,LA451
		LD	A,(Character)
		OR	$FD
		INC	A
		LD	HL,LA2BC
		OR	(HL)
		JR	NZ,LA44E ; Jumps if not Head (alone) or ...
		LD	A,(LA28B)
		OR	$F9
		INC	A
		JR	NZ,LA44E
		LD	A,(LA2B8)
		CP	$08
		JR	NZ,LA44E
		LD	HL,LA2D7
		LD	DE,LA2AE
		LD	BC,L0003
		LDIR
		LD	HL,LA2A9
		PUSH	HL
		POP	IY
		LD	A,(L703D)
		OR	$19
		LD	(LA2B3),A
		LD	(IY+$04),$00
		LD	A,(LA2BB)
		LD	(LA2B4),A
		LD	(IY+$0C),$FF
		LD	(IY+$0F),$20
		CALL	LB03B
		LD	A,$06
		CALL	DecCount
		LD	B,$48
		CALL	PlaySound
		LD	A,(Donuts)
		AND	A
		JR	NZ,LA451
		LD	HL,LA28B
		RES	2,(HL)
		CALL	L8E1D
		JR	LA451
LA44E:		CALL	NopeNoise
LA451:		LD	HL,LB218
		LD	A,(HL)
		AND	$7F
		RET	Z
		LD	A,(LB219)
		AND	A
		JR	Z,LA461
		LD	(HL),$00
		RET
LA461:		LD	A,(LA295)
		AND	A
		JR	Z,LA499
		CALL	LA94B
		PUSH	HL
		POP	IY
		CALL	LB0C6
		LD	A,(Character)
		CP	$03
		JR	Z,LA499
		LD	HL,LA2A6
		CP	(HL)
		JR	Z,LA482
		XOR	$03
		LD	(HL),A
		JR	LA48D
LA482:		LD	HL,LFB49
		LD	DE,LA2A2
		LD	BC,L0005
		LDIR
LA48D:		LD	HL,L0000
		LD	(LA2CD),HL
		LD	(LA2DF),HL
		CALL	L72A0
LA499:		LD	HL,L0000
		LD	(LA2A7),HL
		JP	L70BA
LA4A2:		DEC	(HL)
		LD	HL,(Character)
		JP	LA543
LA4A9:		DEC	(HL)
		LD	HL,(Character)
		JP	NZ,LA54C
		LD	A,$07
		LD	(LB218),A
		JP	LA3C9
LA4B8:		DEC	(HL)
		JP	NZ,LA549
		LD	HL,L0000
		LD	(LA2A7),HL
		LD	HL,Lives
		LD	BC,(LB21A)
		LD	B,$02
		LD	D,$FF
LA4CD:		RR	C
		JR	NC,LA4DA
		LD	A,(HL)
		SUB	$01
		DAA
		LD	(HL),A
		JR	NZ,LA4DA
		LD	D,$00
LA4DA:		INC	HL
		DJNZ	LA4CD
		DEC	HL
		LD	A,(HL)
		DEC	HL
		OR	(HL)
		JP	Z,FinishGame
		LD	A,D
		AND	A
		JR	NZ,LA521
		LD	HL,Lives
		LD	A,(LA295)
		AND	A
		JR	Z,LA50F
		LD	A,(LA2A6)
		CP	$03
		JR	NZ,LA504
		LD	A,(HL)
		AND	A
		LD	A,$01
		JR	NZ,LA4FF
		INC	A
LA4FF:		LD	(LA2A6),A
		JR	LA521
LA504:		RRA
		JR	C,LA508
		INC	HL
LA508:		LD	A,(HL)
		AND	A
		JR	NZ,LA51E
		LD	(LA295),A
LA50F:		CALL	SwitchChar
		LD	HL,L0000
		LD	(LB219),HL
LA518:		LD	HL,LFB28
		SET	0,(HL)
		RET
LA51E:		CALL	LA518
LA521:		LD	A,(LA2A6)
		LD	(Character),A
		CALL	LA58B
		CALL	LA94B
		LD	DE,L0005
		ADD	HL,DE
		EX	DE,HL
		LD	HL,LA2A3
		LD	BC,L0003
		LDIR
		LD	A,(LA2A2)
		LD	(LB218),A
		JP	L70E6
LA543:		PUSH	HL
		LD	HL,LA30A
		JR	LA550
LA549:		LD	HL,(LB21A)
LA54C:		PUSH	HL
		LD	HL,LA2FC
LA550:		LD	IY,LA2C0
		CALL	L8CF0
		POP	HL
		PUSH	HL
		BIT	1,L
		JR	Z,LA572
		PUSH	AF
		LD	(LA2DA),A
		RES	3,(IY+$16)
		LD	HL,LA2D2
		CALL	LA05D
		LD	HL,LA2D2
		CALL	LA0A5
		POP	AF
LA572:		POP	HL
		RR	L
		RET	NC
		XOR	$80
		LD	(LA2C8),A
		RES	3,(IY+$04)
		LD	HL,LA2C0
		CALL	LA05D
		LD	HL,LA2C0
		JP	LA0A5
LA58B:		AND	$01
		RLCA
		RLCA
		LD	HL,SwopPressed
		RES	2,(HL)
		OR	(HL)
		LD	(HL),A
		RET

	;; Looks like more movement stuff
LA597:		CALL	LA94B
		PUSH	HL
		POP		IY
		LD		A,$3F
		LD		(LA2BD),A
		LD		A,(LA2BC)
		CALL	LAF96
		CALL	LA94B
		CALL	LA05D
		LD		HL,LA29F
		LD		A,(HL)
		AND		A
		JR		Z,LA608
		LD		A,(LA2BC)
		AND		A
		JR		Z,LA5BF
		LD		(HL),$00
		JR		LA608
LA5BF:	DEC		(HL)
		CALL	LA94B
		CALL	LAC41
		JR		C,LA5D2
		DEC		(IY+$07)
		LD		A,$84
		CALL	LA931
		JR		LA5E3
LA5D2:	EX		AF,AF'
		LD		A,$88
		BIT		4,(IY+$0B)
		SET		4,(IY+$0B)
		CALL	Z,LA931
		EX		AF,AF'
		JR		Z,LA5EE
LA5E3:	RES		4,(IY+$0B)
		SET		5,(IY+$0B)
		DEC		(IY+$07)
LA5EE:	LD		A,(Character)
		AND		$02
		JR		NZ,LA5FB
LA5F5:	LD		A,(LA2BB)
		JP		LA669
LA5FB:	LD		A,(CurrDir)
		RRA
		CALL	LookupDir
		INC		A
		JP		NZ,LA665
		JR		LA5F5
LA608:	SET		4,(IY+$0B)
		SET		5,(IY+$0C)
		CALL	LA94B
		LD		A,(LB218)
		AND		A
		JR		NZ,LA622
		CALL	LAA74
		JP		NC,LA724
		JP		NZ,LA712
LA622:	LD		A,(LB218)
		RLA
		JR		NC,LA62C
		LD		(IY+$0C),$FF
LA62C:	LD		A,$86
		BIT		5,(IY+$0B)
		SET		5,(IY+$0B)
		CALL	Z,LA931
		BIT		4,(IY+$0C)
		SET		4,(IY+$0C)
		JR		NZ,LA65B
		CALL	LA94B
		CALL	LAC41
		JR		NC,LA654
		JR		NZ,LA654
		LD		A,$88
		CALL	LA931
		JR		LA65B
LA654:	DEC		(IY+$07)
		RES		4,(IY+$0B)
LA65B:	XOR		A
		LD		(LA29E),A
		CALL	LA89A
		CALL	LA820
LA665:	LD		A,(CurrDir)
		RRA
LA669:	CALL	LA788
		CALL	LA774
		EX		AF,AF'
		LD		A,(LA2A0)
		INC		A
		JR		NZ,LA69C
		XOR		A
		LD		HL,Character
		BIT		0,(HL)
		JR		Z,LA684
		LD		(LA2E4),A
		LD		(LA2EA),A
LA684:	BIT		1,(HL)
		JR		Z,LA68E
		LD		(LA2F0),A
		LD		(LA2F6),A
LA68E:	EX		AF,AF'
		LD		BC,L1B21
		JR		C,LA6CC
		CALL	LA700
		LD		BC,L181F
		JR		LA6CC
LA69C:	EX		AF,AF'
		LD		HL,LA2E4
		LD		DE,LA2F0
		JR		NC,LA6AB
		LD		HL,LA2EA
		LD		DE,LA2F6
LA6AB:	PUSH	DE
		LD		A,(Character)
		RRA
		JR		NC,LA6B8
		CALL	L8CF0
		LD		(LA2C8),A
LA6B8:	POP		HL
		LD		A,(Character)
		AND		$02
		JR		Z,LA6C6
		CALL	L8CF0
		LD		(LA2DA),A
LA6C6:	SET		5,(IY+$0B)
		JR		LA6E4
LA6CC:	SET		5,(IY+$0B)
LA6D0:	LD		A,(Character)
		RRA
		JR		NC,LA6D9
		LD		(IY+$08),B
LA6D9:	LD		A,(Character)
		AND		$02
		JR		Z,LA6E4
		LD		A,C
		LD		(LA2DA),A
LA6E4:	LD		A,(LA2BF)
		LD		(IY+$0C),A
		CALL	LA94B
		CALL	LB0BE
		CALL	LAA42
		XOR		A
		CALL	LAF96
		CALL	LA94B
		CALL	LA0A5
		JP		LA938
LA700:	LD		HL,LA315
		DEC		(HL)
		LD		A,$03
		SUB		(HL)
		RET		C
		JR		Z,LA70F
		CP		$03
		RET		NZ
		LD		(HL),$40
LA70F:	JP		LA316
LA712:	LD		HL,LA29E
		LD		A,(HL)
		AND		A
		LD		(HL),$FF
		JR		Z,LA729
		CALL	LA89A
		CALL	LA820
		XOR		A
		JR		LA729
LA724:	XOR		A
		LD		(LA29E),A
		INC		A
LA729:	LD		C,A
		CALL	LA81A
		RES		5,(IY+$0B)
		LD		A,(Character)
		AND		$02
		JR		NZ,LA73E
		DEC		C
		JR		NZ,LA756
		INC		(IY+$07)
LA73E:	INC		(IY+$07)
		AND		A
		JR		NZ,LA759
		LD		A,$82
		CALL	LA931
		LD		HL,LA293
		LD		A,(HL)
		AND		A
		JR		Z,LA765
		DEC		(HL)
		LD		A,(LA2BB)
		JR		LA762
LA756:	INC		(IY+$07)
LA759:	LD		A,$83
		CALL	LA931
		LD		A,(CurrDir)
		RRA
LA762:	CALL	LA788
LA765:	CALL	LA774
		LD		BC,L1B21
		JP		C,LA6D0
		LD		BC,L184D
		JP		LA6D0
LA774:	LD		A,(LA2BB)
		CALL	LookupDir
		RRA
		RES		4,(IY+$04)
		RRA
		JR		C,LA786
		SET		4,(IY+$04)
LA786:	RRA
		RET


	;; Another character-updating function
LA788:	OR		$F0
		CP		$FF
		LD		(LA2A0),A
		JR		Z,LA7A3
		EX		AF,AF'
		XOR		A
		LD		(LA2A0),A
		LD		A,$80
		CALL	LA931
		EX		AF,AF'
		LD		HL,LA2BB
		CP		(HL)
		LD		(HL),A
		JR		Z,LA7A8
LA7A3:	CALL	LA81A
		LD		A,$FF
LA7A8:	PUSH	AF
		AND		A,(IY+$0C)
		CALL	LookupDir
		CP		$FF
		JR		Z,LA7C6
		CALL	LA94B
		CALL	LB21C
		JR		NC,LA7D0
		LD		A,(IY+$0B)
		OR		$F0
		INC		A
		LD		A,$88
		CALL	NZ,LA931
LA7C6:	POP		AF
		LD		A,(IY+$0B)
		OR		$0F
		LD		(IY+$0B),A
		RET
LA7D0:	CALL	LA94B
		CALL	L8CD6
		POP		BC
		LD		HL,LA2A1
		LD		A,(HL)
		AND		A
		JR		Z,LA7E0
		DEC		(HL)
		RET
LA7E0:		LD		HL,Speed ; FIXME: Fast if have Speed or are Heels...
		LD		A,(Character)
		AND		$01
		OR		(HL)
		RET		Z
		LD		HL,LA299
		DEC		(HL)
		PUSH	BC
		JR		NZ,LA7FE
		LD		(HL),$02
		LD		A,(Character)
		RRA
		JR		C,LA7FE
		LD		A,$00
		CALL	DecCount
LA7FE:	LD		A,$81
		CALL	LA931
		POP		AF
		CALL	LookupDir
		CP		$FF
		RET		Z
		CALL	LA94B
		PUSH	HL
		CALL	LB21C
		POP		HL
		JP		NC,L8CD6
		LD		A,$88
		JP		LA931
LA81A:	LD		A,$02
		LD		(LA2A1),A
		RET


	
LA820:	LD		A,(Character)
		LD		B,A
		DEC		A
		JR		NZ,LA82B
		XOR		A
		LD		(LA293),A
LA82B:	LD		A,(LA2BC)
		AND		A
		RET		NZ
		LD		A,(CurrDir)
		RRA
		RET		C
		LD		C,$00
		LD		L,(IY+$0D)
		LD		H,(IY+$0E)
		LD		A,H
		OR		L
		JR		Z,LA863
		PUSH	HL
		POP		IX
		BIT		0,(IX+$09)
		JR		Z,LA851
		LD		A,(IX+$0B)
		OR		$CF
		INC		A
		RET		NZ
LA851:	LD		A,(IX+$08)
		AND		$7F
		CP		$57
		JR		Z,LA88F
		CP		$2B
		JR		Z,LA862
		CP		$2C
		JR		NZ,LA863
LA862:	INC		C
LA863:	LD		A,(Character)
		AND		$02
		JR		NZ,LA873
		PUSH	BC
		LD		A,$01
		CALL	DecCount
		POP		BC
		JR		Z,LA874
LA873:	INC		C
LA874:	LD		A,C
		ADD		A,A
		ADD		A,A
		ADD		A,$04
		CP		$0C
		JR		NZ,LA87F
		LD		A,$0A
LA87F:	LD		(LA29F),A
		LD		A,$85
		DEC		B
		JR		NZ,LA88C
		LD		HL,LA293
		LD		(HL),$07
LA88C:	JP		LA931
LA88F:	LD		HL,L080C
		LD		(LA296),HL
		LD		B,$C7
		JP		PlaySound
LA89A:	LD		A,(CarryPressed)
		RRA
		RET		NC
		LD		A,(LA28B)
		RRA
LA8A3:	JP		NC,NopeNoise
		LD		A,(Character)
		AND		$01
		JR		Z,LA8A3
		LD		A,$87
		CALL	LA931
		LD		A,(LA2A8)
		AND		A
		JR		NZ,LA8D3
		CALL	LA94B
		CALL	LAC12
		JR		NC,LA8A3
		LD		A,(IX+$08)
		PUSH	HL
		LD		(LA2A7),HL
		LD		BC,LD8B0
		PUSH	AF
		CALL	Draw3x24
		POP		AF
		POP		HL
		JP		L8D4B
LA8D3:	LD		A,(LA2BC)
		AND		A
		JP		NZ,NopeNoise
		LD		C,(IY+$07)
		LD		B,$03
LA8DF:	CALL	LA94B
		PUSH	BC
		CALL	LAC41
		POP		BC
		JR		C,LA926
		DEC		(IY+$07)
		DEC		(IY+$07)
		DJNZ	LA8DF
		LD		HL,(LA2A7)
		PUSH	HL
		LD		DE,L0007
		ADD		HL,DE
		PUSH	HL
		CALL	LA94B
		LD		DE,L0006
		ADD		HL,DE
		EX		DE,HL
		POP		HL
		LD		(HL),C
		EX		DE,HL
		DEC		DE
		LDD
		LDD
		POP		HL
		CALL	L8D7F
		LD		HL,L0000
		LD		(LA2A7),HL
		LD		BC,LD8B0
		CALL	Clear3x24
		CALL	LA94B
		CALL	LAA74
		CALL	LA94B
		JP		LA05D
LA926:	LD		(IY+$07),C
		JP		NopeNoise
LA92C:	LD		HL,LA2BE
		JR		LA934
LA931:	LD		HL,LA2BD
LA934:	CP		(HL)
		RET		C
		LD		(HL),A
		RET
LA938:	LD		A,(LA2BD)
		OR		$80
		LD		B,A
		CP		$85
		JP		NC,PlaySound
		LD		A,(MENU_SOUND)
		AND		A
		RET		NZ
		JP		PlaySound
	
LA94B:		LD		HL,Character
		BIT		0,(HL)
		LD		HL,LA2C0
		RET		NZ
		LD		HL,LA2D2
		RET


	
LA958:	XOR		A
		LD		(LA2FC),A
		LD		(LA296),A
		LD		(LA30A),A
		LD		A,$08
		LD		(LA2B8),A
		CALL	SetCharThing
		LD		A,(Character)
		LD		(LA2A6),A
		CALL	LA94B
		PUSH	HL
		PUSH	HL
		PUSH	HL
		POP		IY
		LD		A,(LB218)
		LD		(LA2A2),A
		PUSH	AF
		SUB		$01
		PUSH	AF
		CP		$04
		JR		NC,LA99D
		XOR		$01
		LD		E,A
		LD		D,$00
		LD		HL,L7744
		ADD		HL,DE
		LD		C,(HL)
		LD		HL,LAA6E
		ADD		HL,DE
		LD		A,(L7716)
		AND		(HL)
		JR		NZ,LA99D
		LD		(IY+$07),C
LA99D:	CALL	LA94B
		LD		DE,L0005
		ADD		HL,DE
		EX		DE,HL
		POP		AF
		JR		C,LA9F2
		CP		$06
		JR		Z,LA9DA
		JR		NC,LA9ED
		CP		$04
		JR		NC,LA9C5
		LD		HL,L7718
		LD		C,$FD
		RRA
		JR		NC,LA9BC
		INC		DE
		INC		HL
LA9BC:	RRA
		JR		C,LA9FD
		LD		C,$03
		INC		HL
		INC		HL
		JR		LA9FD
LA9C5:	INC		DE
		INC		DE
		RRA
		LD		A,$84
		JR		NC,LA9D6
		LD		A,(L7B8F)
		AND		A
		LD		A,$BA
		JR		Z,LA9D6
		LD		A,$B4
LA9D6:	LD		(DE),A
		POP		AF
		JR		LAA0C
LA9DA:	INC		DE
		INC		DE
		LD		A,(L7B8F)
		AND		A
		JR		Z,LA9E6
		LD		A,(DE)
		SUB		$06
		LD		(DE),A
LA9E6:	LD		B,$C8
		CALL	PlaySound
		JR		LAA00
LA9ED:	LD		HL,L8ADF
		JR		LA9F5
LA9F2:	LD		HL,LAA64
LA9F5:	LDI
		LDI
		LDI
		JR		LAA00
LA9FD:	LD		A,(HL)
		ADD		A,C
		LD		(DE),A
LAA00:	POP		AF
		ADD		A,$67
		LD		L,A
		ADC		A,$AA
		SUB		L
		LD		H,A
		LD		A,(HL)
		LD		(LA2BB),A
LAA0C:	LD		A,$80
		LD		(LB218),A
		POP		HL
		LD		DE,L0005
		ADD		HL,DE
		LD		DE,LA2A3
		LD		BC,L0003
		LDIR
		LD		(IY+$0D),$00
		LD		(IY+$0E),$00
		LD		(IY+$0B),$FF
		LD		(IY+$0C),$FF
		POP		HL
		CALL	LB010
		CALL	LAA42
		XOR		A
		LD		(LB219),A
		LD		(LB21A),A
		LD		(L7B8F),A
		JP		LAF96
LAA42:	LD		A,(LAF77)
		LD		(LA2BC),A
		RET

	
LAA49:		LD		A,(Character)
		LD		HL,LA295
		RRA
		OR		(HL)
		RRA
		RET		NC
		LD		HL,(LA2A7)
		INC		H
		DEC		H
		RET		Z
		LD		DE,L0008
		ADD		HL,DE
		LD		A,(HL)
		LD		BC,LD8B0
		JP		Draw3x24

LAA64:	DEFB $28,$28,$C0,$FD,$FD,$FB,$FE,$F7,$FD,$FD
LAA6E:	DEFB 08,$04,$02,$01


	
LAA72:	DEFB $00
LAA73:	DEFB $00
LAA74:	CALL	LAA7E
		LD		A,(IY+$07)
		SUB		C
		JP		LAB0B
LAA7E:	LD		C,$C0
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
		CALL	LA94B
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
		CALL	LB2F8

	;; Return with 0 in A, and carry flag set.
RetZeroC:	XOR	A
		SCF
		RET

FloorCheck:	LD	A,(FloorCode)
		CP	$07 		; No floor?
		JR	NZ,RetZeroC
		LD	(IY+$0A),$22 	; Update this, then.
		JR	RetZeroC

LAB06:		LD	A,(IY+$07)
		SUB	$C0
LAB0B:		LD	BC,L0000
		LD	(LAA72),BC
		JR	Z,FloorThing2
		INC	A
		JR	Z,FloorThing1
		CALL	LB0F9
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
		CALL	LACD3
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
LAB64:	LD		HL,LAF80
LAB67:	LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		OR		H
		JR		Z,LABA6
		PUSH	HL
		POP		IX
		BIT		7,(IX+$04)
		JR		NZ,LAB67
		LD		A,(IX+$07)
		SUB		$06
		EXX
		CP		B
		JR		NZ,LAB90
		EXX
		PUSH	HL
		CALL	LACD3
		POP		HL
		JR		NC,LAB67
LAB88:	LD		(IY+$0D),L
		LD		(IY+$0E),H
		JR		LAB3F
LAB90:	CP		C
		EXX
		JR		NZ,LAB67
		LD		A,(LAA73)
		AND		A
		JR		NZ,LAB67
		PUSH	HL
		CALL	LACD3
		POP		HL
		JR		NC,LAB67
		LD		(LAA72),HL
		JR		LAB67
LABA6:	LD		A,(LA2BC)
		AND		A
		JR		Z,LABE7
		CALL	LACAF
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
		CALL	LACD3
		POP		HL
		JR		NC,LABE7
		JR		LAB88
LABCB:	CP		C
		EXX
		JR		NZ,LABE7
		LD		A,(LAA73)
		AND		A
		JR		NZ,LABE7
		CALL	LACAF
		CALL	LACD3
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
LAC12:	CALL	LB0F9
		LD		A,B
		ADD		A,$06
		LD		B,A
		INC		A
		LD		C,A
		EXX
		LD		HL,LAF80
LAC1F:	LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		OR		H
		RET		Z
		PUSH	HL
		POP		IX
		BIT		6,(IX+$04)
		JR		Z,LAC1F
		LD		A,(IX+$07)
		EXX
		CP		B
		JR		Z,LAC36
		CP		C
LAC36:	EXX
		JR		NZ,LAC1F
		PUSH	HL
		CALL	LACD3
		POP		HL
		JR		NC,LAC1F
		RET
LAC41:	CALL	LB0F9
		LD		B,C
		DEC		B
		EXX
		XOR		A
		LD		(LAA72),A
		LD		HL,LAF80
LAC4E:	LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		OR		H
		JR		Z,LAC97
		PUSH	HL
		POP		IX
		BIT		7,(IX+$04)
		JR		NZ,LAC4E
		LD		A,(IX+$07)
		EXX
		CP		C
		JR		NZ,LAC7F
		EXX
		PUSH	HL
		CALL	LACD3
		POP		HL
		JR		NC,LAC4E
LAC6D:	LD		A,(IY+$0B)
		OR		$E0
		AND		$EF
		LD		C,A
		LD		A,(IX+$0C)
		AND		C
		LD		(IX+$0C),A
		JP		LAB5F
LAC7F:	CP		B
		EXX
		JR		NZ,LAC4E
		LD		A,(LAA72)
		AND		A
		JR		NZ,LAC4E
		PUSH	HL
		CALL	LACD3
		POP		HL
		JR		NC,LAC4E
		LD		A,$FF
		LD		(LAA72),A
		JR		LAC4E
LAC97:	LD		A,(LA2BC)
		AND		A
		JR		Z,LACCC
		CALL	LACAF
		LD		A,(IX+$07)
		EXX
		CP		C
		JR		NZ,LACB6
		EXX
		CALL	LACD3
		JR		NC,LACCC
		JR		LAC6D
LACAF:	CALL	LA94B
		PUSH	HL
		POP		IX
		RET
LACB6:	CP		B
		EXX
		JR		NZ,LACCC
		LD		A,(LAA72)
		AND		A
		JR		NZ,LACCC
		CALL	LACAF
		CALL	LACD3
		JR		NC,LACCC
		LD		A,$FF
		JR		LACCF
LACCC:	LD		A,(LAA72)
LACCF:	AND		A
		RET		Z
		SCF
		RET
LACD3:	CALL	LACE6
LACD6:	LD		A,E
		EXX
		CP		D
		LD		A,E
		EXX
		RET		NC
		CP		D
		RET		NC
		LD		A,L
		EXX
		CP		H
		LD		A,L
		EXX
		RET		NC
		CP		H
		RET
LACE6:	LD		A,(IX+$04)
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
LAD26:	LD		BC,(L703B)
		LD		HL,LAD4C
		CALL	LAD35
		LD		(L703B),DE
		RET
LAD35:	CALL	LAD42
		JR		Z,LAD42
		PUSH	DE
		CALL	LAD42
		POP		DE
		JR		NZ,LAD35
		RET
LAD42:	LD		A,C
		LD		E,(HL)
		INC		HL
		LD		D,(HL)
		INC		HL
		CP		E
		RET		NZ
		LD		A,B
		CP		D
		RET
LAD4C:	DEFB $40,$8A,$50,$71,$40,$89,$80,$04,$70,$BA,$00,$13,$00,$41,$80,$29
LAD5C:	DEFB $00,$A1,$00,$26,$00,$81,$80,$E9,$00,$84,$00,$B1,$00,$85,$20,$EF
LAD6C:	DEFB $00,$A4,$F0,$00,$00,$A5,$D0,$88,$D0,$BC,$D0,$DE,$B0,$2D,$D0,$8B
LAD7C:	DEFB $90,$11,$C0,$E1,$B0,$00,$C0,$E2,$B0,$10,$00,$C1,$F0,$8B,$F0,$00
LAD8C:	DEFB $30,$97,$20,$EF,$00,$1D,$00,$A8,$70,$BA,$00,$4E,$00,$88,$30,$1B
LAD9C:	DEFB $00,$4C,$30,$39,$30,$8B,$30,$8D

SpriteWidth:	DEFB $04	; Width of sprite in bytes.

	;; Current sprite we're drawing.
SpriteCode:	DEFB $00

RevTable:	EQU $B900
	
	;; Initialise a look-up table of byte reverses.
InitRevTbl:	LD	HL,RevTable
RevLoop_1:	LD	C,L
		LD	A,$01
		AND	A
RevLoop_2:	RRA
		RL	C
		JR	NZ,RevLoop_2
		LD	(HL),A
		INC	L
		JR	NZ,RevLoop_1
		RET

LADB7:		LD	(SpriteCode),A
		AND	$7F
		CP	$10
		JR	C,LADF4
		LD	DE,L0606
		LD	H,$12
		CP	$54
		JR	C,LADCE
		LD	DE,L0808
		LD	H,$14
LADCE:	CP		$18
		JR	NC,LADE1
		LD	A,(SpriteFlags)
		AND	$02
		LD	D,$04
		LD	H,$0C
		JR	Z,LADE1
		LD	D,$00
		LD	H,$10
LADE1:	LD		A,B
		ADD	A,D
		LD	L,A
		SUB	D
		SUB	H
		LD	H,A
		LD	A,C
		ADD	A,E
		LD	C,A
		SUB	E
		SUB	E
		LD	B,A
		LD	A,E
		AND	A
		RRA
		LD	(SpriteWidth),A
		RET
LADF4:	LD		HL,(BigSpriteThing+1)
		INC	HL
		INC	HL
		BIT	5,(HL)
		EX	AF,AF'
		LD	A,(HL)
		SUB	$10
		CP	$20
		LD	L,$04
		JR	NC,LAE07
		LD	L,$08
LAE07:	LD		A,B
		ADD	A,L
		LD	L,A
		SUB	$38
		LD	H,A
		EX	AF,AF'
		LD	A,C
		LD	B,$08
		JR	NZ,LAE15
		LD	B,$04
LAE15:	ADD		A,B
		LD	C,A
		SUB	$0C
		LD	B,A
		LD	A,$03
		LD	(SpriteWidth),A
		RET


#include "get_sprite.asm"
	
BigSpriteFlipped:	DEFB $00
LAF5B:	DEFB $1B		; Reinitialisation size

	DEFB $00
	DEFW LBA40
	DEFW LAF7E
	DEFW LAF80
	DEFW $0000
	DEFW $0000
	DEFW $0000,$0000
	DEFW $0000,$0000
	DEFW $0000,$0000
	DEFW $0000,$0000

LAF77:	DEFB $00
LAF78:	DEFW LBA40
LAF7A:	DEFW LAF7E
LAF7C:	DEFW LAF80
LAF7E:	DEFW $0000
LAF80:	DEFW $0000
LAF82:	DEFW $0000,$0000
LAF86:	DEFW $0000,$0000
LAF8A:	DEFW $0000,$0000
LAF8E:	DEFW $0000,$0000
	
LAF92:	DEFW LBA40
LAF94:	DEFW $0000
	
LAF96:		LD		(LAF77),A
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

LAFAB:	LD		HL,L0012
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
LAFC6:	PUSH	HL
		PUSH	BC
		INC		HL
		INC		HL
		CALL	LA1BD
		POP		BC
		POP		HL
		RET		NC
		LD		DE,(LAF78)
		PUSH	DE
		LDIR
		LD		(LAF78),DE
		POP		HL
		PUSH	HL
		POP		IY
		BIT		3,(IY+$04)
		JR		Z,LB010
		LD		BC,L0009
		PUSH	HL
		LDIR
		EX		DE,HL
		LD		A,(DE)
		OR		$02
		LD		(HL),A
		INC		HL
		LD		(HL),$00
		LD		DE,L0008
		ADD		HL,DE
		LD		(LAF78),HL
		BIT		5,(IY+$09)
		JR		Z,LB00F
		PUSH	IY
		LD		DE,L0012
		ADD		IY,DE
		LD		A,(L822E)
		CALL	L828B
		POP		IY
LB00F:	POP		HL
LB010:	LD		A,(LAF77)
		DEC		A
		CP		$02
		JR		NC,LB03B
		INC		HL
		INC		HL
		BIT		3,(IY+$04)
		JR		Z,LB034
		PUSH	HL
		CALL	LB034
		POP		DE
		CALL	LAFAB
		PUSH	HL
		CALL	LB106
		EXX
		PUSH	IY
		POP		HL
		INC		HL
		INC		HL
		JR		LB085
LB034:	PUSH	HL
		CALL	LB106
		EXX
		JR		LB082
LB03B:	INC		HL
		INC		HL
		BIT		3,(IY+$04)
		JR		Z,LB057
		PUSH	HL
		CALL	LB057
		POP		DE
		CALL	LAFAB
		PUSH	HL
		CALL	LB106
		EXX
		PUSH	IY
		POP		HL
		INC		HL
		INC		HL
		JR		LB085
LB057:	PUSH	HL
		CALL	LB106
		LD		A,$03
		EX		AF,AF'
		LD		A,(L771A)
		CP		D
		JR		C,LB07D
		LD		A,(L771B)
		CP		H
		JR		C,LB07D
		LD		A,$04
		EX		AF,AF'
		LD		A,(L7718)
		DEC		A
		CP		E
		JR		NC,LB07D
		LD		A,(L7719)
		DEC		A
		CP		L
		JR		NC,LB07D
		XOR		A
		EX		AF,AF'
LB07D:	EXX
		EX		AF,AF'
		CALL	LAF96
LB082:	LD		HL,(LAF7A)
LB085:	LD		(LAF94),HL
LB088:	LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		OR		H
		JR		Z,LB09C
		PUSH	HL
		CALL	LB106
		CALL	LB17A
		POP		HL
		JR		NC,LB085
		AND		A
		JR		NZ,LB088
LB09C:	LD		HL,(LAF94)
		POP		DE
		LD		A,(HL)
		LDI
		LD		C,A
		LD		A,(HL)
		LD		(DE),A
		DEC		DE
		LD		(HL),D
		DEC		HL
		LD		(HL),E
		LD		L,C
		LD		H,A
		OR		C
		JR		NZ,LB0B4
		LD		HL,(LAF7C)
		INC		HL
		INC		HL
LB0B4:	DEC		HL
		DEC		DE
		LDD
		LD		A,(HL)
		LD		(DE),A
		LD		(HL),E
		INC		HL
		LD		(HL),D
		RET
LB0BE:	PUSH	HL
		CALL	LB0C6
		POP		HL
		JP		LB03B
LB0C6:	BIT		3,(IY+$04)
		JR		Z,LB0D5
		PUSH	HL
		CALL	LB0D5
		POP		DE
		LD		HL,L0012
		ADD		HL,DE
LB0D5:	LD		E,(HL)
		INC		HL
		LD		D,(HL)
		INC		HL
		PUSH	DE
		LD		A,D
		OR		E
		INC		DE
		INC		DE
		JR		NZ,LB0E4
		LD		DE,(LAF7A)
LB0E4:	LD		A,(HL)
		LDI
		LD		C,A
		LD		A,(HL)
		LD		(DE),A
		LD		H,A
		LD		L,C
		OR		C
		DEC		HL
		JR		NZ,LB0F4
		LD		HL,(LAF7C)
		INC		HL
LB0F4:	POP		DE
		LD		(HL),D
		DEC		HL
		LD		(HL),E
		RET
LB0F9:	CALL	LB104
		AND		$08
		RET		Z
		LD		A,C
		SUB		$06
		LD		C,A
		RET
LB104:	INC		HL
		INC		HL
LB106:	INC		HL
		INC		HL
		LD		A,(HL)
		INC		HL
		LD		C,A
		EX		AF,AF'
		LD		A,C
		BIT		2,A
		JR		NZ,LB153
		BIT		1,A
		JR		NZ,LB12F
		AND		$01
		ADD		A,$03
		LD		B,A
		ADD		A,A
		LD		C,A
		LD		A,(HL)
		ADD		A,B
		LD		D,A
		SUB		C
		LD		E,A
		INC		HL
		LD		A,(HL)
		INC		HL
		ADD		A,B
		LD		B,(HL)
		LD		H,A
		SUB		C
		LD		L,A
LB129:	LD		A,B
		SUB		$06
		LD		C,A
		EX		AF,AF'
		RET
LB12F:	RRA
		JR		C,LB143
		LD		A,(HL)
		ADD		A,$04
		LD		D,A
		SUB		$08
		LD		E,A
		INC		HL
		LD		A,(HL)
		INC		HL
		LD		B,(HL)
		LD		H,A
		LD		L,A
		INC		H
		DEC		L
		JR		LB129
LB143:	LD		D,(HL)
		LD		E,D
		INC		D
		DEC		E
		INC		HL
		LD		A,(HL)
		INC		HL
		ADD		A,$04
		LD		B,(HL)
		LD		H,A
		SUB		$08
		LD		L,A
		JR		LB129
LB153:	LD		A,(HL)
		RR		C
		JR		C,LB15E
		LD		E,A
		ADD		A,$04
		LD		D,A
		JR		LB162
LB15E:	LD		D,A
		SUB		$04
		LD		E,A
LB162:	INC		HL
		LD		A,(HL)
		INC		HL
		LD		B,(HL)
		RR		C
		JR		C,LB170
		LD		L,A
		ADD		A,$04
		LD		H,A
		JR		LB174
LB170:	LD		H,A
		SUB		$04
		LD		L,A
LB174:	LD		A,B
		SUB		$12
		LD		C,A
		EX		AF,AF'
		RET
LB17A:	LD		A,L
		EXX
		CP		H
		LD		A,L
		EXX
		JR		NC,LB184
		CP		H
		JR		C,LB1BB
LB184:	LD		A,E
		EXX
		CP		D
		LD		A,E
		EXX
		JR		NC,LB18E
		CP		D
		JR		C,LB1F2
LB18E:	LD		A,C
		EXX
		CP		B
		LD		A,C
		EXX
		JR		NC,LB198
		CP		B
		JR		C,LB1AF
LB198:	LD		A,L
		ADD		A,E
		ADD		A,C
		LD		L,A
		ADC		A,$00
		SUB		L
		LD		H,A
		EXX
		LD		A,L
		ADD		A,E
		ADD		A,C
		EXX
		LD		E,A
		ADC		A,$00
		SUB		E
		LD		D,A
		SBC		HL,DE
		LD		A,$FF
		RET
LB1AF:	LD		A,L
		ADD		A,E
		LD		L,A
		EXX
		LD		A,L
		ADD		A,E
		EXX
		CP		L
		CCF
		LD		A,$FF
		RET
LB1BB:	LD		A,E
		EXX
		CP		D
		LD		A,E
		EXX
		JR		NC,LB1C5
		CP		D
		JR		C,LB1EB
LB1C5:	LD		A,C
		EXX
		CP		B
		LD		A,C
		EXX
		JR		NC,LB1CF
		CP		B
		JR		C,LB1E4
LB1CF:	EXX
		ADD		A,E
		EXX
		LD		L,A
		ADC		A,$00
		SUB		L
		LD		H,A
		LD		A,C
		ADD		A,E
		LD		E,A
		ADC		A,$00
		SUB		E
		LD		D,A
		SBC		HL,DE
		CCF
		LD		A,$FF
		RET
LB1E4:	LD		A,E
		EXX
		CP		E
		EXX
		LD		A,$00
		RET
LB1EB:	LD		A,C
		EXX
		CP		C
		EXX
		LD		A,$00
		RET
LB1F2:	LD		A,C
		EXX
		CP		B
		LD		A,C
		EXX
		JR		NC,LB1FC
		CP		B
		JR		C,LB210
LB1FC:	EXX
		ADD		A,L
		EXX
		LD		E,A
		ADC		A,$00
		SUB		E
		LD		D,A
		LD		A,C
		ADD		A,L
		LD		L,A
		ADC		A,$00
		SUB		L
		LD		H,A
		SBC		HL,DE
		LD		A,$FF
		RET
LB210:	LD		A,L
		EXX
		CP		L
		EXX
		LD		A,$00
		RET
LB217:	DEFB $00
LB218:	DEFB $00
LB219:	DEFB $00
LB21A:	DEFB $00
LB21B:	DEFB $00
LB21C:	PUSH	AF
		CALL	LB0F9
		EXX
		POP		AF
		LD		(LB21B),A
LB225:	CALL	LB22C
		LD		A,(LB21B)
		RET
LB22C:	LD		DE,LB24B
		PUSH	DE
		LD		C,A
		ADD		A,A
		ADD		A,A
		ADD		A,C
		ADD		A,$77
		LD		L,A
		ADC		A,$B3
		SUB		L
		LD		H,A
		LD		A,(HL)
		LD		(LB217),A
		INC		HL
		LD		E,(HL)
		INC		HL
		LD		D,(HL)
		INC		HL
		LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		PUSH	DE
		EXX
		RET
LB24B:	DEFB $D9,$C8,$E5,$DD,$E1,$CB,$51,$20,$15,$21,$7E,$AF,$7E,$23,$66,$6F
LB25B:	DEFB $B4,$28,$24,$E5,$CD,$F4,$9D,$E1,$38,$3B,$20,$F0,$18,$19,$21,$80
LB26B:	DEFB $AF,$7E,$23,$66,$6F,$B4,$28,$09,$E5,$CD,$F4,$9D,$E1,$38,$28,$20
LB27B:	DEFB $F0,$CD,$4B,$A9,$5D,$18,$06,$CD,$4B,$A9,$5D,$23,$23,$FD,$CB,$09
LB28B:	DEFB $46,$28,$04,$FD,$7D,$BB,$C8,$3A,$BC,$A2,$A7,$C8,$CD,$F4,$9D,$D0
LB29B:	DEFB $CD,$4B,$A9,$23,$23,$2B,$2B,$E5,$DD,$E1,$3A,$17,$B2,$DD,$CB,$09
LB2AB:	DEFB $4E,$28,$08,$DD,$A6,$FA,$DD,$77,$FA,$18,$06,$DD,$A6,$0C,$DD,$77
LB2BB:	DEFB $0C,$AF,$D6,$01
LB2BF:	PUSH	AF
		PUSH	IX
		PUSH	IY
		CALL	LB2CD
		POP		IY
		POP		IX
		POP		AF
		RET
LB2CD:	BIT		0,(IY+$09)
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
		JR		Z,LB2F8
		BIT		4,(IX+$09)
		RET		NZ
LB2F8:		BIT		3,B
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
		LD		A,(L866B)
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
LB377:	DEFB $FD,$BE,$B4,$84,$B4,$FF,$9F,$B3,$00,$00,$FB,$15,$B5,$A2,$B4,$FF
LB387:	DEFB $C0,$B3,$00,$00,$FE,$65,$B5,$28,$B4,$FF,$E4,$B3,$00,$00,$F7,$AD
LB397:	DEFB $B5,$69,$B4,$FF,$07,$B4,$00,$00
LB39F:	EXX
		POP		HL
		POP		DE
		XOR		A
		CALL	LB225
		JR		C,LB3B6
		EXX
		DEC		D
		DEC		E
		EXX
		LD		A,$02
		CALL	LB225
		LD		A,$01
		RET		NC
		XOR		A
		RET
LB3B6:	LD		A,$02
		CALL	LB225
		RET		C
		AND		A
		LD		A,$02
		RET
LB3C0:	EXX
		POP		HL
		POP		DE
		LD		A,$04
		CALL	LB225
		JR		C,LB3DA
		EXX
		INC		D
		INC		E
		EXX
		LD		A,$02
		CALL	LB225
		LD		A,$03
		RET		NC
		LD		A,$04
		AND		A
		RET
LB3DA:	LD		A,$02
		CALL	LB225
		RET		C
		AND		A
		LD		A,$02
		RET
LB3E4:	EXX
		POP		HL
		POP		DE
		LD		A,$04
		CALL	LB225
		JR		C,LB3FE
		EXX
		INC		D
		INC		E
		EXX
		LD		A,$06
		CALL	LB225
		LD		A,$05
		RET		NC
		LD		A,$04
		AND		A
		RET
LB3FE:	LD		A,$06
		CALL	LB225
		RET		C
		LD		A,$06
		RET
LB407:	EXX
		POP		HL
		POP		DE
		XOR		A
		CALL	LB225
		JR		C,LB41E
		EXX
		DEC		D
		DEC		E
		EXX
		LD		A,$06
		CALL	LB225
		LD		A,$07
		RET		NC
		XOR		A
		RET
LB41E:	LD		A,$06
		CALL	LB225
		RET		C
		AND		A
		LD		A,$06
		RET
LB428:	INC		HL
		INC		HL
		CALL	LB650
		LD		A,(HL)
		SUB		C
		EXX
		CP		D
		EXX
		JR		C,LB465
		JR		NZ,LB453
		INC		HL
LB437:	LD		A,(HL)
		SUB		B
		EXX
		CP		H
		LD		A,L
		EXX
		JR		NC,LB465
		SUB		B
		CP		(HL)
		JR		NC,LB465
LB443:	INC		HL
		EXX
		LD		A,C
		EXX
		CP		(HL)
		JR		NC,LB465
		LD		A,(HL)
		SUB		E
		EXX
		CP		B
		EXX
		JR		NC,LB465
		SCF
		RET
LB453:	INC		HL
		LD		A,(HL)
		SUB		B
		EXX
		CP		H
		EXX
		JR		C,LB465
		INC		HL
		LD		A,(HL)
		SUB		E
		EXX
		CP		B
		EXX
		JR		C,LB465
		XOR		A
		RET
LB465:	LD		A,$FF
		AND		A
		RET
LB469:	INC		HL
		INC		HL
		CALL	LB650
		LD		A,(HL)
		SUB		C
		EXX
		CP		D
		LD		A,E
		EXX
		JR		NC,LB453
		SUB		C
		CP		(HL)
		JR		NC,LB465
		INC		HL
		LD		A,(HL)
		SUB		B
		EXX
		CP		H
		EXX
		JR		Z,LB443
		JR		LB465
LB484:	CALL	LB650
		EXX
		LD		A,E
		EXX
		SUB		C
		CP		(HL)
		JR		C,LB465
		INC		HL
		JR		Z,LB437
LB491:	EXX
		LD		A,L
		EXX
		SUB		B
		CP		(HL)
		JR		C,LB465
		INC		HL
		LD		A,(HL)
		ADD		A,E
		EXX
		CP		B
		EXX
		JR		NC,LB465
		XOR		A
		RET
LB4A2:	CALL	LB650
		EXX
		LD		A,E
		EXX
		SUB		C
		CP		(HL)
		INC		HL
		JR		NC,LB491
		DEC		HL
		LD		A,(HL)
		SUB		C
		EXX
		CP		D
		LD		A,L
		EXX
		JR		NC,LB465
		INC		HL
		SUB		B
		CP		(HL)
		JP		Z,LB443
		JR		LB465
LB4BE:	CALL	LB63D
		JR		Z,LB4F6
		CALL	LB5F5
		LD		A,$24
		JR		C,LB4F9
		BIT		0,(IX-$01)
		JR		Z,LB4E4
		LD		A,(L7747)
		CALL	LB629
		JR		C,LB4F6
		CALL	LB619
		JR		C,LB4FD
		LD		A,(L7718)
		SUB		$04
		JR		LB4ED
LB4E4:	BIT		0,(IX-$02)
		JR		Z,LB4F6
		LD		A,(L7718)
LB4ED:	CP		E
		RET		NZ
		LD		A,$01
LB4F1:	LD		(LB218),A
		SCF
		RET
LB4F6:	LD		A,(L7718)
LB4F9:	CP		E
		RET		NZ
		SCF
		RET
LB4FD:	CALL	LB621
		JR		C,LB4F6
		CALL	LB4F6
LB505:	RET		NZ
		LD		A,L
		CP		$25
		LD		A,$F7
		JR		C,LB50F
		LD		A,$FB
LB50F:	LD		(LA2BF),A
		XOR		A
		SCF
		RET
LB515:	CALL	LB63D
		JR		Z,LB54A
		CALL	LB5FF
		LD		A,$24
		JR		C,LB54D
		BIT		1,(IX-$01)
		JR		Z,LB53B
		LD		A,(L7746)
		CALL	LB629
		JR		C,LB54A
		CALL	LB609
		JR		C,LB551
		LD		A,(L7719)
		SUB		$04
		JR		LB544
LB53B:	BIT		1,(IX-$02)
		JR		Z,LB54A
		LD		A,(L7719)
LB544:	CP		L
		RET		NZ
		LD		A,$02
		JR		LB4F1
LB54A:	LD		A,(L7719)
LB54D:	CP		L
		RET		NZ
		SCF
		RET
LB551:	CALL	LB611
		JR		C,LB54A
		CALL	LB54A
LB559:	RET		NZ
		LD		A,E
		CP		$25
		LD		A,$FE
		JR		C,LB50F
		LD		A,$FD
		JR		LB50F
LB565:	CALL	LB63D
		JR		Z,LB59B
		CALL	LB5F5
		LD		A,$2C
		JR		C,LB59E
		BIT		2,(IX-$01)
		JR		Z,LB58B
		LD		A,(L7745)
		CALL	LB629
		JR		C,LB59B
		CALL	LB619
		JR		C,LB5A2
		LD		A,(L771A)
		ADD		A,$04
		JR		LB594
LB58B:	BIT		2,(IX-$02)
		JR		Z,LB59B
		LD		A,(L771A)
LB594:	CP		D
		RET		NZ
		LD		A,$03
		JP		LB4F1
LB59B:	LD		A,(L771A)
LB59E:	CP		D
		RET		NZ
		SCF
		RET
LB5A2:	CALL	LB621
		JR		C,LB59B
		CALL	LB59B
		JP		LB505
LB5AD:	CALL	LB63D
		JR		Z,LB5E3
		CALL	LB5FF
		LD		A,$2C
		JR		C,LB5E6
		BIT		3,(IX-$01)
		JR		Z,LB5D3
		LD		A,(L7744)
		CALL	LB629
		JR		C,LB5E3
		CALL	LB609
		JR		C,LB5EA
		LD		A,(L771B)
		ADD		A,$04
		JR		LB5DC
LB5D3:	BIT		3,(IX-$02)
		JR		Z,LB5E3
		LD		A,(L771B)
LB5DC:	CP		H
		RET		NZ
		LD		A,$04
		JP		LB4F1
LB5E3:	LD		A,(L771B)
LB5E6:	CP		H
		RET		NZ
		SCF
		RET
LB5EA:	CALL	LB611
		JR		C,LB5E3
		CALL	LB5E3
		JP		LB559
LB5F5:	LD		A,(L771B)
		CP		H
		RET		C
		LD		A,L
		CP		A,(IX+$01)
		RET
LB5FF:	LD		A,(L771A)
		CP		D
		RET		C
		LD		A,E
		CP		A,(IX+$00)
		RET
LB609:	LD		A,$2C
		CP		D
		RET		C
		LD		A,E
		CP		$24
		RET
LB611:	LD		A,$30
		CP		D
		RET		C
		LD		A,E
		CP		$20
		RET
LB619:	LD		A,$2C
		CP		H
		RET		C
		LD		A,L
		CP		$24
		RET
LB621:	LD		A,$30
		CP		H
		RET		C
		LD		A,L
		CP		$20
		RET
LB629:	SUB		B
		RET		C
		PUSH	AF
		LD		A,(Character)
		CP		$03
		JR		NZ,LB638
		POP		AF
		CP		$03
		CCF
		RET
LB638:	POP		AF
		CP		$09
		CCF
		RET
LB63D:	LD		IX,L7718
		BIT		0,(IY+$09)
		RET		Z
		LD		A,(IY+$0A)
		AND		$7F
		SUB		$01
		RET		C
		XOR		A
		RET
LB650:	INC		HL
		INC		HL
		LD		A,(HL)
		INC		HL
		LD		E,$06
		BIT		1,A
		JR		NZ,LB662
		RRA
		LD		A,$03
		ADC		A,$00
		LD		B,A
		LD		C,A
		RET
LB662:	RRA
		JR		C,LB669
		LD		BC,L0104
		RET
LB669:		LD		BC,L0401
		RET
	
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
