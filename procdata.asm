;;
;; procdata.asm
;;
;; Mystery set of functions that process the bit-packed data
;;

;; Exported functions:
;;  * BigProcData
;;  * ProcDataEltC
;;  * ProcDataEltD
;;  * ProcTmpObj
;;  * SomeExport

;; Calls into:
;;  * C7358
;; (and maybe some more)

;; FIXME: Called lots. Suspect it forms the backbone of loading a
;; screen or something? Reads all the packed data.
;; Takes something in HL and BC and IY
BigProcData:	LD	(L76E0),HL
		XOR	A
		LD	(L76E2),A
		PUSH	BC
		CALL	BPDSubA
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
BPD1:		LD	C,(HL)
		LD	A,(IX+$00)
		AND	A
		JR	Z,BPD2
		SUB	C
		LD	E,A
		RRA
		RRA
		RRA
		AND	$1F
		LD	(IX+$00),A
		LD	A,E
BPD2:		ADD	A,C
		LD	(IY+$00),A
		INC	HL
		INC	IX
		INC	IY
		DJNZ	BPD1
	;; Do this bit twice:
		LD	B,$02
BPD3:		LD	A,(IX-$02)
		ADD	A,A
		ADD	A,A
		ADD	A,A
		ADD	A,(HL)
		LD	(IY+$00),A
		INC	IY
		INC	IX
		INC	HL
		DJNZ	BPD3
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
BPD4:		CALL	ProcData
		JR		NC,BPD4
		POP		BC
		JP		BPDEnd 		; NB: Tail call.

;; Add a signed 3-bit value in A to (HL), result in A
Add3Bit:        BIT     2,A
                JR      Z,A3B
                OR      $F8
A3B:            ADD     A,(HL)
                RET

;; Recursively do ProcData
RecProcData:	EX	AF,AF'
		CALL	FetchData333
		LD	HL,(L76DE)
		PUSH	AF
		LD	A,B
		CALL	Add3Bit
		LD	B,A
		INC	HL
		LD	A,C
		CALL	Add3Bit
		LD	C,A
		INC	HL
		POP	AF
		SUB	$07
		ADD	A,(HL)
		INC	HL
		LD	(L76DE),HL
		LD	(HL),B
		INC	HL
		LD	(HL),C
		INC	HL
		LD	(HL),A
	;; Save the current data pointer, do some stuff, restore.
		LD	A,(CurrData)
		LD	HL,(DataPtr)
		PUSH	AF
		PUSH	HL
		CALL	GetDataPtr
		LD	(DataPtr),HL
RPD1:		CALL	ProcData
		JR	NC,RPD1
		LD	HL,(L76DE)
		DEC	HL
		DEC	HL
		DEC	HL
		LD	(L76DE),HL
		POP	HL
		POP	AF
		LD	(DataPtr),HL
		LD	(CurrData),A
	;; NB: Fall through, carrying on.

;; TODO: Processes some fetched data.
ProcData:	LD	B,$08
		CALL	FetchData
        ;; Return if we hit $FF with carry set.
		CP	$FF
		SCF
		RET	Z
        ;; Code >= $C0 means recurse.
		CP	$C0
		JR	NC,RecProcData
        ;; Otherwise do FIXME
		PUSH	IY
		LD	IY,TmpObj
		CALL	ProcDataStart
		POP	IY
        ;; A few bits set up L7700
		LD	B,$02
		CALL	FetchData
		BIT	1,A
		JR	NZ,PD1
		LD	A,$01
		JR	PD2
PD1:		PUSH	AF
		LD	B,$01
		CALL	FetchData
		POP	BC
		RLCA
		RLCA
		OR	B
PD2:		LD	(L7700),A
        ;; And then some processing loops thing...
PD3:		CALL	ProcDataEltA
		CALL	ProcDataEltB
		LD	A,(L7700)
		RRA
		JR	NC,PD4
		LD	A,(L7704)
		INC	A
		AND	A
		RET	Z
		CALL	ProcTmpObj
		JR	PD3
PD4:		CALL	ProcTmpObj
		AND	A
		RET

;; TODO: Some thing we do at the end of ProcData.
;; And elsewhere. Not a great name, but we're giving it a name...
ProcTmpObj:	LD	HL,TmpObj
		LD	BC,L0012
		PUSH	IY
		LD	A,(SkipObj)
		AND	A
		CALL	Z,ProcDataObj
		POP	IY
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
		JR	C,ThingB
		RL	(HL)
		INC	HL
		SCF
		RL	(HL)
		SUB	$07
		NEG
        ;; Z coordinate set to 6 * A + 0x96
		LD	C,A
		ADD	A,A
		ADD	A,C
		ADD	A,A
		ADD	A,$96
		LD	(TmpObj+7),A
		SCF
		EXX
		LD	(HL),A
		RET

ThingB:		CP	$FF
		CCF
		RL	(HL)
		AND	A
		INC	HL
		RL	(HL)
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

YetAnotherCore:	ADD	A,A
		ADD	A,A
		ADD	A,A
		PUSH	AF
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

;; Clears CurrData and returns a value in HL to be used as DataPtr
GetDataPtr:	LD		A,$80
		LD		(CurrData),A 	; Clear buffered byte.
	;; Get the size of some buffer thing: Start at L5B00, just after attributes.
	;; Take first byte as step size, then scan at that step size until we find a zero.
	;; Return in HL.
        ;;
        ;; NB: Unless data is changed, this is after 67C6?
		LD		HL,L5B00
		EX		AF,AF'
		LD		D,$00
GDP1:		LD		E,(HL)
		INC		HL
		CP		(HL)
		RET		Z
		ADD		HL,DE
		JR		GDP1

	
SomeExport:	LD		BC,(L703B)
		LD		A,C
		DEC		A
		AND		$F0
		LD		C,A
		CALL	ThingE
		RET		C
		INC		DE
		INC		DE
		INC		DE
		LD		A,(DE)
		OR		$F1
		INC		A
		RET		Z
		SCF
		RET
	
BPDSubA:	CALL	ThingE
		EXX
		LD		A,C
		OR		(HL)
		LD		(HL),A
		EXX
		RET

ThingE:	LD		D,$00
		LD		HL,L5C71
		CALL	ThingF
		RET		NC
		LD		HL,L6B16
		JR		ThingG ; NB: Tail call
	
ThingF:		EXX
		LD		HL,L8AE2
		LD		C,$01
		EXX
        ;; NB: Fall through

ThingG:		LD		E,(HL)
		INC		E
		DEC		E
		SCF
		RET		Z
		INC		HL
		LD		A,B
		CP		(HL)
		JR		Z,TG4
TG2:		ADD		HL,DE
		EXX
		RLC		C
		JR		NC,TG3
		INC		HL
TG3:		EXX
		JR		ThingG ; NB: Loop back to top
TG4:		INC		HL
		DEC		E
		LD		A,(HL)
		AND		$F0
		CP		C
		JR		NZ,TG2
		DEC		HL
	;; Initialise DataPtr and CurrData for new data.
		LD		(DataPtr),HL
		LD		A,$80
		LD		(CurrData),A
		LD		B,$04
		JP		FetchData ; NB: Tail call

;; Called from inside the ProcData loop...
ProcDataEltA:	LD	A,(L7700)
		RRA
		RRA
		JR	C,PDEA1
		LD	B,$01
		CALL	FetchData
PDEA1:		AND	$01
		RLCA
		RLCA
		RLCA
		RLCA
		AND	$10
		LD	C,A
		LD	A,(L76ED)
		XOR	C
		LD	(TmpObj+4),A
		LD	BC,(L76EC)
		BIT	4,A
		JR	Z,PDEA3
		BIT	1,A
		JR	Z,PDEA2
		XOR	$01
		LD	(TmpObj+4),A
PDEA2:		DEC	C
		DEC	C
PDEA3:		LD	A,C
		LD	(TmpObj+16),A
		RET

;; Called from inside the ProcData loop...
ProcDataEltB:	CALL	FetchData333
        ;; NB: Fall through

ProcDataEltC:	EX	AF,AF'
		LD	HL,(L76DE)
		LD	DE,TmpObj+5
        ;; NB: Fall through

ProcDataEltD:	LD	A,B
		CALL	TwiddleHL
		LD	(DE),A
		LD	A,C
		CALL	TwiddleHL
		INC	DE
		LD	(DE),A
		EX	AF,AF'
		PUSH	AF
		ADD	A,(HL)
		LD	L,A
		ADD	A,A
		ADD	A,L
		ADD	A,A
		ADD	A,$96
		INC	DE
		LD	(DE),A
		POP	AF
		CPL
		AND	C
		AND	B
		OR	$F8
		LD	(L7704),A
		RET

;; Read a value from (HL), increment HL, return value * 8 + 12 ?!
TwiddleHL:	ADD	A,(HL)
		INC	HL
		RLCA
		RLCA
		RLCA
		ADD	A,$0C
		RET

;; Fetch 3 lots of 3 bits to C, B and A.
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
