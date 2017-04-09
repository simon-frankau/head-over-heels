;;
;; init_bkgnd.asm
;;
;; Initialise variables used by background-drawing.
;;

;; Exports GetScreenEdges

;; Uses the following variables and functions:
;; * BkgndData
;; * CornerPos
;; * HasDoor
;; * LeftAdj
;; * MinU
;; * RightAdj
;; * TweakEdges

;; TODO: Needs a good clean and tidy.
        
        
        
	;;    ^
	;;   / \
	;;  /   \
	;; H     L
	
GetScreenEdges:	LD	HL,(MinU)
		LD	A,(HasDoor)
		PUSH	AF
		BIT	1,A
		JR	Z,GSE_1
		DEC	H
		DEC	H
		DEC	H
		DEC	H
GSE_1:		RRA
		LD		A,L
		JR		NC,GSE_2
		SUB		$04
		LD		L,A
GSE_2:		SUB		H
	;; X coordinate of the play area bottom corner is in A.
	;; 
	;; We write out the corner position, and the appropriate
	;; overall vertical adjustments.
		ADD		A,$80
		LD		(CornerPos+1),A
		LD		C,A
		LD		A,$FC
		SUB		H
		SUB		L
		LD		B,A			; B = $FC - H - L
		NEG
		LD		E,A			; E = H + L - $FC
		ADD		A,C 			; 
		LD		(LeftAdj+1),A		; E + CornerPos
		LD		A,C
		NEG
		ADD		A,E
		LD		(RightAdj+1),A 		; E - CornerPos
	;; FIXME: Next bit.
		CALL		TweakEdges
		POP		AF
		RRA
		PUSH		AF
		CALL		NC,NukeColL
		POP		AF
		RRA
		RET		C
	;; Scan from the right for the first drawn column
		LD	HL,BkgndData + 31*2
ScanR:		LD	A,(HL)
		AND	A
		JR	NZ,NukeCol
		DEC	HL
		DEC	HL
		JR	ScanR

	;; If the current screen column sprite isn't a door column, delete it.
NukeCol:	INC	HL
		LD	A,(HL)
		OR	~5
		INC	A
		RET	NZ
		LD	(HL),A
		DEC	HL
		LD	(HL),A
		RET

	;; Scan from the left for the first drawn column
NukeColL:	LD	HL,BkgndData
ScanL:		LD	A,(HL)
		AND	A
		JR	NZ,NukeCol
		INC	HL
		INC	HL
		JR	ScanL
