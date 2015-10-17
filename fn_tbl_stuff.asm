	;;
	;; fn_tbl_stuff.asm
	;;
	;; Some mysterious jump table stuff...
	;;
	;; FIXME!
	;;
	;; Only exported value is FnTbl
	;; Only call out is to DoTableCall... which calls right back!

	;; Variables used in this file:
	;; L7718
	;; L7719
	;; L771A
	;; L771B
	;; L7744
	;; L7745
	;; L7746
	;; L7747
	;; LA2BF
	;; LB218
	
FnTbl:		DEFB $FD
		DEFW SomeTableFn0,SomeTableArg0
		DEFB $FF
		DEFW SomeTableFn1,L0000
		DEFB $FB
		DEFW SomeTableFn2,SomeTableArg2
		DEFB $FF
		DEFW SomeTableFn3,L0000
		DEFB $FE
		DEFW SomeTableFn4,SomeTableArg4
		DEFB $FF
		DEFW SomeTableFn5,L0000
		DEFB $F7
		DEFW SomeTableFn6,SomeTableArg6
		DEFB $FF
		DEFW SomeTableFn7,L0000

SomeTableFn1:	EXX
	;; Remove original return path, hit DoTableCall again.
		POP	HL
		POP	DE
        ;; Call Fn0
		XOR	A
		CALL	DoTableCall
		JR	C,STF1_1
		EXX
		DEC	D
		DEC	E
		EXX
        ;; Call Fn2
		LD	A,$02
		CALL	DoTableCall
		LD	A,$01
		RET	NC
		XOR	A
		RET
        ;; Call Fn2
STF1_1:		LD	A,$02
		CALL	DoTableCall
		RET	C
		AND	A
		LD	A,$02
		RET

SomeTableFn3:	EXX
	;; Remove original return path, hit DoTableCall again.
		POP	HL
		POP	DE
        ;; Call Fn4
		LD	A,$04
		CALL	DoTableCall
		JR	C,STF3_1
		EXX
		INC	D
		INC	E
		EXX
        ;; Call Fn2
		LD	A,$02
		CALL	DoTableCall
		LD	A,$03
		RET	NC
		LD	A,$04
		AND	A
		RET
        ;; Call Fn2
STF3_1:		LD	A,$02
		CALL	DoTableCall
		RET	C
		AND	A
		LD	A,$02
		RET

SomeTableFn5:	EXX
	;; Remove original return path, hit DoTableCall again.
		POP	HL
		POP	DE
        ;; Call Fn4
		LD	A,$04
		CALL	DoTableCall
		JR	C,STF5_1
		EXX
		INC	D
		INC	E
		EXX
        ;; Call Fn6
		LD	A,$06
		CALL	DoTableCall
		LD	A,$05
		RET	NC
		LD	A,$04
		AND	A
		RET
        ;; Call Fn6
STF5_1:		LD	A,$06
		CALL	DoTableCall
		RET	C
		LD	A,$06
		RET
	
SomeTableFn7:	EXX
	;; Remove original return path, hit DoTableCall again.
		POP	HL
		POP	DE
        ;; Call Fn0
		XOR	A
		CALL	DoTableCall
		JR	C,STF7_1
		EXX
		DEC	D
		DEC	E
		EXX
        ;; Call Fn6
		LD	A,$06
		CALL	DoTableCall
		LD	A,$07
		RET	NC
		XOR	A
		RET
        ;; Call Fn6
STF7_1:		LD	A,$06
		CALL	DoTableCall
		RET	C
		AND	A
		LD	A,$06
		RET

SomeTableArg4:	INC	HL
		INC	HL
		CALL	TblFnCommon20
		LD	A,(HL)
		SUB	C
		EXX
		CP	D
		EXX
		JR	C,TblArgCommon4
		JR	NZ,TblArgCommon3
		INC	HL
	;; NB: Fall through
	
TblArgCommon1:	LD	A,(HL)
		SUB	B
		EXX
		CP	H
		LD	A,L
		EXX
		JR	NC,TblArgCommon4
		SUB	B
		CP	(HL)
		JR	NC,TblArgCommon4
	;; NB: Fall through
	
TblArgCommon2:	INC	HL
		EXX
		LD	A,C
		EXX
		CP	(HL)
		JR	NC,TblArgCommon4
		LD	A,(HL)
		SUB	E
		EXX
		CP	B
		EXX
		JR	NC,TblArgCommon4
		SCF
		RET
	
TblArgCommon3:	INC	HL
		LD	A,(HL)
		SUB	B
		EXX
		CP	H
		EXX
		JR	C,TblArgCommon4
		INC	HL
		LD	A,(HL)
		SUB	E
		EXX
		CP	B
		EXX
		JR	C,TblArgCommon4
		XOR	A
		RET
	
TblArgCommon4:	LD	A,$FF
		AND	A
		RET

SomeTableArg6:	INC	HL
		INC	HL
		CALL	TblFnCommon20
		LD	A,(HL)
		SUB	C
		EXX
		CP	D
		LD	A,E
		EXX
		JR	NC,TblArgCommon3
		SUB	C
		CP	(HL)
		JR	NC,TblArgCommon4
		INC	HL
		LD	A,(HL)
		SUB	B
		EXX
		CP	H
		EXX
		JR	Z,TblArgCommon2
		JR	TblArgCommon4

SomeTableArg0:	CALL	TblFnCommon20
		EXX
		LD	A,E
		EXX
		SUB	C
		CP	(HL)
		JR	C,TblArgCommon4
		INC	HL
		JR	Z,TblArgCommon1
	;; NB: Fall through
	
TblArgCommon5:	EXX
		LD	A,L
		EXX
		SUB	B
		CP	(HL)
		JR	C,TblArgCommon4
		INC	HL
		LD	A,(HL)
		ADD	A,E
		EXX
		CP	B
		EXX
		JR	NC,TblArgCommon4
		XOR	A
		RET

SomeTableArg2:	CALL	TblFnCommon20
		EXX
		LD	A,E
		EXX
		SUB	C
		CP	(HL)
		INC	HL
		JR	NC,TblArgCommon5
		DEC	HL
		LD	A,(HL)
		SUB	C
		EXX
		CP	D
		LD	A,L
		EXX
		JR	NC,TblArgCommon4
		INC	HL
		SUB	B
		CP	(HL)
		JP	Z,TblArgCommon2
		JR	TblArgCommon4
	
SomeTableFn0:	CALL	TblFnCommon19
		JR	Z,TblFnCommon2
		CALL	TblFnCommon11
		LD	A,$24
		JR	C,TblFnCommon2b
		BIT	0,(IX-$01)
		JR	Z,STF8_1
		LD	A,(L7747)
		CALL	TblFnCommon17
		JR	C,TblFnCommon2
		CALL	TblFnCommon15
		JR	C,TblFnCommon3
		LD	A,(L7718)
		SUB	$04
		JR	STF8_2
STF8_1:		BIT	0,(IX-$02)
		JR	Z,TblFnCommon2
		LD	A,(L7718)
STF8_2:		CP	E
		RET	NZ
		LD	A,$01
	;; NB: Fall through
	
TblFnCommon1:	LD	(LB218),A
		SCF
		RET

TblFnCommon2:	LD	A,(L7718)
TblFnCommon2b:	CP	E
		RET	NZ
		SCF
		RET

TblFnCommon3:	CALL	TblFnCommon16
		JR	C,TblFnCommon2
		CALL	TblFnCommon2
	;; NB: Fall through
	
TblFnCommon4:	RET	NZ
		LD	A,L
		CP	$25
		LD	A,$F7
		JR	C,TblFnCommon5
		LD	A,$FB
	;; NB: Fall through
	
TblFnCommon5:	LD	(LA2BF),A
		XOR	A
		SCF
		RET

SomeTableFn2:	CALL	TblFnCommon19
		JR	Z,TblFnCommon6
		CALL	TblFnCommon12
		LD	A,$24
		JR	C,TblFnCommon6b
		BIT	1,(IX-$01)
		JR	Z,STF2_1
		LD	A,(L7746)
		CALL	TblFnCommon17
		JR	C,TblFnCommon6
		CALL	TblFnCommon13
		JR	C,TblFnCommon7
		LD	A,(L7719)
		SUB	$04
		JR	STF2_2
STF2_1:		BIT	1,(IX-$02)
		JR	Z,TblFnCommon6
		LD	A,(L7719)
STF2_2:		CP	L
		RET	NZ
		LD	A,$02
		JR	TblFnCommon1
	
TblFnCommon6:	LD	A,(L7719)
TblFnCommon6b:	CP	L
		RET	NZ
		SCF
		RET

TblFnCommon7:	CALL	TblFnCommon14
		JR	C,TblFnCommon6
		CALL	TblFnCommon6
	;; NB: Fall through
	
TblFnCommon8:	RET	NZ
		LD	A,E
		CP	$25
		LD	A,$FE
		JR	C,TblFnCommon5
		LD	A,$FD
		JR	TblFnCommon5

SomeTableFn4:	CALL	TblFnCommon19
		JR	Z,STF4_3
		CALL	TblFnCommon11
		LD	A,$2C
		JR	C,STF4_4
		BIT	2,(IX-$01)
		JR	Z,STF4_1
		LD	A,(L7745)
		CALL	TblFnCommon17
		JR	C,STF4_3
		CALL	TblFnCommon15
		JR	C,STF4_5
		LD	A,(L771A)
		ADD	A,$04
		JR	STF4_2
STF4_1:		BIT	2,(IX-$02)
		JR	Z,STF4_3
		LD	A,(L771A)
STF4_2:		CP	D
		RET	NZ
		LD	A,$03
		JP	TblFnCommon1
STF4_3:		LD	A,(L771A)
STF4_4:		CP	D
		RET	NZ
		SCF
		RET
STF4_5:		CALL	TblFnCommon16
		JR	C,STF4_3
		CALL	STF4_3
		JP	TblFnCommon4

SomeTableFn6:	CALL	TblFnCommon19
		JR	Z,TblFnCommon9
		CALL	TblFnCommon12
		LD	A,$2C
		JR	C,TblFnCommon9b
		BIT	3,(IX-$01)
		JR	Z,STF6_1
		LD	A,(L7744)
		CALL	TblFnCommon17
		JR	C,TblFnCommon9
		CALL	TblFnCommon13
		JR	C,TblFnCommon10
		LD	A,(L771B)
		ADD	A,$04
		JR	STF6_2
STF6_1:		BIT	3,(IX-$02)
		JR	Z,TblFnCommon9
		LD	A,(L771B)
STF6_2:		CP	H
		RET	NZ
		LD	A,$04
		JP	TblFnCommon1

TblFnCommon9:	LD	A,(L771B)
TblFnCommon9b:	CP	H
		RET	NZ
		SCF
		RET

TblFnCommon10:	CALL	TblFnCommon14
		JR	C,TblFnCommon9
		CALL	TblFnCommon9
		JP	TblFnCommon8

	;; Unused?
TblFnCommon11:	LD	A,(L771B)
		CP	H
		RET	C
		LD	A,L
		CP	A,(IX+$01)
		RET

TblFnCommon12:	LD	A,(L771A)
		CP	D
		RET	C
		LD	A,E
		CP	A,(IX+$00)
		RET

TblFnCommon13:	LD	A,$2C
		CP	D
		RET	C
		LD	A,E
		CP	$24
		RET

TblFnCommon14:	LD	A,$30
		CP	D
		RET	C
		LD	A,E
		CP	$20
		RET

TblFnCommon15:	LD	A,$2C
		CP	H
		RET	C
		LD	A,L
		CP	$24
		RET

TblFnCommon16:	LD	A,$30
		CP	H
		RET	C
		LD	A,L
		CP	$20
		RET

	;; Checks to see if A is between B and B + 3 / 9
	;; (depending on if you're both head and heels currently)
TblFnCommon17:	SUB	B
		RET	C
		PUSH	AF
		LD	A,(Character)
		CP	$03
		JR	NZ,TFC17_1
		POP	AF
		CP	$03
		CCF
		RET
TFC17_1:	POP	AF
		CP	$09
		CCF
		RET

TblFnCommon19:	LD	IX,L7718
		BIT	0,(IY+$09)
		RET	Z
		LD	A,(IY+$0A)
		AND	$7F
		SUB	$01
		RET	C
		XOR	A
		RET

TblFnCommon20:	INC	HL
		INC	HL
		LD	A,(HL)
		INC	HL
		LD	E,$06
		BIT	1,A
		JR	NZ,TFC20_1
		RRA
		LD	A,$03
		ADC	A,$00
		LD	B,A
		LD	C,A
		RET
TFC20_1:	RRA
		JR	C,TFC20_2
		LD	BC,L0104
		RET
TFC20_2:	LD	BC,L0401
		RET
