	;; 
	;; character.asm
	;;
	;; Does a lot of stuff which seems to care about Character.
	;;
	;; Looks like it hangs together, but needs a lot of
	;; reverse-engineering
	;; 

	;; Exported functions:
	;; * CharThing
	;; * CharThing3
	;; * SetSound
	;; * GetCharObj
	;; * CharThing15
	;; * DrawCarriedObject

	;; Unknown functions that are called:
	;; C72A0
	;; UpdatePos
	;; C8CF0
	;; C8D7F
	;; WiggleEyebrows
	;; CAA74
	;; CAC41
	;; SetObjList
	;; Enlist
	;; EnlistAux
	;; Relink
	;; Unlink
	;; LB21C
	
	
	;; Something of an epic function...
	;; Think it involves general movement/firing etc.
CharThing:	LD	A,(LA314)
		RLA
		CALL	C,WiggleEyebrows
		LD	HL,LB219
		LD	A,(HL)
		AND	A
		JR	Z,EPIC_1
		EXX
		LD	HL,Character
		LD	A,(Dying)
		AND	(HL)
		EXX
		JP	NZ,HandleDeath 		; NB: Tail call
		CALL	HandleDeath
EPIC_1:		LD	HL,LA296
		LD	A,(HL)
		AND	A
		JP	NZ,EPIC_14
		INC	HL
		OR	(HL)
		JP	NZ,EPIC_13

	;; Deal with invuln counter every 3 frames.
		LD	HL,InvulnModulo
		DEC	(HL)
		JR	NZ,EPIC_2
		LD	(HL),$03
		LD	HL,(Character)
		LD	A,H
		ADD	A,A
		OR	H
		OR	L
		RRA
		PUSH	AF
	;; Use up heels invuln
		LD	A,$02
		CALL	C,DecCount
		POP	AF
		RRA
	;; Use up head invuln
		LD	A,$03
		CALL	C,DecCount
EPIC_2:		LD	A,$FF
		LD	(Movement),A
		LD	A,(LB218)
		AND	A
		JR	Z,EPIC_4
		LD	A,(SavedObjListIdx)
		AND	A
		JR	Z,EPIC_3
		LD	A,(LA2BB)
		SCF
		RLA
		LD	(CurrDir),A
		JR	EPIC_4
EPIC_3:		LD	(LB218),A
EPIC_4:		CALL	CharThing4
	;; NB: Big loop back up to here.
EPIC_5:		CALL	GetCharObj
		PUSH	HL
		POP	IY
		LD	A,(IY+$07)
		CP	$84
		JR	NC,DoFire
		XOR	A
		LD	(LA29F),A
		LD	A,(FloorAboveFlag)
		AND	A
		JR	NZ,DoFire
		LD	A,$06
		LD	(LB218),A
	;;  NB: Fall through

	;; Check for Fire being pressed
DoFire:		LD	A,(FirePressed)
		RRA
		JR	NC,NotFire
		LD	A,(Character)
		OR	~2
		INC	A
		LD	HL,SavedObjListIdx
		OR	(HL)
		JR	NZ,NopeFire 	; Skips if not Head (alone) or FIXME
		LD	A,(Inventory)
		OR	~6
		INC	A
		JR	NZ,NopeFire 	; Skips if don't have donuts and a hooter
		LD	A,(FiredObj+$0F)
		CP	$08
		JR	NZ,NopeFire 	; Skips if not FIXME
		LD	HL,HeadObj+$05
		LD	DE,FiredObj+$05
		LD	BC,L0003
		LDIR			; Copies X/Y/Z coordinate from Head.
		LD	HL,FiredObj
		PUSH	HL
		POP	IY		; Sets IY to FiredObj
	;; Set initial phase and object function
		LD	A,(Phase)
		OR	$19		; ObjFnFire
		LD	(FiredObj+$0A),A
	;; FIXME: Initialise other fields...
		LD	(IY+$04),$00
		LD	A,(LA2BB)
		LD	(FiredObj+$0B),A
		LD	(IY+$0C),$FF
		LD	(IY+$0F),$20
		CALL	EnlistAux
	;; Use up a donut
		LD	A,$06
		CALL	DecCount
		LD	B,$48
		CALL	PlaySound
		LD	A,(Donuts)
		AND	A
		JR	NZ,NotFire
		LD	HL,Inventory
		RES	2,(HL)			; Run out of donuts
		CALL	DrawScreenPeriphery
		JR	NotFire
NopeFire:	CALL	NopeNoise
	;; Next section?
NotFire:	LD	HL,LB218
		LD	A,(HL)
		AND	$7F
		RET	Z
		LD	A,(LB219)
		AND	A
		JR	Z,EPIC_9
		LD	(HL),$00
		RET
EPIC_9:		LD	A,(LA295)
		AND	A
		JR	Z,EPIC_12
		CALL	GetCharObj
		PUSH	HL
		POP	IY
		CALL	Unlink
		LD	A,(Character)
		CP	$03
		JR	Z,EPIC_12
		LD	HL,LA2A6
		CP	(HL)
		JR	Z,EPIC_10
		XOR	$03
		LD	(HL),A
		JR	EPIC_11
EPIC_10:	LD	HL,LFB49
		LD	DE,LA2A2
		LD	BC,L0005
		LDIR
EPIC_11:	LD	HL,L0000
		LD	(LA2CD),HL
		LD	(LA2DF),HL
		CALL	C72A0
EPIC_12:	LD	HL,L0000
		LD	(Carrying),HL
		JP	L70BA
EPIC_13:	DEC	(HL)
		LD	HL,(Character)
		JP	CharThing18 		; NB: Tail call
EPIC_14:	DEC	(HL)
		LD	HL,(Character)
		JP	NZ,CharThing19 		; NB: Tail call
		LD	A,$07
		LD	(LB218),A
		JP	EPIC_5

	;; TODO: Almost certainly, "die"
;; HL holds LB219
HandleDeath:	DEC	(HL)                    ; ??
		JP	NZ,CharThing20 		; NB: Tail call
        ;; Drop what you're carrying.
		LD	HL,$0000
		LD	(Carrying),HL
        ;; Decrement lives counters.
		LD	HL,Lives
		LD	BC,(Dying)
		LD	B,$02   ; Run over both characters..
		LD	D,$FF   ; D is set to $FF
HD_1:		RR	C
		JR	NC,HD_2 ; Skip if C bit not set.
		LD	A,(HL)  ; Decrement lives counter.
		SUB	$01
		DAA
		LD	(HL),A
		JR	NZ,HD_2
		LD	D,$00   ; D updated to $00 if any lives reduced.
HD_2:		INC	HL
		DJNZ	HD_1
        ;; If no lives left, game over.
		DEC	HL
		LD	A,(HL)
		DEC	HL
		OR	(HL)
		JP	Z,FinishGame
        ;; No lives lost, then skip to the end.
		LD	A,D
		AND	A
		JR	NZ,HD_9
        ;; FIXME: Messy below here.
		LD	HL,Lives
		LD	A,(LA295)
		AND	A
		JR	Z,HD_6
		LD	A,(LA2A6)
		CP	$03
		JR	NZ,HD_4
        ;; LA2A6 = Lives != 0 ? 1 : 2
		LD	A,(HL)
		AND	A
		LD	A,$01
		JR	NZ,HD_3
		INC	A
HD_3:		LD	(LA2A6),A
		JR	HD_9
        ;; 
HD_4:		RRA
		JR	C,HD_5
		INC	HL
HD_5:		LD	A,(HL)
		AND	A
		JR	NZ,HD_8
		LD	(LA295),A
HD_6:		CALL	SwitchChar
		LD	HL,L0000
		LD	(LB219),HL
HD_7:		LD	HL,LFB28
		SET	0,(HL)
		RET
HD_8:		CALL	HD_7
        ;; 
HD_9:		LD	A,(LA2A6)
		LD	(Character),A
		CALL	CharThing3
        ;; Restore the UVZ position of the character as we enter the room.
		CALL	GetCharObj
		LD	DE,L0005
		ADD	HL,DE
		EX	DE,HL
		LD	HL,EntryPosn
		LD	BC,L0003
		LDIR
        ;; TODO: Restore something, jump somewhere.
		LD	A,(LA2A2)
		LD	(LB218),A
		JP	L70E6

CharThing18:	PUSH	HL
		LD	HL,LA30A
		JR	CharThing21 		; NB: Tail call
	
CharThing20:	LD	HL,(Dying)
	;; NB: Fall through
	
CharThing19:	PUSH	HL
		LD	HL,LA2FC
	;; NB: Fall through

CharThing21:	LD	IY,HeelsObj
		CALL	C8CF0
		POP	HL
		PUSH	HL
		BIT	1,L
		JR	Z,EPIC_29
		PUSH	AF
		LD	(LA2DA),A
		RES	3,(IY+$16)
		LD	HL,HeadObj
		CALL	StoreObjExtents
		LD	HL,HeadObj
		CALL	UnionAndDraw
		POP	AF
EPIC_29:	POP	HL
		RR	L
		RET	NC
		XOR	$80
		LD	(LA2C8),A
		RES	3,(IY+$04)
		LD	HL,HeelsObj
		CALL	StoreObjExtents
		LD	HL,HeelsObj
		JP	UnionAndDraw			; NB: Tail call

        ;; Put bit 0 of A into bit 2 of SwopPressed
CharThing3:	AND	$01
		RLCA
		RLCA
		LD	HL,SwopPressed
		RES	2,(HL)
		OR	(HL)
		LD	(HL),A
		RET

	;; Looks like more movement stuff
CharThing4:	CALL	GetCharObj
		PUSH	HL
		POP	IY
		LD	A,$3F
		LD	(OtherSoundId),A
		LD	A,(SavedObjListIdx)
		CALL	SetObjList
		CALL	GetCharObj
		CALL	StoreObjExtents
		LD	HL,LA29F
		LD	A,(HL)
		AND	A
		JR	Z,EPIC_37
		LD	A,(SavedObjListIdx)
		AND	A
		JR	Z,EPIC_31
		LD	(HL),$00
		JR	EPIC_37
EPIC_31:	DEC	(HL)
		CALL	GetCharObj
		CALL	CAC41
		JR	C,EPIC_32
		DEC	(IY+$07)
		LD	A,$84
		CALL	SetOtherSound
		JR	EPIC_33
EPIC_32:	EX	AF,AF'
		LD	A,$88
		BIT	4,(IY+$0B)
		SET	4,(IY+$0B)
		CALL	Z,SetOtherSound
		EX	AF,AF'
		JR	Z,EPIC_34
EPIC_33:	RES	4,(IY+$0B)
		SET	5,(IY+$0B)
		DEC	(IY+$07)
EPIC_34:	LD	A,(Character)
		AND	$02
		JR	NZ,EPIC_36
EPIC_35:	LD	A,(LA2BB)
		JP	EPIC_43
EPIC_36:	LD	A,(CurrDir)
		RRA
		CALL	LookupDir
		INC	A
		JP	NZ,EPIC_42
		JR	EPIC_35
EPIC_37:	SET	4,(IY+$0B)
		SET	5,(IY+$0C)
		CALL	GetCharObj
		LD	A,(LB218)
		AND	A
		JR	NZ,EPIC_38
		CALL	CAA74
		JP	NC,CharThing23 		; NB: Tail call
		JP	NZ,CharThing22		; NB: Tail call
EPIC_38:	LD	A,(LB218)
		RLA
		JR	NC,EPIC_39
		LD	(IY+$0C),$FF
EPIC_39:	LD	A,$86
		BIT	5,(IY+$0B)
		SET	5,(IY+$0B)
		CALL	Z,SetOtherSound 		; NB: Tail call
		BIT	4,(IY+$0C)
		SET	4,(IY+$0C)
		JR	NZ,EPIC_41
		CALL	GetCharObj
		CALL	CAC41
		JR	NC,EPIC_40
		JR	NZ,EPIC_40
		LD	A,$88
		CALL	SetOtherSound
		JR	EPIC_41
EPIC_40:	DEC	(IY+$07)
		RES	4,(IY+$0B)
EPIC_41:	XOR	A
		LD	(LA29E),A
		CALL	DoCarry
		CALL	DoJump
EPIC_42:	LD	A,(CurrDir)
		RRA
EPIC_43:	CALL	MoveChar
		CALL	CharThing6
		EX	AF,AF'
		LD	A,(LA2A0)
		INC	A
		JR	NZ,EPIC_46
		XOR	A
		LD	HL,Character
		BIT	0,(HL)
		JR	Z,EPIC_44
		LD	(LA2E4),A
		LD	(LA2EA),A
EPIC_44:	BIT	1,(HL)
		JR	Z,EPIC_45
		LD	(LA2F0),A
		LD	(LA2F6),A
EPIC_45:	EX	AF,AF'
		LD	BC,L1B21
		JR	C,EPIC_50
		CALL	CharThing5
		LD	BC,L181F
		JR	EPIC_50
EPIC_46:	EX	AF,AF'
		LD	HL,LA2E4
		LD	DE,LA2F0
		JR	NC,EPIC_47
		LD	HL,LA2EA
		LD	DE,LA2F6
EPIC_47:	PUSH	DE
		LD	A,(Character)
		RRA
		JR	NC,EPIC_48
		CALL	C8CF0
		LD	(LA2C8),A
EPIC_48:	POP	HL
		LD	A,(Character)
		AND	$02
		JR	Z,EPIC_49
		CALL	C8CF0
		LD	(LA2DA),A
EPIC_49:	SET	5,(IY+$0B)
		JR	CharThing26
EPIC_50:	SET	5,(IY+$0B)
	;; NB: Fall through

CharThing25:	LD	A,(Character)
		RRA
		JR	NC,EPIC_52
		LD	(IY+$08),B
EPIC_52:	LD	A,(Character)
		AND	$02
		JR	Z,CharThing26 		; NB: Tail call
		LD	A,C
		LD	(LA2DA),A
	;; NB: Fall through
	
CharThing26:	LD	A,(Movement)
		LD	(IY+$0C),A
		CALL	GetCharObj
		CALL	Relink
		CALL	SaveObjListIdx
		XOR	A
		CALL	SetObjList 		; Switch to default object list
		CALL	GetCharObj
		CALL	UnionAndDraw
		JP	PlayOtherSound 		; NB: Tail call
	
CharThing5:	LD	HL,LA315
		DEC	(HL)
		LD	A,$03
		SUB	(HL)
		RET	C
		JR	Z,EPIC_55
		CP	$03
		RET	NZ
		LD	(HL),$40
EPIC_55:	JP	WiggleEyebrows
	
CharThing22:	LD	HL,LA29E
		LD	A,(HL)
		AND	A
		LD	(HL),$FF
		JR	Z,CharThing24 		; NB: Tail call
		CALL	DoCarry
		CALL	DoJump
		XOR	A
		JR	CharThing24 		; NB: Tail call
	
CharThing23:	XOR	A
		LD	(LA29E),A
		INC	A
	;; NB: Fall through
CharThing24:	LD	C,A
		CALL	ResetTickTock
		RES	5,(IY+$0B)
		LD	A,(Character)
		AND	$02
		JR	NZ,EPIC_59
		DEC	C
		JR	NZ,EPIC_60
		INC	(IY+$07)
EPIC_59:	INC	(IY+$07)
		AND	A
		JR	NZ,EPIC_61
		LD	A,$82
		CALL	SetOtherSound
		LD	HL,LA293
		LD	A,(HL)
		AND	A
		JR	Z,EPIC_63
		DEC	(HL)
		LD	A,(LA2BB)
		JR	EPIC_62
EPIC_60:	INC	(IY+$07)
EPIC_61:	LD	A,$83
		CALL	SetOtherSound
		LD	A,(CurrDir)
		RRA
EPIC_62:	CALL	MoveChar
EPIC_63:	CALL	CharThing6
		LD	BC,L1B21
		JP	C,CharThing25
		LD	BC,L184D
		JP	CharThing25

CharThing6:	LD	A,(LA2BB)
		CALL	LookupDir
		RRA
		RES	4,(IY+$04)
		RRA
		JR	C,EPIC_65
		SET	4,(IY+$04)
EPIC_65:	RRA
		RET


;; Move the character.
MoveChar:	OR	$F0
		CP	$FF
		LD	(LA2A0),A
		JR	Z,MC_1
		EX	AF,AF'
		XOR	A
		LD	(LA2A0),A
		LD	A,$80
		CALL	SetOtherSound
		EX	AF,AF'
		LD	HL,LA2BB
		CP	(HL)
		LD	(HL),A
		JR	Z,MC_2
MC_1:		CALL	ResetTickTock
		LD	A,$FF
MC_2:		PUSH	AF
		AND	A,(IY+$0C)
		CALL	LookupDir
		CP	$FF
		JR	Z,MC_3
		CALL	GetCharObj
		CALL	Move	
		JR	NC,MC_5
		LD	A,(IY+$0B)
		OR	$F0
		INC	A
		LD	A,$88
		CALL	NZ,SetOtherSound
MC_3:		POP	AF
		LD	A,(IY+$0B)
		OR	$0F
		LD	(IY+$0B),A
		RET
        ;; Direction bitmask is on stack. "Move" has been called.
        ;; Update position and do the speed-related movement when when
        ;; TickTock hits zero.
MC_5:           CALL    GetCharObj
                CALL    UpdatePos
                POP     BC
                LD      HL,TickTock
                LD      A,(HL)
                AND     A
                JR      Z,MC_6
                DEC     (HL)
                RET
        ;; Do a bit more movement if we're Heels or have speed.
        ;; Direction bitmask is in B
MC_6:           LD      HL,Speed ; We're fast if we have Speed or are Heels...
                LD      A,(Character)
                AND     $01
                OR      (HL)
                RET     Z
        ;; Deal with speed counter every other time
                LD      HL,SpeedModulo
                DEC     (HL)
                PUSH    BC
                JR      NZ,MC_7
                LD      (HL),$02
                LD      A,(Character)
                RRA
                JR      C,MC_7
        ;; Use up speed if heels not present
                LD      A,$00
                CALL    DecCount
        ;; Do the sound bit...
MC_7:           LD      A,$81
                CALL    SetOtherSound
        ;; Convert bitmap to direction.
                POP     AF
                CALL    LookupDir
        ;; Return if not moving...
                CP      $FF
                RET     Z
        ;; And do a bit of movement.
                CALL    GetCharObj
                PUSH    HL
                CALL    Move
                POP     HL
                JP      NC,UpdatePos
        ;; Failing to move...
                LD      A,$88
                JP      SetOtherSound   ; NB: Tail call

;; The TickTock counter cycles down from 2. Reset it.
ResetTickTock:  LD      A,$02
                LD      (TickTock),A
                RET


	
DoJump:		LD	A,(Character)
	;; Zero LA293 if it's Heels
		LD	B,A
		DEC	A
		JR	NZ,DJ_1
		XOR	A
		LD	(LA293),A
DJ_1:		LD	A,(SavedObjListIdx)
		AND	A
		RET	NZ
	;; Return if jump not pressed.
		LD	A,(CurrDir)
		RRA
		RET	C
	;; Jump button handling case
		LD	C,$00
		LD	L,(IY+$0D)
		LD	H,(IY+$0E)
		LD	A,H
		OR	L
		JR	Z,DJ_5
		PUSH	HL
		POP	IX
		BIT	0,(IX+$09)
		JR	Z,DJ_3
		LD	A,(IX+$0B)
		OR	$CF
		INC	A
		RET	NZ
DJ_3:		LD	A,(IX+$08)
		AND	$7F
		CP	$57
		JR	Z,DJ_10
		CP	$2B
		JR	Z,DJ_4
		CP	$2C
		JR	NZ,DJ_5
DJ_4:		INC	C
DJ_5:		LD	A,(Character)
		AND	$02
		JR	NZ,DJ_6
	;; No Head - use up a spring
		PUSH	BC
		LD	A,$01
		CALL	DecCount
		POP	BC
		JR	Z,DJ_7
	;;  Head
DJ_6:		INC	C
DJ_7:		LD	A,C
		ADD	A,A
		ADD	A,A
		ADD	A,$04
		CP	$0C
		JR	NZ,DJ_8
		LD	A,$0A
DJ_8:		LD	(LA29F),A
		LD	A,$85
		DEC	B
		JR	NZ,DJ_9
		LD	HL,LA293
		LD	(HL),$07
DJ_9:		JP	SetOtherSound 	; NB: Tail call
DJ_10:		LD	HL,L080C
		LD	(LA296),HL
		LD	B,$C7
		JP	PlaySound


	;; Position where the contents being carried are drawn.
CARRY_POSN:	EQU	216 << 8 | 176
	
DoCarry:	LD	A,(CarryPressed)
		RRA
		RET	NC
		LD	A,(Inventory) 		; Check if we have the purse
		RRA
PurseNope:	JP	NC,NopeNoise 		; Tail call
		LD	A,(Character)
		AND	$01
		JR	Z,PurseNope 		; Check if heels is present
		LD	A,$87			; FIXME: ???
		CALL	SetOtherSound
		LD	A,(Carrying+1)
		AND	A
		JR	NZ,DropCarried 		; If holding something, drop it
		CALL	GetCharObj
		CALL	GetStoodUpon
		JR	NC,PurseNope		; NC if nothing there
		LD	A,(IX+$08)		; Load sprite of thing carried
		PUSH	HL
		LD	(Carrying),HL 		; Save carried thing
		LD	BC,CARRY_POSN
		PUSH	AF
		CALL	Draw3x24 		; Draw the item now carried
		POP	AF
		POP	HL
		JP	RemoveObject		; Tail call
DropCarried:	LD	A,(SavedObjListIdx)
		AND	A
		JP	NZ,NopeNoise 		; FIXME: Can't drop if ???
		LD	C,(IY+$07)
		LD	B,$03
CarryLoop:	CALL	GetCharObj
		PUSH	BC
		CALL	CAC41
		POP	BC
		JR	C,NoDrop
		DEC	(IY+$07)
		DEC	(IY+$07)
		DJNZ	CarryLoop
	;; FIXME: That was some other test...
		LD	HL,(Carrying)
		PUSH	HL
		LD	DE,L0007
		ADD	HL,DE
		PUSH	HL
		CALL	GetCharObj
		LD	DE,L0006
		ADD	HL,DE
		EX	DE,HL			; CharObj + 6 in DL
		POP	HL			; Object + 7 in HL
		LD	(HL),C			; Overwrite id thing with C...
		EX	DE,HL
		DEC	DE
		LDD
		LDD
		POP	HL
		CALL	InsertObject
		LD	HL,L0000
		LD	(Carrying),HL
		LD	BC,CARRY_POSN
		CALL	Clear3x24 		; Clear out the what's-carried display
		CALL	GetCharObj
		CALL	CAA74
		CALL	GetCharObj
		JP	StoreObjExtents
NoDrop:		LD	(IY+$07),C 		; Restore old value
		JP	NopeNoise		; Tail call

SetSound:	LD	HL,SoundId 	; FIXME: Unused?
		JR	BumpUp

SetOtherSound:	LD	HL,OtherSoundId
	;; Fall through.
        
	;; Sets (HL) to A if A > (HL)
BumpUp:		CP	(HL)
		RET	C
		LD	(HL),A
		RET

PlayOtherSound:	LD	A,(OtherSoundId)
		OR	$80
		LD	B,A
		CP	$85
		JP	NC,PlaySound
		LD	A,(MENU_SOUND)
		AND	A
		RET	NZ
		JP	PlaySound

	;; Get the object data structure associated with the character.
GetCharObj:	LD	HL,Character
		BIT	0,(HL)
		LD	HL,HeelsObj
		RET	NZ
		LD	HL,HeadObj
		RET


	
CharThing15:	XOR	A 	; FIXME: Unused?
		LD	(LA2FC),A
		LD	(LA296),A
		LD	(LA30A),A
		LD	A,$08
		LD	(FiredObj+$0F),A
		CALL	SetCharThing
		LD	A,(Character)
		LD	(LA2A6),A
		CALL	GetCharObj
		PUSH	HL
		PUSH	HL
		PUSH	HL
		POP	IY
		LD	A,(LB218)
		LD	(LA2A2),A
		PUSH	AF
		SUB	$01
		PUSH	AF
		CP	$04
		JR	NC,EPIC_86
		XOR	$01
		LD	E,A
		LD	D,$00
		LD	HL,DoorLocsCopy
		ADD	HL,DE
		LD	C,(HL)
		LD	HL,LAA6E
		ADD	HL,DE
		LD	A,(HasNoWall)
		AND	(HL)
		JR	NZ,EPIC_86
		LD	(IY+$07),C
EPIC_86:	CALL	GetCharObj
		LD	DE,L0005
		ADD	HL,DE
		EX	DE,HL
		POP	AF
		JR	C,EPIC_93
		CP	$06
		JR	Z,EPIC_90
		JR	NC,EPIC_92
		CP	$04
		JR	NC,EPIC_88
		LD	HL,MinU
		LD	C,$FD
		RRA
		JR	NC,EPIC_87
		INC	DE
		INC	HL
EPIC_87:	RRA
		JR	C,EPIC_95
		LD	C,$03
		INC	HL
		INC	HL
		JR	EPIC_95
EPIC_88:	INC	DE
		INC	DE
		RRA
		LD	A,$84
		JR	NC,EPIC_89
		LD	A,(L7B8F)
		AND	A
		LD	A,$BA
		JR	Z,EPIC_89
		LD	A,$B4
EPIC_89:	LD	(DE),A
		POP	AF
		JR	EPIC_97
EPIC_90:	INC	DE
		INC	DE
		LD	A,(L7B8F)
		AND	A
		JR	Z,EPIC_91
		LD	A,(DE)
		SUB	$06
		LD	(DE),A
EPIC_91:	LD	B,$C8
		CALL	PlaySound
		JR	EPIC_96
EPIC_92:	LD	HL,L8ADF
		JR	EPIC_94
EPIC_93:	LD	HL,LAA64
EPIC_94:	LDI
		LDI
		LDI
		JR	EPIC_96
EPIC_95:	LD	A,(HL)
		ADD	A,C
		LD	(DE),A
EPIC_96:	POP	AF
		ADD	A,$67
		LD	L,A
		ADC	A,$AA
		SUB	L
		LD	H,A
		LD	A,(HL)
		LD	(LA2BB),A
EPIC_97:	LD	A,$80
		LD	(LB218),A
		POP	HL
		LD	DE,L0005
		ADD	HL,DE
		LD	DE,EntryPosn
		LD	BC,L0003
		LDIR
		LD	(IY+$0D),$00
		LD	(IY+$0E),$00
		LD	(IY+$0B),$FF
		LD	(IY+$0C),$FF
		POP	HL
		CALL	Enlist
		CALL	SaveObjListIdx
		XOR	A
		LD	(LB219),A
		LD	(Dying),A
		LD	(L7B8F),A
		JP	SetObjList ; Switch to default object list
	
SaveObjListIdx:	LD	A,(ObjListIdx)
		LD	(SavedObjListIdx),A
		RET

	
DrawCarriedObject:	LD	A,(Character)
			LD	HL,LA295
			RRA
			OR	(HL)
			RRA
			RET	NC		; Return if low bit not set on LA295 and not head
			LD	HL,(Carrying)
			INC	H
			DEC	H
			RET	Z		; Return if high byte zero...
			LD	DE,L0008
			ADD	HL,DE
			LD	A,(HL)		; Get sprite from object pointed to...
			LD	BC,CARRY_POSN
			JP	Draw3x24 	; And draw it

LAA64:	DEFB $28,$28,$C0,$FD,$FD,$FB,$FE,$F7,$FD,$FD
LAA6E:	DEFB 08,$04,$02,$01
