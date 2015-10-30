	;; 
	;; status.asm
	;;
	;; Counts for lives etc.
	;; 

BoostDonuts:	LD	A,(Character)
		AND	$02
		RET	Z		; Must be Head
		LD	A,CNT_DONUTS
		CALL	BoostCountPlus
		LD	A,$02		; Pick up donuts
		JR	PickUp
	
BoostSpeed:	LD	A,(Character)
		AND	$02		; Must be Head
		RET	Z
		XOR	A		; Sets to CNT_SPEED
		JR	BoostCountPlus
	
BoostSpring:	LD	A,(Character)
		AND	$01		; Must be Heels
		RET	Z
		JR	BoostCountPlus  ; $01 = CNT_SPRING

BoostInvuln:	LD	IX,L8763
		LD	C,CNT_HEELS_INVULN
		JR	BoostMaybeDbl
BoostLives:	LD	C,CNT_HEELS_LIVES
BoostMaybeDbl:	LD	A,(Character)
		CP	$03		; Head and Heels?
		JR	Z,BoostCountDbl	; Then increment both
		RRA
		AND	$01		; If Head, add 1
		ADD	A,C
		JR	BoostCountPlus
	
	;; Boosts two subsequent counts. For use when Head and Heels are joined.
BoostCountDbl:	LD	A,C
		PUSH	AF
		CALL	BoostCount
		POP	AF
		INC	A
	;; NB: Fall through

	;; FIXME: Does some other thing before boosting the count.
BoostCountPlus:	PUSH	AF
		CALL	DoCopy	; FIXME: Calls (IX). Is that right?
		POP	AF
	;; NB: Fall through

	;; Boosts whichever count index is provided in A, and displays it.
BoostCount:	CALL	GetCountAddr
		CALL	AddBCD
	;; NB: Fall through

	;; Number to print in A, location in C.
ShowNum:	PUSH	AF
		PUSH	BC
		AND	A
		LD	A,CTRL_ATTR1 		; When printing 0
		JR	Z,SN_1
		LD	A,CTRL_ATTR3 		; Otherwise
SN_1:		CALL	PrintChar
		POP	BC
		LD	A,C
		ADD	A,CTRL_POS_LIGHTNING 	; Position indexed into array...
		CALL	PrintChar
		POP	AF
		JP	Print2DigitsR

	;; FIXME: Decode!
	;; NB: Not directly called from any code I've seen!
EndThing:	LD	A,D
		SUB	$09
		LD	HL,L866B
		CALL	SetBit
		LD	B,$C1
		CALL	PlaySound
		JP	EndScreen		; FIXME: Tail call to end screen thing

	;; FIXME: Decode!
	;; NB: Not directly called from any code I've seen!
SaveContinue:	LD	B,$C2
		CALL	PlaySound
		CALL	GetContinueData
		LD	IX,L866C
		LD	DE,L0004
		LD	B,$06
SC_1:		LD	(HL),$80
SC_2:		LD	A,(IX+$00)
		ADD	IX,DE
		RRA
		RR	(HL)
		JR	NC,SC_2
		INC	HL
		DJNZ	SC_1
		EX	DE,HL
		LD	HL,Continues
		INC	(HL)
		LD	HL,Character
		LD	A,(HL)
		LDI
		LD	HL,Lives
		LDI
		LDI
		CP	$03
		JR	Z,SC_3
		LD	HL,LA2A6
		CP	(HL)
		JR	NZ,SC_3
		LD	HL,LFB49
		LD	BC,L0004
		LDIR
		LD	HL,LFB28
		JR	SC_4
SC_3:		LD	HL,LA2A2
		LD	BC,L0004
		LDIR
		LD	HL,L703B
SC_4:		LDI
		LDI
		LD	HL,L703B
		LDI
		LDI
		RET

	;; FIXME: Decode!
DoContinue:	LD	HL,Continues
		DEC	(HL)
		CALL	GetContinueData
		LD	A,(HL)
		AND	$03
		LD	(Inventory),A
		LD	A,(HL)
		RRA
		RRA
		AND	$1F
		LD	(L866B),A
		PUSH	HL
		POP	IX
		LD	HL,L866C
		LD	DE,L0004
		LD	B,$2F
		RR	(HL)
		JR	DC_2
DC_1:		RR	(HL)
		SRL	(IX+$00)
		JR	NZ,DC_3
		INC	IX
DC_2:		SCF
		RR	(IX+$00)
DC_3:		RL	(HL)
		ADD	HL,DE
		DJNZ	DC_1
		PUSH	IX
		POP	HL
		INC	HL
		LD	DE,Character
		LD	A,(HL)
		LDI
		LD	DE,Lives
		LDI
		LDI
		LD	DE,LB218
		LDI
		BIT	0,A
		LD	DE,LA2C5
		JR	Z,DC_4
		LD	DE,LA2D7
DC_4:		LD	BC,L0003
		LDIR
		LD	DE,L703B
		LDI
		LDI
		CP	$03
		JR	Z,DC_5
		LD	BC,(Lives)
		DEC	B
		JP	M,DC_5
		DEC	C
		JP	M,DC_5
		XOR	$03
		LD	(LFB28),A
		PUSH	HL
		CALL	C7B43
		POP	HL
DC_5:		LD	DE,L703B
		LDI
		LDI
		LD	BC,(L703B)
		SET	0,C
		CALL	C874F
		CALL	C8764
		LD	A,E
		EX	AF,AF'
		LD	DE,L8ADF
		LD	HL,L8ADC
		CALL	C7ACB
		LD	A,$08
		LD	(LB218),A
		LD	(LA297),A
		RET

	;; Returns a pointer to the slot for continue data in HL.
GetContinueData:LD	A,(Continues)
		LD	B,A
		INC	B
		LD	HL,ContinueData - $12
		LD	DE,L0012
GCD_1:		ADD	HL,DE
		DJNZ	GCD_1
		RET

	;; Set bit A of (HL)
SetBit:		LD	B,A
		INC	B
		LD	A,$80
SB_1:		RLCA
		DJNZ	SB_1
		OR	(HL)
		LD	(HL),A
		RET

	;; Decrement one of the core counters and re-display it.
DecCount:	CALL	GetCountAddr
		CALL	DecrementBCD
		RET	Z
		LD	A,(HL)
		CALL	ShowNum
		OR	$FF
		RET

	;; Re-prints all the status info.
PrintStatus:	LD	A,STR_GAME_SYMBOLS
		CALL	PrintChar
		LD	A,$07
PrS_1:		PUSH	AF
		DEC	A
		CALL	GetCountAddr
		LD	A,(HL)
		CALL	ShowNum
		POP	AF
		DEC	A
		JR	NZ,PrS_1
		RET

	;; Add A onto (HL), BCD-fashion, capped at 99.
AddBCD:		ADD	A,(HL)
		DAA
		LD	(HL),A
		RET	NC
		LD	A,$99
		LD	(HL),A
		RET

	;; Decrement contents of HL, BCD-fashion, unless we've hit zero already.
DecrementBCD:	LD	A,(HL)
		AND	A
		RET	Z
		SUB	$01
		DAA
		LD	(HL),A
		OR	$FF
		RET

	;; Given a count index in A, return the pick-up increment in A, and address in HL.
	;; Leaves the count index in C.
	;; Some special case, based on LB218...
GetCountAddr:	LD	C,A
		LD	B,$00
		LD	HL,DefCounts
		ADD	HL,BC
		LD	A,(LB218)
		AND	A
		LD	A,(HL)
		JR	Z,GCA_1
		LD	A,$03
GCA_1:		LD	HL,Speed 	; Points to start of array of counts
		ADD	HL,BC
		RET

	;; Indices for counts of main quantities we hold
CNT_SPEED:		EQU $00
CNT_SPRING:		EQU $01
CNT_HEELS_INVULN:	EQU $02
CNT_HEAD_INVULN:	EQU $03
CNT_HEELS_LIVES:	EQU $04
CNT_HEAD_LIVES:		EQU $05
CNT_DONUTS:		EQU $06

	;; And their values...
DefCounts:	DEFB $99	; Speed
		DEFB $10	; Springs
		DEFB $99	; Heels invuln
		DEFB $99	; Head invuln
		DEFB $02	; Heels lives
		DEFB $02	; Head lives
		DEFB $06	; Donuts

Continues:	DEFB $00

	;; 11 continue slots, it seems
ContinueData:	DEFS 11*$12,$00
