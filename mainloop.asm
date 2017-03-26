;;
;;  mainloop.asm
;;
;;  The main game loop and some associated functions
;;

;; Exported functions:
;;  * SetCharThing
;;  * IsSharedRoom
;;  * SetSens
;;  * InVictoryRoom
;;  * NopeNoise
;;  * FirePresed
;;  * GoToRoom
;;  * FinishGame
;;  * SwitchChar
;;  * RoomLongJmp

;; Exported variables:
;;  * RoomId
;;  * Phase
;;  * CurrDir
;;  * CarryPressed
;;  * SwopPressed
;;  * FirePressed
;;  * FrameCounter

;; Main entry point
Entry:          LD      SP,$FFF4
                CALL    InitStuff
                CALL    InitStick
                JR      Main

RoomId:		DEFW $00
Phase:		DEFB $00	; Top bit toggles every DoObjects loop.
LastDir:	DEFB $EF
CurrDir:	DEFB $FF

;; For each of these, bit 1 means 'currently pressed', and bit 0 is
;; 'newly triggered'.
CarryPressed:	DEFB $00
SwopPressed:	DEFB $00
FirePressed:	DEFB $00

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
MainStart:	CALL	CrownScreen
		LD	A,$40
		LD	(ObjFn36Val),A
MainGoRoom:	XOR	A
		LD	(Phase),A
		CALL	EnterRoom2
	;; The main game-playing loop
MainLoop:       CALL    WaitFrame
                CALL    CheckCtrls
                CALL    DoVictoryRoom
                CALL    DoObjects
                CALL    CheckPause
                CALL    CheckSwop
        ;; Play sound if there is one.
                LD      HL,SoundId
                LD      A,(HL)
                SUB     $01
                LD      (HL),$00
                LD      B,A
                CALL    NC,PlaySound
                JR      MainLoop

        ;; Set zero flag if in victory room.
InVictoryRoom:  LD      HL,(RoomId)
                LD      BC,$8D30 ; Victory room
                XOR     A
                SBC     HL,BC
                RET

;; Do special-case stuff associated with being in the victory room.
DoVictoryRoom:
        ;; Return if in victory room.
                CALL    InVictoryRoom
                RET     NZ
        ;; A is $00. No swapping
                LD      (SwopPressed),A
        ;; No movement
                DEC     A
                LD      (CurrDir),A
        ;; ???
                LD      HL,ObjFn36Val
                DEC     (HL)
                LD      A,(HL)
                INC     A
                JP      Z,FinishGame
        ;; Play sound
                LD      B,$C1
                CP      $30
                PUSH    AF
                CALL    Z,PlaySound
        ;; Print message
                POP     AF
                AND     $01
                LD      A,STR_FREEDOM
                CALL    Z,PrintChar
                RET

	;; FIXME: ???
GoToRoom:	LD	HL,RoomId+1
		LD	A,(LB218)
		DEC	A
		CP	$06
		JR	Z,TeleportRoom
		JR	NC,RoomLongJmp
		CP	$04
		JR	C,GTR_1
		ADD	A,A
		XOR	$02
		DEC	HL
GTR_1:		LD	C,$01
		BIT	1,A
		JR	NZ,GTR_2
		LD	C,$FF
GTR_2:		RRA
		JR	C,GTR_3
		RLD
		ADD	A,C
		RRD
		JR	RoomLongJmp
GTR_3:		RRD
		ADD	A,C
		RLD
        ;; NB: Fall through

;; Perform a longjmp to the enter-a-room code.
RoomLongJmp:    LD      SP,$FFF4
                JP      MainGoRoom

TeleportRoom:   CALL    Teleport
                JR      RoomLongJmp

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
		CALL	RevealScreen
		LD	HL,$4C50 ; TODO
CP_2:		PUSH	HL
		LD	DE,$6088 ; TODO
		CALL	CheckAndDraw
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
		LD		A,(SavedObjListIdx)
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
		LD	BC,(CharDir)
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
		LD	(CharDir),A
		LD	A,(LA295)
		AND	A
		JP	NZ,DrawScreenPeriphery
		JR	RestoreStuff

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

;; Returns whether or not we're in the same room as the other character.
IsSharedRoom:	LD	HL,(RoomId)
		LD	DE,(OtherState)
		AND	A
		SBC	HL,DE
		RET

SwitchHelper:	LD	A,(Character)
		LD	HL,L7044
		LD	E,A
		RRA
		RET


SaveStuff:      XOR     A
                JR      CopyStuff2

RestoreStuff2:  LD      A,$FF
                LD      HL,ClearObjLists
                PUSH    HL
        ;; Fall through

CopyStuff2:     LD      HL,HL2DE
                LD      DE,CopyChar
                JR      CopyStuff

RestoreStuff:   XOR     A
                LD      HL,FinishRestore ; Set the function to call after.
                PUSH    HL
                LD      HL,DE2HL
                LD      DE,LoadCharObjs
        ;; Fall through

;; Take the copy function to use in HL, and function to call
;; afterwards in DE. Copies various chunks of data to/from buffer at
;; OtherState.
CopyStuff:      PUSH    DE
                LD      (COD_JP+1),HL
                CALL    GetOtherChar
                LD      (CC_Ptr),HL
                AND     A
                LD      HL,OtherState
                JR      NZ,CS_1
                EX      DE,HL
CS_1:           EX      AF,AF'
                CALL    CopyData
                DEFW    $0004, RoomId
                CALL    CopyData
                DEFW    $001D, ObjListIdx
                CALL    CopyData
                DEFW    $0019, LA2A2
                CALL    CopyData
                DEFW    $03F0, LBA40
                RET

;; Runs CopyData on a character object.
CopyChar:       CALL    CopyData
                DEFW    $0012           ; Size of an object.
CC_Ptr:         DEFW    HeelsObj        ; Self-modifying code
                RET

;; Takes pointer in DE, and copies data out to current character, then
;; the other character.
LoadCharObjs:   PUSH    DE
                CALL    GetCharObj
                EX      DE,HL
                LD      BC,18   ; TODO
                PUSH    BC
                LDIR
                CALL    GetOtherChar
                POP     BC
                POP     DE
                LDIR
        ;; Fall through.

ClearObjLists:  LD      HL,(LAF92)      ; NB: Referenced as data.
                LD      (ObjDest),HL
                LD      HL,ObjectLists + 4
                LD      BC,8    ; TODO
                JP      FillZero

;; Get the character object associated with the one we're not playing now?
GetOtherChar:   LD      HL,Character
                BIT     0,(HL)          ; Heels?
                LD      HL,HeelsObj     ; No Heels case
                RET     Z
                LD      HL,HeadObj      ; Have Heels case
                RET

;; Given a pointer on the stack, load values into C, B, and if A' is
;; non-zero, then E, D, otherwise L, H. Push updated pointer.
;;
;; Then call the currently-selected function, which may be LDIR, or a
;; kind of reverse LDIR (DE to HL).
CopyData:       POP     IX
                LD      C,(IX+$00)
                INC     IX
                LD      B,(IX+$00)
                INC     IX
                EX      AF,AF'
                AND     A
                JR      Z,COD_1
                LD      E,(IX+$00)
                INC     IX
                LD      D,(IX+$00)
                JR      COD_2
COD_1:          LD      L,(IX+$00)
                INC     IX
                LD      H,(IX+$00)
COD_2:          INC     IX
                EX      AF,AF'
                PUSH    IX
COD_JP:         JP      HL2DE           ; Self-modifying code
DE2HL:          LD      A,(DE)
                LDI
                DEC     HL
                LD      (HL),A
                INC     HL
                JP      PE,DE2HL
                RET
HL2DE:          LDIR
                RET
