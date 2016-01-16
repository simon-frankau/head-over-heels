	;; 
	;; obj_fns.asm
	;;
	;; The functions that implement the per-object function table.
	;;
	;; FIXME: Needs a lot of reversing!
	;; 

	;; Exports ObjFn* and L8F18.

	;; ObjectList appears to be head of a linked list:
	;; Offset 0: Next item (null == end)
        ;; Offset 2: Another list?
	;; Offset 4: Some flag - bit 6 and 7 causes skipping. Bit 6 = carryable?
        ;;           Bits 0-2: ObjectShape (see GetNewCoords)
        ;;           Bit 3:    Tall (extra 6 height)
	;; Offset 5: U coordinate
	;; Offset 6: V coordinate
	;; Offset 7: Z coordinate, C0 = ground
	;; Offset 8: Its sprite
	;; Offset 9: Gets used as a sprite code???
        ;;           Bit 5 = has another object tacked after (double height?)
	;; Offset A: Top bit is flag that's checked against Phase, lower bits are object function.
        ;;           Gets loaded into SpriteFlags
	;; Offset B: Some form of direction mask?
	;; Offset C: Some form of direction mask?
        ;; Offset F: Animation code - top 5 bits are the animation, bottom 3 bits are the frame.
	;; Offset 10: Direction code.
	;; Hmmm. May be 17 bytes? Object-copying code suggests 18 bytes.

        ;; U/V coordinates: X/Y coordinates are used for screen space,
        ;; so we'll use U/V/Z coordinates for the isometric space.
        ;; V     U
        ;;  \   /
        ;;   \ /
        ;;    *
        ;;    |
        ;;    Z

O_SPRITE:       EQU $08
O_ANIM: 	EQU $0F
        
ObjFnJoystick:	LD	A,(IY+$0C)
		LD	(IY+$0C),$FF
		OR	$F0
		CP	$FF
		RET	Z
		LD	(L8EDA),A
		RET

ObjFn29:	CALL	C9319
		LD	HL,L8EDA
		LD	A,(HL)
		LD	(HL),$FF
		PUSH	AF
		CALL	LookupDir
		INC	A
		SUB	$01
		CALL	NC,MoveDir
		POP	AF
		CALL	C92DF
		CALL	C92CF
		JP	C92B7		; Tail call

ObjFnTeleport:	BIT	5,(IY+$0C)
		RET	NZ
		CALL	C92CF
		CALL	C92B7
		LD	B,$47
		JP	PlaySound 	; Tail call

L8F18:		LD		H,B
ObjFn36:	LD		HL,L8F18
		LD		A,(HL)
		AND		A
		RET		NZ
		LD		(HL),$60
		LD		(IY+$0B),$F7
		LD		(IY+$0A),$19
		LD		A,$05
		JP		SetSound

L8F2E:	NOP
ObjFn35:	LD		HL,L8F2E
		LD		(HL),$FF
		PUSH	HL
		CALL	C8F3C
		POP		HL
		LD		(HL),$00
		RET
C8F3C:		LD		A,(ObjDir)
		INC		A
		JR		NZ,L8F82
		LD		A,(IY+$0C)
		AND		$20
		RET		NZ
		LD		BC,(LA2BB)
		JR		L8F61

ObjFn32:	LD		A,(ObjDir)
		INC		A
		JR		NZ,L8F82
		CALL		CharDistAndDir
		OR		~$0C	; Clear one axis of direction bits
		CP		C
		JR		Z,L8F61
		LD		A,C
		OR		$FC
		CP		C
		RET		NZ
L8F61:	LD		(IY+$0C),C
		JR		L8F82

	;; The function associated with a firing donut object.
ObjFnFire:	CALL		C92D2
		CALL		C8F97
		JR		C,OFF2
		CALL		C8F97
OFF2:		JP		C,Fadeify
		JR		L8F88

ObjFnBall:	LD		A,(ObjDir)
		INC		A
		JR		NZ,L8F82
		LD		A,(IY+$0C)
		INC		A
		JR		Z,L8F8B
	;; NB: Fall through

L8F82:		CALL		C9319
		CALL		C8F97
L8F88:		JP		C92B7
L8F8B:		PUSH		IY
		CALL		ObjFnPushable
		POP		IY
		LD		(IY+$0B),$FF
		RET

C8F97:		LD		A,(ObjDir)
		AND		A,(IY+$0C)
		CALL		LookupDir
		CP		$FF
		SCF
		RET		Z
		CALL	C8FC0
		RET		C
		PUSH	AF
		CALL	C92A6
		POP		AF
		PUSH	AF
		CALL	C8CD3
		POP		AF
		LD		HL,(L8F2E)
		INC		L
		RET		Z
		CALL	C8FC0
		RET		C
		CALL	C8CD3
		AND		A
		RET

C8FC0:	LD		HL,(CurrObject)
		JP		TableCall

ObjFnSwitch:	LD		A,(IY+$0C)
		OR		$C0
		INC		A
		JR		NZ,L8FD2
		LD		(IY+$11),A
		RET
L8FD2:		LD		A,(IY+$11)
		AND		A
		JR		Z,L8FDD
		LD		(IY+$0C),$FF
		RET
	
L8FDD:		DEC	(IY+$11)
		CALL	C9314
	;; Call C9005 on each object in the object list...
		LD	HL,ObjectList
L8FE6:		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		OR	H
		JR	Z,L8FF7
		PUSH	HL
		PUSH	HL
		POP	IX
		CALL	C9005		; Call with the object in HL and IX
		POP	HL
		JR	L8FE6
L8FF7:		CALL	C92D6
		LD	A,(IY+$04)
		XOR	$10
		LD	(IY+$04),A
		JP	C92B7		; Tail call

C9005:		LD		A,(IX+$0A)
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

ObjFnHeliplat2:	LD 	A,$90
		DEFB 	$01			; LD BC,nn , NOPs next instruction!

ObjFnHeliplat:  LD		A,$52
		LD		(IY+$11),A
		LD		(IY+$0A),$10
		RET

ObjFn19:	BIT		5,(IY+$0C)
		RET		NZ
		CALL	C931F
		JP		C92B7
	
ObjFnRollers1:  LD		A,$FE
		JR		Write0B

ObjFnRollers2:	LD		A,$FD
		JR		Write0B

ObjFnRollers3:	LD		A,$F7
		JR		Write0B

ObjFnRollers4:	LD		A,$FB
	;; Fall through
	
Write0B:	LD		(IY+$0B),A
		LD		(IY+$0A),$00
		RET

ObjFnHushPuppy:	LD	A,(Character)
		AND	$02			; Test if we have Head (returns early if not)
		JR	TestAndFade

        ;; FIXME: Theory is this is for the dissolving wall grating next to the hooter
ObjFnDissolve:	LD	A,$C0
		DEFB	$01			; LD BC,nn , NOPs next instruction!
ObjFnDissolve2: LD	A,$CF
		OR	A,(IY+$0C)
		INC	A
	;; NB: Fall through

TestAndFade:	RET	Z
	;; NB: Fall through

        ;; Set to use ObjFnFade
Fadeify:	LD	A,$05
		CALL	SetSound
		LD	A,(IY+$0A)
		AND	$80
		OR	OBJFN_FADE
		LD	(IY+$0A),A
		LD	(IY+$0F),$08
        ;; NB: Fall through

ObjFnFade:	LD	(IY+$04),$80
		CALL	C92A6
		CALL	C92D2
		LD	A,(IY+$0F)
		AND	$07
		JP	NZ,C92B7
ObjFnDisappear:	LD	HL,(CurrObject)
		JP	RemoveObject

ObjFnSpring:	LD		B,(IY+$08)
		BIT		5,(IY+$0C)
		SET		5,(IY+$0C)
		LD		A,$2C
		JR		Z,L90B3
		LD		A,(IY+$0F)
		AND		A
		JR		NZ,L90AD
		LD		A,$2C
		CP		B
		JR		NZ,ObjFnPushable
		LD		(IY+$0F),$50
		LD		A,$04
		CALL	SetSound
		JR		L90C6

L90AD:	AND		$07
		JR		NZ,L90C6
		LD		A,$2B
L90B3:	LD		(IY+$08),A
		LD		(IY+$0F),$00
		CP		B
		JR		Z,ObjFnPushable
		JR		L90C6

ObjFn26:	LD		A,(IY+$0F)
		AND		$F0
		JR		Z,ObjFnPushable
L90C6:		CALL	C92A6
		CALL	C92D2
ObjFnPushable:	CALL	C9319
		LD	A,$FF
		CALL	C92DF
		JP		C92B7
ObjFn22:	LD		HL,L921F
		JP		L911B

ObjFn21:	LD		HL,L920D
		JP		L911B

ObjFnVisor1:	LD		HL,L921F
		JR		L9121

ObjFnMonocat:	LD		HL,L920D
		JR		L9121
	
ObjFn8:		LD		HL,L9214
		JR		L9121
	
ObjFnBee:	LD		HL,L9200
		JR		L9121
	
ObjFn12:	LD		HL,L9200
		JR		L9155
	
ObjFn13:	LD		HL,L91E4
		JR		L9155

        ;; Act like a beacon (?)
ObjFnBeacon:	LD		HL,L91F1
		JR		L9155
	
ObjFn15:	LD		HL,HomeIn
		JR		L9141

ObjFn37:	LD		A,(WorldMask)
		OR		$F0
		INC		A
		LD		HL,MoveAway
		JR		Z,L9119
		LD		HL,MoveTowards
L9119:		JR		L9141
	
L911B:		PUSH	HL
		CALL	C92CF
		JR		L912C
	
L9121:	PUSH	HL
L9122:	CALL	C92CF
		CALL	C9319
		LD		A,$FF
		JR		C,L912F
L912C:	CALL	C936A
L912F:	CALL	C92DF
		POP		HL
		LD		A,(L8ED9)
		INC		A
		JP		Z,C92B7
		CALL	TOHL
		JP		C92B7

	;; Calling here is like calling HL.
TOHL:		JP		(HL)

L9141:		PUSH	HL
		CALL	C9319
		POP	HL
		CALL	TOHL
Collision33:	CALL	C92CF
		CALL	C936A
		CALL	C92DF
		JP		C92B7

L9155:		PUSH	HL
		CALL	C8D18
		LD		A,L
		AND		$0F
		JR		NZ,L9122
		CALL	C9319
		POP		HL
		CALL	TOHL
		CALL	C92CF
		CALL	C936A
		CALL	C92DF
		JP		C92B7

L9171:		NOP

ObjFn16:	LD		A,$01
		CALL	SetSound
		CALL	C92CF
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
		LD		HL,(CurrObject)
		CALL	CAC41
		RES		4,(IY+$0B)
		JR		NC,L91A0
		JR		Z,L91E1
L91A0:	CALL	C92A6
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
		LD		HL,(CurrObject)
		CALL	CAB06
		JR		NC,L91D7
		JR		Z,L91E1
L91D7:	CALL	C92A6
		RES		5,(IY+$0B)
		INC		(IY+$07)
L91E1:	JP		C92B7
L91E4:	CALL	C8D18
		LD		A,L
		AND		$06
		CP		A,(IY+$10)
		JR		Z,L91E4
		JR		MoveDir
L91F1:	CALL	C8D18
		LD		A,L
		AND		$06
		OR		$01
		CP		A,(IY+$10)
		JR		Z,L91F1
		JR		MoveDir
L9200:	CALL	C8D18
		LD		A,L
		AND		$07
		CP		A,(IY+$10)
		JR		Z,L9200
		JR		MoveDir
L920D:	LD		A,(IY+$10)
		SUB		$02
		JR		L9219
L9214:	LD		A,(IY+$10)
		ADD		A,$02
L9219:	AND		$07

MoveDir:	LD		(IY+$10),A
		RET

L921F:	LD		A,(IY+$10)
		ADD		A,$04
		JR		L9219

ObjFn33:	CALL		C9319
	;; Check for collision
		CALL		CharDistAndDir
		LD		A,$18
		CP		D
		JR		C,NoColl33
		CP		E
		JP		C,NoColl33
		LD		A,C
		CALL		LookupDir
		LD		(IY+$10),A
		JP		Collision33
NoColl33:	CALL		C92CF
		JP		C92B7

	;; Find the direction number associated with zeroing the
	;; smaller distance, and then working towards the other
	;; dimension.
HomeIn:		CALL		CharDistAndDir
		LD		A,D
		CP		E
		LD		B,~$0C
		JR		C,HI2
		LD		A,E
		LD		B,~$03
HI2:		AND		A
		LD		A,B
		JR		NZ,HI3
		XOR		$0F
HI3:		OR		C
	;; NB: Fall through

MoveToDirMask:	CALL		LookupDir
		JR		MoveDir

MoveAway:	CALL		CharDistAndDir
		XOR		$0F
		JR		MoveToDirMask
MoveTowards:	CALL		CharDistAndDir
		JR		MoveToDirMask

	;; Return the absolute distances from the character in DE,
	;; and direction as a bitmask in A.
CharDistAndDir:	CALL		GetCharObj
		LD		DE,L0005
		ADD		HL,DE
		LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
	;; Character position now in HL.
		LD		C,$FF
		LD		A,H
		SUB		(IY+$06)
		LD		D,A
	;; Second coord diff in D...
		JR		Z,SndCoordMatch
		JR		NC,SndCoordDiff
		NEG
		LD		D,A
		SCF
	;; Absolute coord diff in D...
SndCoordDiff:	PUSH		AF
		RL		C
		POP		AF
		CCF
		RL		C
        ;; Build 2 bits of direction flag in C
SndCoordMatch:	LD		A,(IY+$05)
		SUB		L
		LD		E,A
		JR		Z,FstCoordMatch
		JR		NC,FstCoordDiff
		NEG
		LD		E,A
		SCF
	;; Absolute coord diff in E...
FstCoordDiff:	PUSH		AF
		RL		C
		POP		AF
		CCF
		RL		C
		LD		A,C
	;; Direction flag now in A.
		RET
FstCoordMatch:	RLC		C
		RLC		C
		LD		A,C
	;; Direction flag now in A.
		RET


C92A6:	LD		A,(L8ED8)
		BIT		0,A
		RET		NZ
		OR		$01
		LD		(L8ED8),A
		LD		HL,(CurrObject)
		JP		StoreObjExtents
C92B7:	LD		(IY+$0C),$FF
		LD		A,(L8ED8)
		AND		A
		RET		Z
		CALL	C92A6
		LD		HL,(CurrObject)
		CALL	ProcObjUnk4
		LD		HL,(CurrObject)
		JP		UnionAndDraw
C92CF:	CALL	C937E
C92D2:	CALL	AnimateObj
		RET		NC
C92D6:	LD		A,(L8ED8)
		OR		$02
		LD		(L8ED8),A
		RET
C92DF:	AND		A,(IY+$0C)
		CP		$FF
		LD		(L8ED9),A
		RET		Z
		CALL	LookupDir
		CP		$FF
		LD		(L8ED9),A
		RET		Z
		PUSH	AF
		LD		(L8ED9),A
		CALL	C8FC0
		POP		BC
		CCF
		JP		NC,L930F
		PUSH	AF
		CP		B
		JR		NZ,L9306
		LD		A,$FF
		LD		(L8ED9),A
L9306:	CALL	C92A6
		POP		AF
		CALL	C8CD3
		SCF
		RET
L930F:	LD		A,(ObjDir)
		INC		A
		RET		Z
C9314:	LD		A,$06
		JP		SetSound
C9319:	BIT		4,(IY+$0C)
		JR		Z,L9354
C931F:	LD		HL,(CurrObject)
		CALL	CAB06
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
		CALL	C92A6
		RES		5,(IY+$0B)
		INC		(IY+$07)
		LD		A,$03
		CALL	SetSound
		POP		AF
		RET		C
		INC		(IY+$07)
		SCF
		RET
L9354:	LD		HL,(CurrObject)
		CALL	CAC41
		RES		4,(IY+$0B)
		JR		NC,L9362
		CCF
		RET		Z
L9362:	CALL	C92A6
		DEC		(IY+$07)
		SCF
		RET
C936A:	LD		A,(IY+$10)
		ADD		A,$76
		LD		L,A
		ADC		A,$93
		SUB		L
		LD		H,A
		LD		A,(HL)
		RET
