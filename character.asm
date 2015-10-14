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
	;; C8CD6
	;; C8CF0
	;; C8D7F
	;; DrawScreenPeriphery
	;; CA05D
	;; CA0A5
	;; LA316
	;; CAA74
	;; GetStoodUpon
	;; CAC41
	;; CAF96
	;; CB010
	;; CB03B
	;; CB0BE
	;; CB0C6
	;; LB21C
	
	
	;; Something of an epic function...
	;; Think it involves general movement/firing etc.
CharThing:	LD	A,(LA314)
		RLA
		CALL	C,LA316
		LD	HL,LB219
		LD	A,(HL)
		AND	A
		JR	Z,EPIC_1
		EXX
		LD	HL,Character
		LD	A,(LB21A)
		AND	(HL)
		EXX
		JP	NZ,CharThing2 		; NB: Tail call
		CALL	CharThing2
EPIC_1:		LD	HL,LA296
		LD	A,(HL)
		AND	A
		JP	NZ,EPIC_14
		INC	HL
		OR	(HL)
		JP	NZ,EPIC_13
		LD	HL,LA298
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
		LD	A,$02
		CALL	C,DecCount
		POP	AF
		RRA
		LD	A,$03
		CALL	C,DecCount
EPIC_2:		LD	A,$FF
		LD	(LA2BF),A
		LD	A,(LB218)
		AND	A
		JR	Z,EPIC_4
		LD	A,(LA2BC)
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
		LD	A,(L7712)
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
		LD	HL,LA2BC
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
	;; FIXME: Bunch of mystery...
		LD	A,(L703D)
		OR	$19
		LD	(FiredObj+$0A),A
		LD	(IY+$04),$00
		LD	A,(LA2BB)
		LD	(FiredObj+$0B),A
		LD	(IY+$0C),$FF
		LD	(IY+$0F),$20
		CALL	CB03B
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
		CALL	CB0C6
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

	
CharThing2:	DEC	(HL)
		JP	NZ,CharThing20 		; NB: Tail call
		LD	HL,L0000
		LD	(Carrying),HL
		LD	HL,Lives
		LD	BC,(LB21A)
		LD	B,$02
		LD	D,$FF
EPIC_16:	RR	C
		JR	NC,EPIC_17
		LD	A,(HL)
		SUB	$01
		DAA
		LD	(HL),A
		JR	NZ,EPIC_17
		LD	D,$00
EPIC_17:	INC	HL
		DJNZ	EPIC_16
		DEC	HL
		LD	A,(HL)
		DEC	HL
		OR	(HL)
		JP	Z,FinishGame
		LD	A,D
		AND	A
		JR	NZ,EPIC_24
		LD	HL,Lives
		LD	A,(LA295)
		AND	A
		JR	Z,EPIC_21
		LD	A,(LA2A6)
		CP	$03
		JR	NZ,EPIC_19
		LD	A,(HL)
		AND	A
		LD	A,$01
		JR	NZ,EPIC_18
		INC	A
EPIC_18:	LD	(LA2A6),A
		JR	EPIC_24
EPIC_19:	RRA
		JR	C,EPIC_20
		INC	HL
EPIC_20:	LD	A,(HL)
		AND	A
		JR	NZ,EPIC_23
		LD	(LA295),A
EPIC_21:	CALL	SwitchChar
		LD	HL,L0000
		LD	(LB219),HL
EPIC_22:	LD	HL,LFB28
		SET	0,(HL)
		RET
EPIC_23:	CALL	EPIC_22
EPIC_24:	LD	A,(LA2A6)
		LD	(Character),A
		CALL	CharThing3
		CALL	GetCharObj
		LD	DE,L0005
		ADD	HL,DE
		EX	DE,HL
		LD	HL,LA2A3
		LD	BC,L0003
		LDIR
		LD	A,(LA2A2)
		LD	(LB218),A
		JP	L70E6

CharThing18:	PUSH	HL
		LD	HL,LA30A
		JR	CharThing21 		; NB: Tail call
	
CharThing20:	LD	HL,(LB21A)
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
		CALL	CA05D
		LD	HL,HeadObj
		CALL	CA0A5
		POP	AF
EPIC_29:	POP	HL
		RR	L
		RET	NC
		XOR	$80
		LD	(LA2C8),A
		RES	3,(IY+$04)
		LD	HL,HeelsObj
		CALL	CA05D
		LD	HL,HeelsObj
		JP	CA0A5			; NB: Tail call
	
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
		LD	A,(LA2BC)
		CALL	CAF96
		CALL	GetCharObj
		CALL	CA05D
		LD	HL,LA29F
		LD	A,(HL)
		AND	A
		JR	Z,EPIC_37
		LD	A,(LA2BC)
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
		CALL	CharThing9
EPIC_42:	LD	A,(CurrDir)
		RRA
EPIC_43:	CALL	CharThing7
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
	
CharThing26:	LD	A,(LA2BF)
		LD	(IY+$0C),A
		CALL	GetCharObj
		CALL	CB0BE
		CALL	CharThing16
		XOR	A
		CALL	CAF96
		CALL	GetCharObj
		CALL	CA0A5
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
EPIC_55:	JP	LA316
	
CharThing22:	LD	HL,LA29E
		LD	A,(HL)
		AND	A
		LD	(HL),$FF
		JR	Z,CharThing24 		; NB: Tail call
		CALL	DoCarry
		CALL	CharThing9
		XOR	A
		JR	CharThing24 		; NB: Tail call
	
CharThing23:	XOR	A
		LD	(LA29E),A
		INC	A
	;; NB: Fall through
CharThing24:	LD	C,A
		CALL	CharThing8
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
EPIC_62:	CALL	CharThing7
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


	;; Another character-updating function
CharThing7:	OR	$F0
		CP	$FF
		LD	(LA2A0),A
		JR	Z,EPIC_66
		EX	AF,AF'
		XOR	A
		LD	(LA2A0),A
		LD	A,$80
		CALL	SetOtherSound
		EX	AF,AF'
		LD	HL,LA2BB
		CP	(HL)
		LD	(HL),A
		JR	Z,EPIC_67
EPIC_66:	CALL	CharThing8
		LD	A,$FF
EPIC_67:	PUSH	AF
		AND	A,(IY+$0C)
		CALL	LookupDir
		CP	$FF
		JR	Z,EPIC_68
		CALL	GetCharObj
		CALL	TableCall	
		JR	NC,EPIC_69
		LD	A,(IY+$0B)
		OR	$F0
		INC	A
		LD	A,$88
		CALL	NZ,SetOtherSound
EPIC_68:	POP	AF
		LD	A,(IY+$0B)
		OR	$0F
		LD	(IY+$0B),A
		RET
EPIC_69:	CALL	GetCharObj
		CALL	C8CD6
		POP	BC
		LD	HL,LA2A1
		LD	A,(HL)
		AND	A
		JR	Z,EPIC_70
		DEC	(HL)
		RET
EPIC_70:	LD	HL,Speed ; FIXME: Fast if have Speed or are Heels...
		LD	A,(Character)
		AND	$01
		OR	(HL)
		RET	Z
		LD	HL,LA299
		DEC	(HL)
		PUSH	BC
		JR	NZ,EPIC_71
		LD	(HL),$02
		LD	A,(Character)
		RRA
		JR	C,EPIC_71
		LD	A,$00
		CALL	DecCount
EPIC_71:	LD	A,$81
		CALL	SetOtherSound
		POP	AF
		CALL	LookupDir
		CP	$FF
		RET	Z
		CALL	GetCharObj
		PUSH	HL
		CALL	TableCall
		POP	HL
		JP	NC,C8CD6
		LD	A,$88
		JP	SetOtherSound 	; NB: Tail call
	
CharThing8:	LD	A,$02
		LD	(LA2A1),A
		RET


	
CharThing9:	LD	A,(Character)
		LD	B,A
		DEC	A
		JR	NZ,EPIC_72
		XOR	A
		LD	(LA293),A
EPIC_72:	LD	A,(LA2BC)
		AND	A
		RET	NZ
		LD	A,(CurrDir)
		RRA
		RET	C
		LD	C,$00
		LD	L,(IY+$0D)
		LD	H,(IY+$0E)
		LD	A,H
		OR	L
		JR	Z,EPIC_75
		PUSH	HL
		POP	IX
		BIT	0,(IX+$09)
		JR	Z,EPIC_73
		LD	A,(IX+$0B)
		OR	$CF
		INC	A
		RET	NZ
EPIC_73:	LD	A,(IX+$08)
		AND	$7F
		CP	$57
		JR	Z,EPIC_80
		CP	$2B
		JR	Z,EPIC_74
		CP	$2C
		JR	NZ,EPIC_75
EPIC_74:	INC	C
EPIC_75:	LD	A,(Character)
		AND	$02
		JR	NZ,EPIC_76
		PUSH	BC
		LD	A,$01
		CALL	DecCount
		POP	BC
		JR	Z,EPIC_77
EPIC_76:	INC	C
EPIC_77:	LD	A,C
		ADD	A,A
		ADD	A,A
		ADD	A,$04
		CP	$0C
		JR	NZ,EPIC_78
		LD	A,$0A
EPIC_78:	LD	(LA29F),A
		LD	A,$85
		DEC	B
		JR	NZ,EPIC_79
		LD	HL,LA293
		LD	(HL),$07
EPIC_79:	JP	SetOtherSound 	; NB: Tail call
EPIC_80:	LD	HL,L080C
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
DropCarried:	LD	A,(LA2BC)
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
		JP	CA05D
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
		LD	HL,L7744
		ADD	HL,DE
		LD	C,(HL)
		LD	HL,LAA6E
		ADD	HL,DE
		LD	A,(L7716)
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
		LD	HL,L7718
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
		LD	DE,LA2A3
		LD	BC,L0003
		LDIR
		LD	(IY+$0D),$00
		LD	(IY+$0E),$00
		LD	(IY+$0B),$FF
		LD	(IY+$0C),$FF
		POP	HL
		CALL	CB010
		CALL	CharThing16
		XOR	A
		LD	(LB219),A
		LD	(LB21A),A
		LD	(L7B8F),A
		JP	CAF96
	
CharThing16:	LD	A,(LAF77)
		LD	(LA2BC),A
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
