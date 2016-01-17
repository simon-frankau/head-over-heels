;; 
;; obj_fns.asm
;;
;; The functions that implement the per-object function table.
;;
;; FIXME: Needs a lot of reversing!
;; 

;; Called functions and accessed values:
;; * AnimateObj
;; * C8CD3
;; * C8D18
;; * SetFacingDirEx
;; * CAB06
;; * CAC41
;; * Character
;; * CurrObject
;; * GetCharObj
;; * L0005
;; * TodoFlags
;; * L8ED9
;; * LA2BB
;; * LookupDir
;; * OBJFN_16
;; * OBJFN_FADE
;; * OBJFN_FIRE
;; * ObjDir
;; * ObjectList
;; * PlaySound
;; * ProcObjUnk4
;; * RemoveObject
;; * RobotDir
;; * RootDir
;; * SetSound
;; * StoreObjExtents
;; * TableCall
;; * UnionAndDraw
;; * WorldMask

;; Exports ObjFn* and ObjFn36Val.

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
        ;;           I think it's how we're being pushed. I think bit 5 means 'being stood on'.
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

        ;; Bit 0 set = have updated object extents
TodoFlags:	DEFB $00
L8ED9:		DEFB $FF
RobotDir:	DEFB $FF

ObjFnJoystick:	LD	A,(IY+$0C)
		LD	(IY+$0C),$FF
		OR	$F0
		CP	$FF
		RET	Z
		LD	(RobotDir),A
		RET

ObjFnRobot:	CALL	ObjAgain8
		LD	HL,RobotDir
		LD	A,(HL)
		LD	(HL),$FF
		PUSH	AF
		CALL	LookupDir
		INC	A
		SUB	$01
		CALL	NC,MoveDir
		POP	AF
		CALL	ObjAgain6
		CALL	FaceAndAnimate
		JP	ObjDraw		; Tail call

ObjFnTeleport:	BIT	5,(IY+$0C)
		RET	NZ
		CALL	FaceAndAnimate
		CALL	ObjDraw
		LD	B,$47
		JP	PlaySound 	; Tail call

ObjFn36Val:	DEFB $60
ObjFn36:	LD		HL,ObjFn36Val
		LD		A,(HL)
		AND		A
		RET		NZ
		LD		(HL),$60
		LD		(IY+$0B),~$08
		LD		(IY+$0A),OBJFN_FIRE
		LD		A,$05
		JP		SetSound

ObjFn35Val:	DEFB 0
ObjFn35:	LD		HL,ObjFn35Val
		LD		(HL),$FF
		PUSH	HL
		CALL	ObjFn35b
		POP		HL
		LD		(HL),$00
		RET
ObjFn35b:	LD		A,(ObjDir)
		INC		A
		JR		NZ,ObjFnEnd2
		LD		A,(IY+$0C)
		AND		$20
		RET		NZ
		LD		BC,(LA2BB)
		JR		ObjFnEnd

ObjFn32:	LD		A,(ObjDir)
		INC		A
		JR		NZ,ObjFnEnd2
		CALL		CharDistAndDir
		OR		~$0C	; Clear one axis of direction bits
		CP		C
		JR		Z,ObjFnEnd
		LD		A,C
		OR		$FC
		CP		C
		RET		NZ
        ;; NB: Fall through

ObjFnEnd:	LD		(IY+$0C),C
		JR		ObjFnEnd2

	;; The function associated with a firing donut object.
ObjFnFire:	CALL		AnimateSetBit1
		CALL		ObjFnSub
		JR		C,OFF2
		CALL		ObjFnSub
OFF2:		JP		C,Fadeify
		JR		ObjDraw2

ObjFnBall:	LD		A,(ObjDir)
		INC		A
		JR		NZ,ObjFnEnd2
		LD		A,(IY+$0C)
		INC		A
		JR		Z,ObjFnEnd4
	;; NB: Fall through

ObjFnEnd2:	CALL		ObjAgain8
		CALL		ObjFnSub
ObjDraw2:	JP		ObjDraw

ObjFnEnd4:	PUSH		IY
		CALL		ObjFnPushable
		POP		IY
		LD		(IY+$0B),$FF
		RET

ObjFnSub:	LD		A,(ObjDir)
		AND		A,(IY+$0C)
		CALL		LookupDir
		CP		$FF
		SCF
		RET		Z
		CALL	TableCallCurr
		RET		C
		PUSH	AF
		CALL	UpdateObjExtents
		POP		AF
		PUSH	AF
		CALL	C8CD3
		POP		AF
		LD		HL,(ObjFn35Val)
		INC		L
		RET		Z
		CALL	TableCallCurr
		RET		C
		CALL	C8CD3
		AND		A
		RET

TableCallCurr:	LD		HL,(CurrObject)
		JP		TableCall

ObjFnSwitch:	LD		A,(IY+$0C)
		OR		$C0
		INC		A
		JR		NZ,OFS1
		LD		(IY+$11),A
		RET
OFS1:		LD		A,(IY+$11)
		AND		A
		JR		Z,OFS2
		LD		(IY+$0C),$FF
		RET
OFS2:		DEC	(IY+$11)
		CALL	ObjAgain7
	;; Call PerObj on each object in the object list...
		LD	HL,ObjectList
OFS3:		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		OR	H
		JR	Z,OFS4
		PUSH	HL
		PUSH	HL
		POP	IX
		CALL	PerObj		; Call with the object in HL and IX
		POP	HL
		JR	OFS3
OFS4:		CALL	SetBit1
		LD	A,(IY+$04)
		XOR	$10
		LD	(IY+$04),A
		JP	ObjDraw		; Tail call

PerObj:		LD		A,(IX+$0A)
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
		LD		(IY+$0A),OBJFN_16
		RET

ObjFn19:	BIT	5,(IY+$0C)
		RET	NZ
		CALL	ObjAgain9
		JP	ObjDraw

;; Rollers in the various directions
ObjFnRollers1:  LD      A,~$01
                JR      Write0B

ObjFnRollers2:  LD      A,~$02
                JR      Write0B

ObjFnRollers3:  LD      A,~$08
                JR      Write0B

ObjFnRollers4:  LD      A,~$04
        ;; Fall through

Write0B:        LD      (IY+$0B),A
                LD      (IY+$0A),$00
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
		CALL	UpdateObjExtents
		CALL	AnimateSetBit1
		LD	A,(IY+$0F)
		AND	$07
		JP	NZ,ObjDraw
ObjFnDisappear:	LD	HL,(CurrObject)
		JP	RemoveObject

ObjFnSpring:	LD		B,(IY+$08)
		BIT		5,(IY+$0C)
		SET		5,(IY+$0C)
		LD		A,$2C
		JR		Z,OFSp2
		LD		A,(IY+$0F)
		AND		A
		JR		NZ,OFSp1
		LD		A,$2C
		CP		B
		JR		NZ,ObjFnPushable
		LD		(IY+$0F),$50
		LD		A,$04
		CALL	SetSound
		JR		ObjFnStuff
OFSp1:	AND		$07
		JR		NZ,ObjFnStuff
		LD		A,$2B
OFSp2:	LD		(IY+$08),A
		LD		(IY+$0F),$00
		CP		B
		JR		Z,ObjFnPushable
		JR		ObjFnStuff

ObjFn26:	LD		A,(IY+$0F)
		AND		$F0
		JR		Z,ObjFnPushable
        ;; NB: Fall through

ObjFnStuff:	CALL	UpdateObjExtents
		CALL	AnimateSetBit1
        ;; NB: Fall through

ObjFnPushable:	CALL	ObjAgain8
		LD	A,$FF
		CALL	ObjAgain6
		JP		ObjDraw

ObjFn22:	LD		HL,ObjBlah6
		JP		ObjFnStuff2

ObjFn21:	LD		HL,ObjBlah4
		JP		ObjFnStuff2

ObjFnVisor1:	LD		HL,ObjBlah6
		JR		ObjFnStuff3

ObjFnMonocat:	LD		HL,ObjBlah4
		JR		ObjFnStuff3
	
ObjFn8:		LD		HL,ObjBlah5
		JR		ObjFnStuff3
	
ObjFnBee:	LD		HL,ObjBlah3
		JR		ObjFnStuff3
	
ObjFn12:	LD		HL,ObjBlah3
		JR		ObjFnStuff8
	
ObjFn13:	LD		HL,ObjBlah
		JR		ObjFnStuff8

        ;; Act like a beacon (?)
ObjFnBeacon:	LD		HL,ObjBlah2
		JR		ObjFnStuff8
	
ObjFn15:	LD		HL,HomeIn
		JR		ObjFnStuff7

ObjFn37:	LD		A,(WorldMask)
		OR		$F0
		INC		A
		LD		HL,MoveAway
		JR		Z,OFn37b
		LD		HL,MoveTowards
OFn37b:		JR		ObjFnStuff7

ObjFnStuff2:	PUSH	HL
		CALL	FaceAndAnimate
		JR		ObjFnStuff5
	
ObjFnStuff3:	PUSH	HL
ObjFnStuff4:	CALL	FaceAndAnimate
		CALL	ObjAgain8
		LD		A,$FF
		JR		C,ObjFnStuff6
ObjFnStuff5:	CALL	ObjAgain11
ObjFnStuff6:	CALL	ObjAgain6
		POP		HL
		LD		A,(L8ED9)
		INC		A
		JP		Z,ObjDraw
		CALL	TOHL
		JP		ObjDraw

	;; Calling here is like calling HL.
TOHL:		JP		(HL)

ObjFnStuff7:	PUSH	HL
		CALL	ObjAgain8
		POP	HL
		CALL	TOHL
        ;; NB: Fall through

Collision33:	CALL	FaceAndAnimate
		CALL	ObjAgain11
		CALL	ObjAgain6
		JP	ObjDraw

ObjFnStuff8:	PUSH	HL
		CALL	C8D18
		LD		A,L
		AND		$0F
		JR		NZ,ObjFnStuff4
		CALL	ObjAgain8
		POP		HL
		CALL	TOHL
		CALL	FaceAndAnimate
		CALL	ObjAgain11
		CALL	ObjAgain6
		JP		ObjDraw

ObjFn16Val:		DEFB 0

ObjFn16:	LD		A,$01
		CALL	SetSound
		CALL	FaceAndAnimate
		LD		A,(IY+$11)
		LD		B,A
		BIT		3,A
		JR		Z,OF16e
		RRA
		RRA
		AND		$3C
		LD		C,A
		RRCA
		ADD		A,C
		NEG
		ADD		A,$C0
		CP		A,(IY+$07)
		JR		NC,OF16c
		LD		HL,(CurrObject)
		CALL	CAC41
		RES		4,(IY+$0B)
		JR		NC,OF16b
		JR		Z,OF16g
OF16b:		CALL	UpdateObjExtents
		DEC		(IY+$07)
		JR		OF16g
OF16c:		LD		HL,ObjFn16Val
		LD		A,(HL)
		AND		A
		JR		NZ,OF16d
		LD		(HL),$02
OF16d:		DEC		(HL)
		JR		NZ,OF16g
		LD		A,B
		XOR		$08
		LD		(IY+$11),A
		AND		$08
		JR		OF16g
OF16e:		AND		$07
		ADD		A,A
		LD		C,A
		ADD		A,A
		ADD		A,C
		NEG
		ADD		A,$BF
		CP		A,(IY+$07)
		JR		C,OF16c
		LD		HL,(CurrObject)
		CALL	CAB06
		JR		NC,OF16f
		JR		Z,OF16g
OF16f:		CALL	UpdateObjExtents
		RES		5,(IY+$0B)
		INC		(IY+$07)
OF16g:		JP		ObjDraw

ObjBlah:	CALL	C8D18
		LD		A,L
		AND		$06
		CP		A,(IY+$10)
		JR		Z,ObjBlah
		JR		MoveDir

ObjBlah2:	CALL	C8D18
		LD		A,L
		AND		$06
		OR		$01
		CP		A,(IY+$10)
		JR		Z,ObjBlah2
		JR		MoveDir

ObjBlah3:	CALL	C8D18
		LD		A,L
		AND		$07
		CP		A,(IY+$10)
		JR		Z,ObjBlah3
		JR		MoveDir

ObjBlah4:	LD		A,(IY+$10)
		SUB		$02
		JR		ObjBlah5b

ObjBlah5:	LD		A,(IY+$10)
		ADD		A,$02
ObjBlah5b:	AND		$07
        ;; NB: Fall through

MoveDir:	LD		(IY+$10),A
		RET

ObjBlah6:	LD		A,(IY+$10)
		ADD		A,$04
		JR		ObjBlah5b

ObjFn33:	CALL		ObjAgain8
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
NoColl33:	CALL		FaceAndAnimate
		JP		ObjDraw

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


;; If bit 0 of TodoFlags is not set, set it and set the object extents.
UpdateObjExtents:
                LD      A,(TodoFlags)
                BIT     0,A
                RET     NZ
                OR      $01
                LD      (TodoFlags),A
                LD      HL,(CurrObject)
                JP      StoreObjExtents

;; Clear $0C and if any of TodoFlags are set, draw the thing.
ObjDraw:        LD      (IY+$0C),$FF
                LD      A,(TodoFlags)
                AND     A
                RET     Z
                CALL    UpdateObjExtents
                LD      HL,(CurrObject)
                CALL    ProcObjUnk4
                LD      HL,(CurrObject)
                JP      UnionAndDraw

FaceAndAnimate: CALL    SetFacingDirEx
        ;; NB: Fall through

;; Calls animate and SetBit1 if it's an animation.
AnimateSetBit1: CALL    AnimateObj
                RET     NC
        ;; NB: Fall through

;; Sets bit 1 of TodoFlags
SetBit1:        LD      A,(TodoFlags)
                OR      $02
                LD      (TodoFlags),A
                RET

ObjAgain6:	AND		A,(IY+$0C)
		CP		$FF
		LD		(L8ED9),A
		RET		Z
		CALL	LookupDir
		CP		$FF
		LD		(L8ED9),A
		RET		Z
		PUSH	AF
		LD		(L8ED9),A
		CALL	TableCallCurr
		POP		BC
		CCF
		JP		NC,OA6c
		PUSH	AF
		CP		B
		JR		NZ,OA6b
		LD		A,$FF
		LD		(L8ED9),A
OA6b:		CALL	UpdateObjExtents
		POP		AF
		CALL	C8CD3
		SCF
		RET
OA6c:		LD		A,(ObjDir)
		INC		A
		RET		Z
        ;; NB: Fall through
        
ObjAgain7:	LD		A,$06
		JP		SetSound

        ;; TODO: Called quite a lot.
ObjAgain8:	BIT		4,(IY+$0C)
		JR		Z,ObjAgain10
        ;; NB: Fall through

ObjAgain9:	LD		HL,(CurrObject)
		CALL	CAB06
		JR		NC,OA9c
		CCF
		JR		NZ,OA9b
		BIT		4,(IY+$0C)
		RET		NZ
		JR		ObjAgain10
OA9b:		BIT		4,(IY+$0C)
		SCF
		JR		NZ,OA9c
		RES		4,(IY+$0B)
		RET
OA9c:		PUSH	AF
		CALL	UpdateObjExtents
		RES		5,(IY+$0B)
		INC		(IY+$07)
		LD		A,$03
		CALL	SetSound
		POP		AF
		RET		C
		INC		(IY+$07)
		SCF
		RET

ObjAgain10:	LD		HL,(CurrObject)
		CALL	CAC41
		RES		4,(IY+$0B)
		JR		NC,OA10b
		CCF
		RET		Z
OA10b:		CALL	UpdateObjExtents
		DEC		(IY+$07)
		SCF
		RET

ObjAgain11:	LD		A,(IY+$10)
		ADD		A,$76
		LD		L,A
		ADC		A,$93
		SUB		L
		LD		H,A
		LD		A,(HL)
		RET
