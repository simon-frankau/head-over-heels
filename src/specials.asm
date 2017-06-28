	;; 
	;; specials.asm
	;;
	;; Counts for lives etc.
	;; 

;; Bit mask of worlds visited.
WorldMask:      DEFB $00

;; Special collectible items
Specials:       DEFB $70,$14,$00,$72,    $60,$30,$01,$40
                DEFB $B0,$2E,$09,$34,    $B0,$00,$1A,$00
                DEFB $F0,$9A,$0B,$70,    $40,$A7,$1C,$44
                DEFB $30,$37,$7D,$37,    $70,$15,$68,$34
                DEFB $60,$89,$48,$47,    $60,$C5,$68,$76
                DEFB $80,$1B,$68,$76,    $D0,$BC,$28,$35
                DEFB $D0,$1C,$28,$71,    $F0,$87,$38,$74
                DEFB $20,$FB,$28,$71,    $60,$31,$48,$05
                DEFB $C0,$E2,$38,$54,    $20,$69,$68,$07
                DEFB $60,$52,$62,$77,    $60,$47,$72,$27
                DEFB $C0,$E3,$42,$07,    $F0,$63,$12,$70
                DEFB $20,$AA,$22,$05,    $30,$6C,$22,$46
                DEFB $60,$47,$73,$57,    $80,$FA,$63,$67
                DEFB $F0,$70,$13,$60,    $10,$7B,$73,$31
                DEFB $60,$64,$74,$70,    $80,$1A,$44,$45
                DEFB $F0,$46,$74,$74,    $60,$C5,$66,$74
                DEFB $70,$98,$76,$00,    $00,$32,$76,$50
                DEFB $80,$29,$76,$40,    $A0,$E0,$16,$40
                DEFB $A0,$0F,$66,$47,    $B0,$03,$26,$44
                DEFB $F0,$83,$36,$17,    $40,$8A,$06,$06
                DEFB $20,$99,$76,$14,    $60,$C5,$65,$75
                DEFB $60,$77,$75,$44,    $00,$36,$75,$66
                DEFB $A0,$FE,$75,$22,    $F0,$42,$65,$61
                DEFB $20,$AE,$75,$04
;; The crown special items.
Crowns:         DEFB $30,$8D,$7E,$47
                DEFB $30,$8D,$6E,$17
                DEFB $30,$8D,$7E,$07
                DEFB $30,$8D,$6E,$37
                DEFB $30,$8D,$3E,$27

;; The sprites associated with special collectible objects.
SpecialSprites: DEFB SPR_PURSE,SPR_HOOTER,SPR_DONUTS,SPR_BUNNY
                DEFB SPR_BUNNY,SPR_BUNNY,SPR_BUNNY,$00
                DEFB ANIM_FISH,SPR_CROWN,SPR_CROWN,SPR_CROWN
                DEFB SPR_CROWN,SPR_CROWN,SPR_CROWN ; One excess crown?

FindSpecials2:  LD      BC,(RoomId)

FindSpecials:   LD      HL,Specials
                LD      E,$34           ; # of special items
        ;; Try to find the room id we want, looping by skipping 2
        ;; bytes (plus the 2 room id bytes) each time.
        ;;
        ;; Remaining count in E, room id in BC, search point in HL.
        ;; Returns with Z flag set if found, pointer in HL.
FindSpecLoop:   LD      A,C
                CP      (HL)
                INC     HL
                JR      NZ,FindSpecCont
                LD      A,B
                CP      (HL)
                RET     Z       ; Found!
        ;; NB: Entry point in the middle to continue loop
FindSpecCont:   INC     HL
                INC     HL
                INC     HL
                DEC     E
                JR      NZ,FindSpecLoop
                DEC     E
FindSpecRet:    RET             ; Looks like an arbitrary 'ret'.

;; Takes a pointer in HL, and extracts the nybbles.
GetNybbles:     INC     HL
                XOR     A
                RLD
                LD      E,A     ; E gets high 4 bits of *(HL+1).
                RLD
                LD      D,A     ; D gets next 4 bits of *(HL+1).
                RLD
                INC     HL
                RLD
                LD      B,A     ; B gets high 4 bits of *(HL+2).
                RLD
                LD      C,A     ; C gets next 4 bits of *(HL+2).
                RLD
                RET

;; Adds all the special collectible items to the room.
;;
;; Takes room id in BC
AddSpecials:    PUSH    BC
        ;; TODO: Tweak some room list entries (?) from WorldMask?
                LD      HL,Crowns
                LD      A,(WorldMask)
                CPL
                LD      B,$05
                LD      DE,4
AS_1:           RR      (HL)
                RRA
                RL      (HL)
                ADD     HL,DE
                DJNZ    AS_1
        ;; Then, look up the room id.
                POP     BC
                CALL    FindSpecials
AS_2:           RET     NZ              ; If not found, return.
        ;; Found. Save the state so we can search some more, as there
        ;; can be multiple entries per room.
                PUSH    HL
                PUSH    DE
                PUSH    BC
                PUSH    IY
        ;; And construct some extra objects.
                CALL    GetNybbles      ; Fills in E, D, B, C
                LD      IY,TmpObj
                LD      A,D
                CP      $0E
                LD      A,$60
                JR      NZ,AS_3
                XOR     A
AS_3:           LD      (IY+$04),A              ; Set flags
                LD      (IY+$11),D              ; Set special id.
                LD      (IY+$0A),OBJFN_26       ; Set the object function
        ;; Look up D in SpecialSprites to get a sprite id, and set it.
                LD      A,D
                ADD     A,SpecialSprites & $FF
                LD      L,A
                ADC     A,SpecialSprites >> 8
                SUB     L
                LD      H,A
                LD      A,(HL)
                PUSH    BC
                PUSH    DE
                CALL    SetObjSprite
                POP     DE
                POP     BC
        ;; Set position based on B, C and E
                POP     IY
                LD      A,E
                CALL    SetTmpObjUVZ
                CALL    AddObjOpt
        ;; Restore state and carry on.
                POP     BC
                POP     DE
                POP     HL
                CALL    FindSpecCont
                JR      AS_2

        ;; Clear the "collected" flag on all the specials.
ResetSpecials:  LD      HL,Specials
                LD      DE,4
                LD      B,$34
RS_1:           RES     0,(HL)
                ADD     HL,DE
                DJNZ    RS_1
                RET

        ;; Get a special item. Id in A
GetSpecial:     LD      D,A
                CALL    FindSpecials2
        ;; Return if not found.
GSP_1:          RET     NZ
                INC     HL
        ;; Extract second nybble, compare to D.
                LD      A,(HL)
                DEC     HL
                AND     $0F
                CP      D
                JR      Z,GSP_2
        ;; Not the one we wanted? Loop.
                CALL    FindSpecCont
                JR      GSP_1
        ;; Found!
GSP_2:          DEC     HL
        ;; Mark bit 0 of the location second location byte, so that
        ;; this entry is hidden from future searches.
                SET     0,(HL)
        ;; Look up the special in a table
                ADD     A,A
                ADD     A,SpecialFns & $FF
                LD      L,A
                ADC     A,SpecialFns >> 8
                SUB     L
                LD      H,A
                LD      E,(HL)
                INC     HL
                LD      H,(HL)
                LD      L,E
        ;; Set IX to a continuation function (?), and off we go.
                LD      IX,GSPRet
                JP      (HL)

GSPRet:         LD      B,$C5 ; Self-modifying code?
                JP      PlaySound ; TODO: Sound?

 ;; Array of function pointers for actions when picking up a special.
SpecialFns      ;; Purse, hooter, donuts, bunny
                DEFW PickUp2, PickUp2, BoostDonuts, BoostSpeed
                ;; bunny, bunny, bunny, $00
                DEFW BoostSpring, BoostInvuln, BoostLives, $0000
                ;; fish, crown, crown, crown
                DEFW SaveContinue, GetCrown, GetCrown, GetCrown
                ;; crown, crown
                DEFW GetCrown, GetCrown

PickUp2:        LD      A,D
        ;; NB: Fall through

        ;; Pick up an inventory item. Item number in A.
PickUp:         LD      HL,Inventory
                CALL    SetBit
                CALL    DrawScreenPeriphery
                LD      B,$C2           ; Hornpipe
                JP      PlaySound

BoostDonuts:    LD      A,(Character)
                AND     $02
                RET     Z               ; Must be Head
                LD      A,CNT_DONUTS
                CALL    BoostCountPlus
                LD      A,$02           ; Pick up donuts
                JR      PickUp

BoostSpeed:     LD      A,(Character)
                AND     $02             ; Must be Head
                RET     Z
                XOR     A               ; Sets to CNT_SPEED
                JR      BoostCountPlus

BoostSpring:    LD      A,(Character)
                AND     $01             ; Must be Heels
                RET     Z
                JR      BoostCountPlus  ; $01 = CNT_SPRING

BoostInvuln2:   LD      IX,FindSpecRet  ; Set the "plus" call to do nothing.
BoostInvuln:    LD      C,CNT_HEELS_INVULN
                JR      BoostMaybeDbl

BoostLives:     LD      C,CNT_HEELS_LIVES
        ;; NB: Fall through

;; Boosts both characters counts if they're joined. Only works for
;; invuln and lives.
BoostMaybeDbl:  LD      A,(Character)
                CP      $03             ; Head and Heels?
                JR      Z,BoostCountDbl ; Then increment both
                RRA
                AND     $01             ; If Head, add 1
                ADD     A,C
                JR      BoostCountPlus

        ;; Boosts two subsequent counts. For use when Head and Heels are joined.
BoostCountDbl:  LD      A,C
                PUSH    AF
                CALL    BoostCount
                POP     AF
                INC     A
        ;; NB: Fall through

        ;; FIXME: Does some other thing before boosting the count.
BoostCountPlus: PUSH    AF
                CALL    JpIX
                POP     AF
        ;; NB: Fall through

;; Boosts whichever count index is provided in A, and displays it.
BoostCount:     CALL    GetCountAddr
                CALL    AddBCD
        ;; NB: Fall through

;; Number to print in A, location in C.
ShowNum:        PUSH    AF
                PUSH    BC
                AND     A
                LD      A,CTRL_ATTR1            ; When printing 0
                JR      Z,SN_1
                LD      A,CTRL_ATTR3            ; Otherwise
SN_1:           CALL    PrintChar
                POP     BC
                LD      A,C
                ADD     A,CTRL_POS_LIGHTNING    ; Position indexed into array...
                CALL    PrintChar
                POP     AF
                JP      Print2DigitsR           ; Tail call

GetCrown:	LD	A,D
		SUB	$09
		LD	HL,WorldMask
		CALL	SetBit
		LD	B,$C1                   ; Tada! noise
		CALL	PlaySound
		JP	CrownScreenCont         ; NB: Tail call

	;; FIXME: Decode!
SaveContinue:	LD	B,$C2                   ; Hornpipe noise
		CALL	PlaySound
		CALL	GetContinueData
		LD	IX,Specials
		LD	DE,4
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
		LD	BC,4
		LDIR
		LD	HL,OtherState
		JR	SC_4
SC_3:		LD	HL,LA2A2
		LD	BC,4
		LDIR
		LD	HL,RoomId
SC_4:		LDI
		LDI
		LD	HL,RoomId
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
		LD	(WorldMask),A
		PUSH	HL
		POP	IX
		LD	HL,Specials
		LD	DE,4
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
		LD	DE,NextRoom
		LDI
		BIT	0,A
		LD	DE,LA2C5
		JR	Z,DC_4
		LD	DE,LA2D7
DC_4:		LD	BC,3
		LDIR
		LD	DE,RoomId
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
		LD	(OtherState),A
		PUSH	HL
		CALL	InitThings
		POP	HL
DC_5:		LD	DE,RoomId
		LDI
		LDI
		LD	BC,(RoomId)
		SET	0,C
		CALL	FindSpecials
		CALL	GetNybbles
		LD	A,E
		EX	AF,AF'
		LD	DE,L8ADF
		LD	HL,L8ADC
		CALL	SetUVZ
		LD	A,$08
		LD	(NextRoom),A
		LD	(LA297),A
		RET

	;; Returns a pointer to the slot for continue data in HL.
GetContinueData:LD	A,(Continues)
		LD	B,A
		INC	B
		LD	HL,ContinueData - $12
		LD	DE,18 ; TODO: Char obj size
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
AddBCD:         ADD     A,(HL)
                DAA
                LD      (HL),A
                RET     NC
                LD      A,$99
                LD      (HL),A
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
;; If NextRoom is non-zero, return 3 as the increment.
GetCountAddr:   LD      C,A
                LD      B,$00
                LD      HL,DefCounts
                ADD     HL,BC
                LD      A,(NextRoom)
                AND     A
                LD      A,(HL)
                JR      Z,GCA_1
                LD      A,$03
GCA_1:          LD      HL,Speed        ; Points to start of array of counts
                ADD     HL,BC
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
