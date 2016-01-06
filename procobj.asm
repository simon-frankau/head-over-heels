;;
;; procobj.asm
;;
;; Mystery set of functions that handle an object?
;;

;; Exported functions:
;;  * ProcDataObj
;;  * GetUpdatedCoords
;;  * CB010
;;  * CB0C6
;;  * CB03B
;;  * CB0BE
;;  * CB0F9

;; Called during the ProcData loop to copy an object into the dest
;; buffer and process it.
;;
;; HL points to an object.
;; BC contains the size of the object (always 18 bytes!).
ProcDataObj:
        ;; First, just return if there's no intersection with the view window.
                PUSH    HL
                PUSH    BC
                INC     HL
                INC     HL
                CALL    IntersectObj   ; HL now contains an object + 2
                POP     BC
                POP     HL
                RET     NC
        ;; Copy BC bytes of object to what ObjDest pointer, updating ObjDest
                LD      DE,(ObjDest)
                PUSH    DE
                LDIR
                LD      (ObjDest),DE
                POP     HL
        ;; HL now points at copied object
                PUSH    HL
                POP     IY
                BIT     3,(IY+$04)      ; Check bit 3 of flags...
                JR      Z,CB010         ; NB: Tail call if not set
        ;; Make another copy of the next 9 bytes? FIXME...
		LD	BC,L0009
		PUSH	HL
		LDIR
		EX	DE,HL
		LD	A,(DE)
		OR	$02
		LD	(HL),A
		INC	HL
		LD	(HL),$00
		LD	DE,L0008
		ADD	HL,DE
		LD	(ObjDest),HL
		BIT	5,(IY+$09)
		JR	Z,LB00F
		PUSH	IY
		LD	DE,L0012
		ADD	IY,DE
		LD	A,(L822E)
		CALL	C828B
		POP	IY
LB00F:		POP	HL
        ;; NB: Fall through.

;; HL points at an object, as does IY.
CB010:		LD	A,(LAF77)
		DEC	A
		CP	$02
		JR	NC,CB03B
		INC	HL
		INC	HL
		BIT	3,(IY+$04)
		JR	Z,CB034
		PUSH	HL
		CALL	CB034
		POP	DE
		CALL	CAFAB
		PUSH	HL
		CALL	GetUpdatedCoords2
		EXX
		PUSH	IY
		POP	HL
		INC	HL
		INC	HL
		JR	LB085
CB034:		PUSH	HL
		CALL	GetUpdatedCoords2
		EXX
		JR	LB082

	
CB03B:		INC	HL
		INC	HL
		BIT	3,(IY+$04)
		JR	Z,CB057
		PUSH	HL
		CALL	CB057
		POP	DE
		CALL	CAFAB
		PUSH	HL
		CALL	GetUpdatedCoords2
		EXX
		PUSH	IY
		POP	HL
		INC	HL
		INC	HL
		JR	LB085

CB057:		PUSH	HL
		CALL	GetUpdatedCoords2
		LD	A,$03
		EX	AF,AF'
		LD	A,(L771A)
		CP	D
		JR	C,LB07D
		LD	A,(L771B)
		CP	H
		JR	C,LB07D
		LD	A,$04
		EX	AF,AF'
		LD	A,(L7718)
		DEC	A
		CP	E
		JR	NC,LB07D
		LD	A,(L7719)
		DEC	A
		CP	L
		JR	NC,LB07D
		XOR	A
		EX	AF,AF'
LB07D:		EXX
		EX	AF,AF'
		CALL	CAF96
LB082:	        LD	HL,(LAF7A)
LB085:	        LD	(LAF94),HL
LB088:	        LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		OR	H
		JR	Z,LB09C
		PUSH	HL
		CALL	GetUpdatedCoords2
		CALL	CB17A
		POP	HL
		JR	NC,LB085
		AND	A
		JR	NZ,LB088
LB09C:	LD		HL,(LAF94)
		POP	DE
		LD	A,(HL)
		LDI
		LD	C,A
		LD	A,(HL)
		LD	(DE),A
		DEC	DE
		LD	(HL),D
		DEC	HL
		LD	(HL),E
		LD	L,C
		LD	H,A
		OR	C
		JR	NZ,LB0B4
		LD	HL,(LAF7C)
		INC	HL
		INC	HL
LB0B4:	DEC		HL
		DEC	DE
		LDD
		LD		A,(HL)
		LD		(DE),A
		LD		(HL),E
		INC		HL
		LD		(HL),D
		RET
CB0BE:	PUSH	HL
		CALL	CB0C6
		POP		HL
		JP		CB03B
CB0C6:	BIT		3,(IY+$04)
		JR		Z,CB0D5
		PUSH	HL
		CALL	CB0D5
		POP		DE
		LD		HL,L0012
		ADD		HL,DE
CB0D5:	LD		E,(HL)
		INC		HL
		LD		D,(HL)
		INC		HL
		PUSH	DE
		LD		A,D
		OR		E
		INC		DE
		INC		DE
		JR		NZ,LB0E4
		LD		DE,(LAF7A)
LB0E4:	LD		A,(HL)
		LDI
		LD		C,A
		LD		A,(HL)
		LD		(DE),A
		LD		H,A
		LD		L,C
		OR		C
		DEC		HL
		JR		NZ,LB0F4
		LD		HL,(LAF7C)
		INC		HL
LB0F4:	POP		DE
		LD		(HL),D
		DEC		HL
		LD		(HL),E
		RET

	;; Have a suspicion this places X/Y extents in DE/HL and Z coords in BC
CB0F9:		CALL	GetUpdatedCoords
		AND		$08
		RET		Z
		LD		A,C
		SUB		$06
		LD		C,A
		RET

	;; FIXME: Some object-processing thing...
	;; FIXME: Seems to calculate speeds to move in particular directions
GetUpdatedCoords:	INC		HL
			INC		HL
GetUpdatedCoords2:	INC		HL
			INC		HL
			LD		A,(HL) 		; Offset 4: Flags
			INC		HL
			LD		C,A
			EX		AF,AF'
			LD		A,C
			BIT		2,A
			JR		NZ,LB153 	; If bit 2 set
			BIT		1,A
			JR		NZ,GUC3 	; If bit 1 set
			AND		$01
			ADD		A,$03
			LD		B,A 		; Bit 0 + 3 in B
			ADD		A,A
			LD		C,A 		; x2 in C
			LD		A,(HL)
			ADD		A,B
			LD		D,A 		; Store added co-ord in D
			SUB		C
			LD		E,A 		; And subtracted co-ord in E
			INC		HL
			LD		A,(HL)
			INC		HL
			ADD		A,B
			LD		B,(HL)
			LD		H,A 		; Store 2nd added co-ord in H
			SUB		C
			LD		L,A 		; And 2nd subtracted co-ored in L
GUC2:			LD		A,B
			SUB		$06
			LD		C,A 		; Put Z co-ord - 6 in C
			EX		AF,AF'
			RET

	;; Bit 1 was set in the object flags
GUC3:		RRA
		JR		C,GUC4
	;; Bit 1 set, bit 0 not set
		LD		A,(HL)
		ADD		A,$04
		LD		D,A
		SUB		$08
		LD		E,A 			; D/E given added/subtracted co-ords of 4
		INC		HL
		LD		A,(HL)
		INC		HL
		LD		B,(HL)
		LD		H,A
		LD		L,A 			; H/L given added/subtracted co-ords of 1
		INC		H
		DEC		L
		JR		GUC2

	;; Bits 1 and 0 were set
GUC4:		LD		D,(HL)
		LD		E,D
		INC		D
		DEC		E 			; D/E given added/subtracted co-ords of 1
		INC		HL
		LD		A,(HL)
		INC		HL
		ADD		A,$04
		LD		B,(HL)
		LD		H,A
		SUB		$08
		LD		L,A 			; H/L given added/subtracted co-ords of 4
		JR		GUC2

	;; Bit 2 was set in the object flags
LB153:		LD		A,(HL)
		RR		C
		JR		C,LB15E
		LD		E,A
		ADD		A,$04
		LD		D,A
		JR		LB162
LB15E:		LD		D,A
		SUB		$04
		LD		E,A
LB162:		INC		HL
		LD		A,(HL)
		INC		HL
		LD		B,(HL)
		RR		C
		JR		C,LB170
		LD		L,A
		ADD		A,$04
		LD		H,A
		JR		LB174
LB170:		LD		H,A
		SUB		$04
		LD		L,A
LB174:		LD		A,B
		SUB		$12
		LD		C,A
		EX		AF,AF'
		RET
