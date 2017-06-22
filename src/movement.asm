	;;
	;; movement.asm
	;;
	;; Performs movement in a direction.
	;;
	;; Only exported value is MoveTbl
	;; Only call out is to DoMove... which calls right back!

	;; Variables used in this file:
	;; MinU
	;; MinV
	;; MaxU
	;; MaxV
	;; DoorHeights
	;; Movement
	;; LB218

        ;; Table is indexed on a direction, as per LookupDir.
        ;; First element is bit mask for directions.
        ;; Second is the function to move that direction.
        ;; Third element is ???
MoveTbl:        DEFB ~$02
                DEFW Down,DownThing
                DEFB ~$00
                DEFW DownRight,0
                DEFB ~$04
                DEFW Right,RightThing
                DEFB ~$00
                DEFW UpRight,0
                DEFB ~$01
                DEFW Up,UpThing
                DEFB ~$00
                DEFW UpLeft,0
                DEFB ~$08
                DEFW Left,LeftThing
                DEFB ~$00
                DEFW DownLeft,0

        ;; Movement functions expects extents in primed registers.
        ;; Returns direction actually travelled.
        ;; TODO: And sets some flags?

DownRight:      EXX
        ;; Remove original return path, hit DoMove again.
                POP     HL
                POP     DE
        ;; Call Down
                XOR     A
                CALL    DoMove
                JR      C,DR_1
        ;; Update extents in DE
                EXX
                DEC     D
                DEC     E
                EXX
        ;; Call Right
                LD      A,$02
                CALL    DoMove
                LD      A,$01
                RET     NC
                XOR     A
                RET
        ;; Call Right
DR_1:           LD      A,$02
                CALL    DoMove
                RET     C
                AND     A
                LD      A,$02
                RET

UpRight:        EXX
        ;; Remove original return path, hit DoMove again.
                POP     HL
                POP     DE
        ;; Call Up
                LD      A,$04
                CALL    DoMove
                JR      C,UR_1
                EXX
                INC     D
                INC     E
                EXX
        ;; Call Right
                LD      A,$02
                CALL    DoMove
                LD      A,$03
                RET     NC
                LD      A,$04
                AND     A
                RET
        ;; Call Right
UR_1:           LD      A,$02
                CALL    DoMove
                RET     C
                AND     A
                LD      A,$02
                RET

UpLeft:         EXX
        ;; Remove original return path, hit DoMove again.
                POP     HL
                POP     DE
        ;; Call Up
                LD      A,$04
                CALL    DoMove
                JR      C,UL_1
                EXX
                INC     D
                INC     E
                EXX
        ;; Call Left
                LD      A,$06
                CALL    DoMove
                LD      A,$05
                RET     NC
                LD      A,$04
                AND     A
                RET
        ;; Call Left
UL_1:           LD      A,$06
                CALL    DoMove
                RET     C
                LD      A,$06
                RET

DownLeft:       EXX
        ;; Remove original return path, hit DoMove again.
                POP     HL
                POP     DE
        ;; Call Down
                XOR     A
                CALL    DoMove
                JR      C,DL_1
                EXX
                DEC     D
                DEC     E
                EXX
        ;; Call Left
                LD      A,$06
                CALL    DoMove
                LD      A,$07
                RET     NC
                XOR     A
                RET
        ;; Call Left
DL_1:           LD      A,$06
                CALL    DoMove
                RET     C
                AND     A
                LD      A,$06
                RET

UpThing:	INC	HL
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

LeftThing:	INC	HL
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

DownThing:	CALL	TblFnCommon20
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

RightThing:	CALL	TblFnCommon20
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
	
Down:		CALL	InitMove
		JR	Z,D_3
		CALL	UD_fn
		LD	A,$24
		JR	C,D_4
		BIT	0,(IX-$01)
		JR	Z,D_1
		LD	A,(DoorHeights + 3)
		CALL	CommonFn
		JR	C,D_3
		CALL	UD_fn2
		JR	C,D_5
		LD	A,(MinU)
		SUB	$04
		JR	D_2
D_1:		BIT	0,(IX-$02)
		JR	Z,D_3
		LD	A,(MinU)
D_2:		CP	E
		RET	NZ
		LD	A,$01
	;; NB: Shared across the various cases:
CommonRet:	LD	(LB218),A
		SCF
		RET
D_3:		LD	A,(MinU)
D_4:		CP	E
		RET	NZ
		SCF
		RET
D_5:		CALL	UD_fn3
		JR	C,D_3
		CALL	D_3
	;; NB: Fall through
UD_fn4:		RET	NZ
		LD	A,L
		CP	$25
		LD	A,$F7
		JR	C,CommonFn2
		LD	A,$FB
	;; NB: Fall through
CommonFn2:	LD	(Movement),A
		XOR	A
		SCF
		RET

Right:		CALL	InitMove
		JR	Z,R_3
		CALL	LR_fn
		LD	A,$24
		JR	C,R_4
		BIT	1,(IX-$01)
		JR	Z,R_1
		LD	A,(DoorHeights + 2)
		CALL	CommonFn
		JR	C,R_3
		CALL	LR_fn2
		JR	C,R_5
		LD	A,(MinV)
		SUB	$04
		JR	R_2
R_1:		BIT	1,(IX-$02)
		JR	Z,R_3
		LD	A,(MinV)
R_2:		CP	L
		RET	NZ
		LD	A,$02
		JR	CommonRet
R_3:		LD	A,(MinV)
R_4:		CP	L
		RET	NZ
		SCF
		RET
R_5:		CALL	LR_fn3
		JR	C,R_3
		CALL	R_3
	;; NB: Fall through
LR_fn4:		RET	NZ
		LD	A,E
		CP	$25
		LD	A,$FE
		JR	C,CommonFn2
		LD	A,$FD
		JR	CommonFn2

Up:		CALL	InitMove
		JR	Z,U_3
		CALL	UD_fn
		LD	A,$2C
		JR	C,U_4
		BIT	2,(IX-$01)
		JR	Z,U_1
		LD	A,(DoorHeights + 1)
		CALL	CommonFn
		JR	C,U_3
		CALL	UD_fn2
		JR	C,U_5
		LD	A,(MaxU)
		ADD	A,$04
		JR	U_2
U_1:		BIT	2,(IX-$02)
		JR	Z,U_3
		LD	A,(MaxU)
U_2:		CP	D
		RET	NZ
		LD	A,$03
		JP	CommonRet
U_3:		LD	A,(MaxU)
U_4:		CP	D
		RET	NZ
		SCF
		RET
U_5:		CALL	UD_fn3
		JR	C,U_3
		CALL	U_3
		JP	UD_fn4

Left:		CALL	InitMove
		JR	Z,L_3
		CALL	LR_fn
		LD	A,$2C
		JR	C,L_4
		BIT	3,(IX-$01)
		JR	Z,L_1
		LD	A,(DoorHeights)
		CALL	CommonFn
		JR	C,L_3
		CALL	LR_fn2
		JR	C,L_5
		LD	A,(MaxV)
		ADD	A,$04
		JR	L_2
L_1:		BIT	3,(IX-$02)
		JR	Z,L_3
		LD	A,(MaxV)
L_2:		CP	H
		RET	NZ
		LD	A,$04
		JP	CommonRet
L_3:		LD	A,(MaxV)
L_4:		CP	H
		RET	NZ
		SCF
		RET
L_5:		CALL	LR_fn3
		JR	C,L_3
		CALL	L_3
		JP	LR_fn4

UD_fn:		LD	A,(MaxV)
		CP	H
		RET	C
		LD	A,L
		CP	A,(IX+$01)
		RET

LR_fn:		LD	A,(MaxU)
		CP	D
		RET	C
		LD	A,E
		CP	A,(IX+$00)
		RET

LR_fn2:		LD	A,$2C
		CP	D
		RET	C
		LD	A,E
		CP	$24
		RET

LR_fn3:		LD	A,$30
		CP	D
		RET	C
		LD	A,E
		CP	$20
		RET

UD_fn2:		LD	A,$2C
		CP	H
		RET	C
		LD	A,L
		CP	$24
		RET

UD_fn3:		LD	A,$30
		CP	H
		RET	C
		LD	A,L
		CP	$20
		RET

	;; Checks to see if A is between B and B + 3 / 9
	;; (depending on if you're both head and heels currently)
CommonFn:	SUB	B
		RET	C
		PUSH	AF
		LD	A,(Character)
		CP	$03
		JR	NZ,CF_1
		POP	AF
		CP	$03
		CCF
		RET
CF_1:		POP	AF
		CP	$09
		CCF
		RET

InitMove:	LD	IX,MinU
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
		LD	BC,$0104 ; TODO
		RET
TFC20_2:	LD	BC,$0401 ; TODO
		RET
