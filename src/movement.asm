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

        ;; TODO: This part of the function is the most mysterious...
Down:		CALL	InitMove
		JR	Z,D_NoExit
		CALL	UD_fn
		LD	A,$24
		JR	C,D_NoExit2
        ;; If the wall has a door, and
        ;; we're the right height to fit through, and
        ;; we're lined up to go through the frame,
        ;; set 'A' to be the far side of the door.
                BIT     0,(IX-$01) ; HasDoor
                JR      Z,D_NoDoor
                LD      A,(DoorHeights + 3)
                CALL    DoorHeightCheck
                JR      C,D_NoExit
                CALL    UD_InFrame
                JR      C,D_NearDoor
                LD      A,(MinU)
                SUB     $04
                JR      D_Exit
        ;; If there's no wall, put the room end coordinate into 'A'...
D_NoDoor:       BIT     0,(IX-$02) ; HasNoWall
                JR      Z,D_NoExit
                LD      A,(MinU)
        ;; Case where we can exit the room.
D_Exit:         CP      E
                RET     NZ
                LD      A,$01
	;; NB: Shared across the various cases:
CommonRet:	LD	(LB218),A
		SCF
		RET

        ;; The case where we can't exit the room, but may hit the
        ;; wall.
D_NoExit:       LD      A,(MinU)
        ;; (or some other value given in A).
D_NoExit2:      CP      E
                RET     NZ
                SCF
                RET

        ;; Handle the near-door case: If we're not near the door frame,
        ;; we do the normal "not door" case. Otherwise, we do that and
        ;; then nudge into the door.
D_NearDoor:     CALL    UD_InFrameW
                JR      C,D_NoExit
                CALL    D_NoExit
        ;; NB: Fall through

        ;; Choose a direction to move based on which side of the door
        ;; we're trying to get through.
UD_Nudge:       RET     NZ
                LD      A,L
                CP      DOOR_LOW + 1
                LD      A,~$08
                JR      C,Nudge
                LD      A,~$04
        ;; NB: Fall through

        ;; Update the direction with they way to go to get through the door.
Nudge:          LD      (Movement),A
                XOR     A
                SCF
                RET

Right:		CALL	InitMove
		JR	Z,R_NoExit
		CALL	LR_fn
		LD	A,$24
		JR	C,R_NoExit2
		BIT	1,(IX-$01) ; HasDoor
		JR	Z,R_NoDoor
		LD	A,(DoorHeights + 2)
		CALL	DoorHeightCheck
		JR	C,R_NoExit
		CALL	LR_InFrame
		JR	C,R_NearDoor
		LD	A,(MinV)
		SUB	$04
		JR	R_Exit
R_NoDoor:		BIT	1,(IX-$02) ; HasNoWall
		JR	Z,R_NoExit
		LD	A,(MinV)
R_Exit:		CP	L
		RET	NZ
		LD	A,$02
		JR	CommonRet
R_NoExit:		LD	A,(MinV)
R_NoExit2:		CP	L
		RET	NZ
		SCF
		RET
R_NearDoor:		CALL	LR_InFrameW
		JR	C,R_NoExit
		CALL	R_NoExit
	;; NB: Fall through
LR_Nudge:		RET	NZ
		LD	A,E
		CP	$25
		LD	A,$FE
		JR	C,Nudge
		LD	A,$FD
		JR	Nudge

Up:		CALL	InitMove
		JR	Z,U_NoExit
		CALL	UD_fn
		LD	A,$2C
		JR	C,U_NoExit2
		BIT	2,(IX-$01) ; HasDoor
		JR	Z,U_NoDoor
		LD	A,(DoorHeights + 1)
		CALL	DoorHeightCheck
		JR	C,U_NoExit
		CALL	UD_InFrame
		JR	C,U_NearDoor
		LD	A,(MaxU)
		ADD	A,$04
		JR	U_Exit
U_NoDoor:		BIT	2,(IX-$02) ; HasNoWall
		JR	Z,U_NoExit
		LD	A,(MaxU)
U_Exit:		CP	D
		RET	NZ
		LD	A,$03
		JP	CommonRet
U_NoExit:		LD	A,(MaxU)
U_NoExit2:		CP	D
		RET	NZ
		SCF
		RET
U_NearDoor:		CALL	UD_InFrameW
		JR	C,U_NoExit
		CALL	U_NoExit
		JP	UD_Nudge

Left:		CALL	InitMove
		JR	Z,L_NoExit
		CALL	LR_fn
		LD	A,$2C
		JR	C,L_NoExit2
		BIT	3,(IX-$01) ; HasDoor
		JR	Z,L_NoDoor
		LD	A,(DoorHeights)
		CALL	DoorHeightCheck
		JR	C,L_NoExit
		CALL	LR_InFrame
		JR	C,L_NearDoor
		LD	A,(MaxV)
		ADD	A,$04
		JR	L_Exit
L_NoDoor:		BIT	3,(IX-$02) ; HasNoWall
		JR	Z,L_NoExit
		LD	A,(MaxV)
L_Exit:		CP	H
		RET	NZ
		LD	A,$04
		JP	CommonRet
L_NoExit:		LD	A,(MaxV)
L_NoExit2:		CP	H
		RET	NZ
		SCF
		RET
L_NearDoor:		CALL	LR_InFrameW
		JR	C,L_NoExit
		CALL	L_NoExit
		JP	LR_Nudge

UD_fn:		LD	A,(MaxV)
		CP	H
		RET	C
		LD	A,L
		CP	A,(IX+$01) ; MinV
		RET

LR_fn:		LD	A,(MaxU)
		CP	D
		RET	C
		LD	A,E
		CP	A,(IX+$00) ; MinU
		RET

;; Return NC if within the interval associated with the door.
;; Specifically, returns NC if D <= DOOR_HIGH and E >= DOOR_LOW
LR_InFrame:     LD      A,DOOR_HIGH
                CP      D
                RET     C
                LD      A,E
                CP      DOOR_LOW
                RET

;; Same, but for the whole door, not just the inner arch
LR_InFrameW:    LD      A,DOOR_HIGH + 4
                CP      D
                RET     C
                LD      A,E
                CP      DOOR_LOW - 4
                RET

;; Return NC if within the interval associated with the door.
;; Specifically, returns NC if H <= DOOR_HIGH and L >= DOOR_LOW
UD_InFrame:     LD      A,DOOR_HIGH
                CP      H
                RET     C
                LD      A,L
                CP      DOOR_LOW
                RET

UD_InFrameW:    LD      A,DOOR_HIGH + 4
                CP      H
                RET     C
                LD      A,L
                CP      DOOR_LOW - 4
                RET

;; Door height check.
;;
;; Checks to see if the character Z coord (in A) is between B
;; and either B + 3 or B + 9 (depending on if you're both head
;; and heels currently). Returns NC if the character is in the right
;; height range to go through door.
DoorHeightCheck:SUB     B
                RET     C
                PUSH    AF
                LD      A,(Character)
                CP      $03
                JR      NZ,DHC_1
                POP     AF
                CP      $03
                CCF
                RET
DHC_1:          POP     AF
                CP      $09
                CCF
                RET

        ;; Points IX at the room boundaries, sets zero flag if:
        ;; Bit 0 of IY+09 is not zero and
        ;; Bottom 7 bits of IY+0A are zero.
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
