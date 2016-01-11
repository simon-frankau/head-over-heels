;;
;; procdata.asm
;;
;; Functions that largely decode the packed room data
;;

;; Exported functions:
;;  * EnterRoom
;;  * SetTmpObjUVZ
;;  * SetUVZ
;;  * ProcTmpObj
;;  * SomeExport

;; Calls into:
;;  * C7358
;; (and maybe some more)

;; FIXME: Called lots. Suspect it forms the backbone of loading a
;; screen or something? Reads all the packed data.
;; Takes something in HL and BC and IY

;; Takes room id in BC
EnterRoom:	LD	(L76E0),HL
		XOR	A
		LD	(L76E2),A
		PUSH	BC
		CALL	FindVisitRoom
		LD	B,$03
		CALL	FetchData
		LD	(L7710),A
        ;; Load HL with L7724 + 4 * A
		ADD	A,A
		ADD	A,A
		ADD	A,L7724 & $FF
		LD	L,A
		ADC	A,L7724 >> 8
		SUB	L
		LD	H,A
        ;; Loop twice...
		LD	B,$02
		LD	IX,L76E0
ER1:		LD	C,(HL)
		LD	A,(IX+$00)
		AND	A
		JR	Z,ER2
		SUB	C
		LD	E,A
		RRA
		RRA
		RRA
		AND	$1F
		LD	(IX+$00),A
		LD	A,E
ER2:		ADD	A,C
		LD	(IY+$00),A
		INC	HL
		INC	IX
		INC	IY
		DJNZ	ER1
	;; Do this bit twice:
		LD	B,$02
ER3:		LD	A,(IX-$02)
		ADD	A,A
		ADD	A,A
		ADD	A,A
		ADD	A,(HL)
		LD	(IY+$00),A
		INC	IY
		INC	IX
		INC	HL
		DJNZ	ER3
	;; Now update some stuff off FetchData:
		LD	B,$03
		CALL	FetchData
		LD	(AttribScheme),A	; Fetch the attribute scheme to use.
		LD	B,$03
		CALL	FetchData
		LD	(WorldId),A 		; Fetch the current world identifier
		CALL	BPDSubB
		LD	B,$03
		CALL	FetchData
		LD	(FloorCode),A 		; And the floor pattern to use
		CALL	SetFloorAddr
	;; FIXME
ER4:		CALL	ProcEntry
		JR	NC,ER4
		POP	BC
		JP	BPDEnd 		; NB: Tail call.

;; Add a signed 3-bit value in A to (HL), result in A
Add3Bit:        BIT     2,A
                JR      Z,A3B
                OR      $F8
A3B:            ADD     A,(HL)
                RET

;; Recursively do ProcEntry
RecProcEntry:   EX      AF,AF'
        ;; When processing recursively, we read 3 values to adjust the
        ;; origin for the macro-expanded processing, so it can be played
        ;; at whatever offset you like.
        ;;
        ;; Read values into B, C, A
                CALL    FetchData333
                LD      HL,(DecodeOrgPtr)
                PUSH    AF
                LD      A,B             ; Adjust U value
                CALL    Add3Bit
                LD      B,A
                INC     HL
                LD      A,C             ; Adjust V value
                CALL    Add3Bit
                LD      C,A
                INC     HL
                POP     AF
                SUB     $07
                ADD     A,(HL)          ; Adjust Z value (slightly different)
                INC     HL
        ;; Write out origin values, update pointer
                LD      (DecodeOrgPtr),HL
                LD      (HL),B
                INC     HL
                LD      (HL),C
                INC     HL
                LD      (HL),A
        ;; Origin updated, save the current read pointer.
                LD      A,(CurrData)
                LD      HL,(DataPtr)
                PUSH    AF
                PUSH    HL
        ;; Run the macro.
                CALL    FindMacro
                LD      (DataPtr),HL
RPE1:           CALL    ProcEntry
                JR      NC,RPE1
        ;; Pop the decode origin stack...
                LD      HL,(DecodeOrgPtr)
                DEC     HL
                DEC     HL
                DEC     HL
                LD      (DecodeOrgPtr),HL
        ;; And restore the read pointer.
                POP     HL
                POP     AF
                LD      (DataPtr),HL
                LD      (CurrData),A
        ;; NB: Fall through, carrying on.

;; Process one entry in the description array. Returns carry when done.
ProcEntry:      LD      B,$08
                CALL    FetchData
        ;; Return with carry set if we hit $FF.
                CP      $FF
                SCF
                RET     Z
        ;; Code >= $C0 means recurse.
                CP      $C0
                JR      NC,RecProcEntry         ; NB: Tail call (falls through back)
        ;; Otherwise, deal with an object.
                PUSH    IY
                LD      IY,TmpObj
                CALL    ProcDataStart
                POP     IY
        ;; Read two bits. Bottom bit is "should loop".
        ;; Top bit is "read flag bit once for all loops?".
                LD      B,$02
                CALL    FetchData
                BIT     1,A
                JR      NZ,PE1
        ;; We will read per loop. Set "should loop" bit.
                LD      A,$01
                JR      PE2
PE1:
        ;; Not reading per-loop. Read once and store in the 0x04 bit position.
                PUSH    AF
                LD      B,$01
                CALL    FetchData
                POP     BC
                RLCA
                RLCA
                OR      B
PE2:            LD      (UnpackFlags),A
        ;; And then some processing loops thing...
PE3:            CALL    SetTmpObjFlags
                CALL    SetTmpObjUVZEx
        ;; Only loop if loop bit (bottom bit) is set.
                LD      A,(UnpackFlags)
                RRA
                JR      NC,PE4
        ;; Although we break out if (ExpandDone) is 0xFF.
                LD      A,(ExpandDone)
                INC     A
                AND     A
                RET     Z
                CALL    ProcTmpObj
                JR      PE3
PE4:            CALL    ProcTmpObj
                AND     A
                RET

;; Once we've built TmpObj, process it...
ProcTmpObj:     LD      HL,TmpObj
                LD      BC,L0012
                PUSH    IY
                LD      A,(SkipObj)
                AND     A
                CALL    Z,ProcDataObj
                POP     IY
                RET

        ;; Could this perhaps be setting some kind of boundary - 4 calls, etc?
BPDSubB:	LD	B,$03
		CALL	FetchData
		CALL	C7358   ; Looks suspiciously like self-modifying code
		ADD	A,A
		LD	L,A
		LD	H,A
		INC	H
		LD	(L7705),HL
		LD	IX,L7707
		LD	HL,L7748
		EXX
		LD	A,(IY-$01)
		ADD	A,$04
		CALL	YetAnotherA
		LD	HL,L7749
		EXX
		LD	A,(IY-$02)
		ADD	A,$04
		CALL	YetAnotherB
		LD	HL,L774A
		EXX
		LD	A,(IY-$03)
		SUB	$04
		CALL	YetAnotherA
		LD	HL,L774B
		EXX
		LD	A,(IY-$04)
		SUB	$04
		JP	YetAnotherB		; Tail call
	
ThingA:		LD	B,$03
		CALL	FetchData
		LD	HL,L7716
		SUB	$02
        ;; Jump for the fetched-a-0-or-1 case
		JR	C,ThingA2
        ;; Rotate a zero into (HL)
		RL	(HL)
        ;; And rotate a one bit into (HL+1)
		INC	HL
		SCF
		RL	(HL)
        ;; Set A = 9 - fetched data
		SUB	$07
		NEG
        ;; Z coordinate set to 6 * A + 0x96
		LD	C,A
		ADD	A,A
		ADD	A,C
		ADD	A,A
		ADD	A,$96
		LD	(TmpObj+7),A
        ;; Set carry flag, switch reg set and save Z coord
		SCF
		EXX
		LD	(HL),A
		RET
ThingA2:
        ;; Set flag if fetched value was 1.
		CP	$FF
		CCF
        ;; Rotate it into (HL)
		RL	(HL)
        ;; And rotate a zero bit into (HL+1)
		AND	A
		INC	HL
		RL	(HL)
        ;; Return with no carry
		AND	A
		RET

        ;; These two seem to take a thing in HL' and A.
YetAnotherB:	LD	(TmpObj+5),A
		LD	HL,TmpObj+6
		LD	A,(L76E1)
		JP	YetAnotherCore   	; NB: Tail call

YetAnotherA:	LD	(TmpObj+6),A
		LD	HL,TmpObj+5
		LD	A,(L76E0)
        ;; NB: Fall through

        ;; Takes things in A, HL and HL'
        ;; HL points to a place to put a coordinate
YetAnotherCore:
        ;; Multiply A by 8
		ADD	A,A
		ADD	A,A
		ADD	A,A
		PUSH	AF
        ;; Stash A + $24 in the coordinate
		ADD	A,$24
		LD	(HL),A
		PUSH	HL
		CALL	ThingA
		JR	NC,ThingD 	; NB: Tail call
		LD	A,(IX+$00)
		LD	(TmpObj+4),A
		INC	IX
		LD	A,(L7705)
		LD	(TmpObj+8),A
		CALL	ThingC
		LD	A,(IX+$00)
		LD	(TmpObj+4),A
		INC	IX
		LD	A,(L7706)
		LD	(TmpObj+8),A
		POP	HL
		POP	AF
		ADD	A,$2C
		LD	(HL),A
        ;; NB: Fall through

ThingC:		CALL	ProcTmpObj
		LD	A,(TmpObj+4)
		LD	C,A
		AND	$30
		RET	PO
		AND	$10
		OR	$01
		LD	(TmpObj+4),A
		LD	A,(TmpObj+7)
		CP	$C0
		RET	Z
		PUSH	AF
		ADD	A,$06
		LD	(TmpObj+7),A
		LD	A,$54
		LD	(TmpObj+8),A
		CALL	ProcTmpObj
		POP	AF
		LD	(TmpObj+7),A
		RET

ThingD:		POP	HL
		POP	AF
		INC	IX
		INC	IX
		RET

;; Clears CurrData and returns a pointer to a specific room description macro
FindMacro:      LD      A,$80
                LD      (CurrData),A    ; Clear buffered byte.
                LD      HL,RoomMacros
                EX      AF,AF'
                LD      D,$00
FM1:            LD      E,(HL)
                INC     HL
                CP      (HL)
                RET     Z
                ADD     HL,DE
                JR      FM1

SomeExport:	LD	BC,(RoomId)
		LD	A,C
		DEC	A
		AND	$F0
		LD	C,A
		CALL	FindRoom
		RET	C
        ;; Not found? Let's carry on...
        ;; FIXME: ???
		INC	DE
		INC	DE
		INC	DE
		LD	A,(DE)
		OR	$F1
		INC	A
		RET	Z
		SCF
		RET

;; Like FindRoom, but set the "visited" bit. Assumes HL' and C' set.
FindVisitRoom:  CALL    FindRoom
                EXX
                LD      A,C
                OR      (HL)
                LD      (HL),A
                EXX
                RET

;; Find a room. Takes room id in BC. Returns first field in A, and
;; room bit mask location in HL' and C'.
FindRoom:       LD      D,$00
                LD      HL,RoomList1
                CALL    FindRoom2
                RET     NC
                LD      HL,RoomList2
                JR      FindRoomInner ; NB: Tail call

        ;; Set up the room bit field thing, and do the first run.
FindRoom2:      EXX
                LD      HL,RoomMask
                LD      C,$01
                EXX
        ;; NB: Fall through

;; Finds an entry in a room list. The list consists of packed entries.
;;
;; The entry structure is:
;; 1 byte size (excludes this byte)
;; 1.5 bytes id (bottom nibble ignored for matching)
;; Data
;;
;; A size of zero terminates the list.
;;
;; This is called with:
;;  HL pointing to the start of the tagged list
;;  D should be zero - DE will be the entry size
;;  BC should be the id we're looking for
;;  HL' and C' are incremented as the address and bit mask for a bitfield
;;   associated with the nth entry.
;;
;; The carry flag is set if nothing's returned. Otherwise, it returns the
;; first four bits of the bit-packed data.
FindRoomInner:
        ;; Return with carry set if (HL) is 0 - not found.
                LD      E,(HL)
                INC     E
                DEC     E
                SCF
                RET     Z
        ;; If HL+1 equals B, go to FR4
                INC     HL
                LD      A,B
                CP      (HL)
                JR      Z,FR4
        ;; Otherwise, increment HL by DE, move the bit pointer in C',
        ;; and increment HL' every time the bit wraps round. Then loop.
FR2:            ADD     HL,DE
                EXX
                RLC     C
                JR      NC,FR3
                INC     HL
FR3:            EXX
                JR      FindRoomInner
        ;; Second check: Does HL+2 & 0xF0 equal C?
FR4:            INC     HL
                DEC     E       ; Incremented HL, so decrement DE.
                LD      A,(HL)
                AND     $F0
                CP      C
                JR      NZ,FR2
        ;; Found item. Step back to start of item.
                DEC     HL
        ;; Initialise DataPtr and CurrData for new data.
                LD      (DataPtr),HL
                LD      A,$80
                LD      (CurrData),A
        ;; Skip that top nibble of id.
                LD      B,$04
                JP      FetchData ; NB: Tail call

;; Called from inside the ProcEntry loop...
SetTmpObjFlags:	LD	A,(UnpackFlags)
		RRA
		RRA
        ;; If the 'read once' bit is set, use the read-once value.
        ;; Otherwise, read another bit.
		JR	C,BTOA1
		LD	B,$01
		CALL	FetchData
BTOA1:		AND	$01
        ;; Flag goes into 0x10 position of the object flag.
		RLCA
		RLCA
		RLCA
		RLCA
		AND	$10
        ;; Set fields of TmpObj
		LD	C,A
		LD	A,(L76ED)
		XOR	C
		LD	(TmpObj+4),A
		LD	BC,(L76EC)
		BIT	4,A
		JR	Z,BTOA3
		BIT	1,A
		JR	Z,BTOA2
		XOR	$01
		LD	(TmpObj+4),A
BTOA2:		DEC	C
		DEC	C
BTOA3:		LD	A,C
		LD	(TmpObj+16),A
		RET

;; Read U, V, Z coords (3 bits each), and set TmpObj's location
SetTmpObjUVZEx: CALL    FetchData333
        ;; NB: Fall through

;; Put B = U coord, C = V coord, A = Z coord
;; Set's TmpObj's location
SetTmpObjUVZ:   EX      AF,AF'
                LD      HL,(DecodeOrgPtr)
                LD      DE,TmpObj+5
        ;; NB: Fall through

;; Calculates U, V and Z coordinates
;;  DE points to where we will write the U, V and Z coordinates
;;  HL points to the address of the origin which we add our coordinates to.
;;  B contains U, C contains V, A' contains Z
;;  U/V coordinates are built on a grid of * 8 + 12
;;  Z coordinate is built on a grid of * 6 + 0x96
;;  Sets ExpandDone to 0xFF (done) if B = 7, C = 7, A' = 0
SetUVZ:         LD      A,B
                CALL    TwiddleHL
                LD      (DE),A          ; Set U coordinate
                LD      A,C
                CALL    TwiddleHL
                INC     DE
                LD      (DE),A          ; Set V coordinate
                EX      AF,AF'
                PUSH    AF
                ADD     A,(HL)
        ;; Take value * 6 + 0x96
                LD      L,A
                ADD     A,A
                ADD     A,L
                ADD     A,A
                ADD     A,$96
                INC     DE
                LD      (DE),A          ; Set Z coordinate
                POP     AF
        ;; Set ExpandDone to 0xFF if Z coord is 0, U and V are 7.
                CPL
                AND     C
                AND     B
                OR      $F8
                LD      (ExpandDone),A
                RET

;; Read a value from (HL), increment HL, return value * 8 + 12
TwiddleHL:      ADD     A,(HL)
                INC     HL
                RLCA
                RLCA
                RLCA
                ADD     A,$0C
                RET

;; Fetch 3 lots of 3 bits to B, C and A.
FetchData333:   LD      B,$03
                CALL    FetchData
                PUSH    AF
                LD      B,$03
                CALL    FetchData
                PUSH    AF
                LD      B,$03
                CALL    FetchData
                POP     HL
                POP     BC
                LD      C,H
                RET
