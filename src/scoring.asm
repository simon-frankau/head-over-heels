
L8ADC:	DEFB $00,$00
L8ADE:	DEFB $00
L8ADF:	DEFB $00,$00,$00

NUM_ROOMS:      EQU 301
;; Strangely, despite being bit-packed, one byte is preserved per room.
RoomMask:       DEFS NUM_ROOMS, $00

;; Clear donut count and then count number of inventory items we have
EmptyDonuts:    LD      HL,Inventory
                RES     2,(HL)
ED1:            EXX
                LD      BC,1
                JR      CountBits

WorldCount:     LD      HL,WorldMask ; FIXME: Possibly actually crowns...
                JR      ED1

RoomCount:      LD      HL,RoomMask
                EXX
                LD      BC,301
        ;; NB: Fall through

;; Counts #bits set in BC bytes starting at HL', returning them in DE.
;; Count is given in BCD.
CountBits:      EXX
                LD      DE,0
                EXX
        ;; Outer loop
CB1:            EXX
                LD      C,(HL)
        ;; Run inner loop 8 times?
                SCF
                RL      C
CB2:
        ;; BCD-normalise E
                LD      A,E
                ADC     A,$00
                DAA
                LD      E,A
        ;; BCD-normalise D
                LD      A,D
                ADC     A,$00
                DAA
                LD      D,A
        ;; And loop...
                SLA     C
                JR      NZ,CB2
        ;; So, I think we just added bit population of (HL') into DE'.
                INC     HL
                EXX
                DEC     BC
                LD      A,B
                OR      C
                JR      NZ,CB1
        ;; And do the same for the rest of the BC entries...
                EXX
                RET

InitNewGame1:	LD	HL,RoomMask
		LD	BC,NUM_ROOMS
		JP	FillZero

        ;; Gets the score and puts it in HL
GetScore:	CALL	InVictoryRoom 		; Zero set if end reached.
		PUSH	AF
		CALL	RoomCount
		POP	AF
		LD	HL,0
		JR	NZ,GS_1
		LD	HL,$0501
		LD	A,(InSameRoom) 	; TODO: Non-zero gets you points.
		AND	A
		JR	Z,GS_1
		LD	HL,$1002
GS_1:		LD	BC,16
		CALL	MulAccBCD
        ;; 500 points per inventory item.
		PUSH	HL
		CALL	EmptyDonuts ; Alternatively, score inventory minus donuts?
		POP	HL
		LD	BC,500
		CALL	MulAccBCD
        ;; Add score for each world - 636 per world.
		PUSH	HL
		CALL	WorldCount
		POP	HL
		LD	BC,636
        ;; NB: Fall through.

        ;; HL += DE * BC. HL and DE are in BCD. BC is not.
MulAccBCD:      LD      A,E
                ADD     A,L
                DAA
                LD      L,A
                LD      A,H
                ADC     A,D
                DAA
                LD      H,A
                DEC     BC
                LD      A,B
                OR      C
                JR      NZ,MulAccBCD
                RET
