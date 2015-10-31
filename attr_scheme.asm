	;; 
	;; attr_scheme.asm
	;;
	;; Attribute colour schemes
	;;

	;; Exported functions:
        ;; * SetAttribs
        ;; * UpdateAttribs

        ;; Exported variables:
        ;; * AttribL
        ;; * AttribR
        ;; * LastOut
        
	;; FIXME: Give the schemes nicer names, generally polish
	
	;; Paper colour
BK:		EQU	0
BL:		EQU	1
RD:		EQU	2
MG:		EQU	3
GR:		EQU	4
CY:		EQU	5
YL:		EQU	6
WH:		EQU	7
	;; Modifiers (otherwise, will be dark with black ink)
BR:		EQU	$40	; Bright
BLI:		EQU	$10	; Blue ink
WHI:		EQU	$38	; White ink

	;; The various colour schemes available.
AttribTable:	DEFB    YL,    CY, BR+CY,  BR+MG,  BR+GR,     WH ; 0
		DEFB    WH, BR+GR,    CY,  BR+MG,  BR+GR,     YL ; 1
		DEFB    CY,    MG,    WH,  BR+GR,  BR+YL,  BR+WH ; 2
		DEFB BR+MG,    GR,    CY,  BR+CY,  BR+YL,  BR+WH ; 3
		DEFB BR+GR,    CY,    YL,  BR+MG,  BR+CY,  BR+WH ; 4
		DEFB BR+CY, BR+MG,    WH,  BR+GR,  BR+YL,  BR+WH ; 5
		DEFB BR+WH, BR+CY,    YL,  BR+MG,  BR+CY,  BR+YL ; 6
		DEFB BR+YL, BR+GR,    WH,  BR+MG,  BR+GR,  BR+CY ; 7
		DEFB    BK,    BK,    BK,     BK,     BK,     BK ; 8
		DEFB   WHI,    BK,    BK, WHI+BL, WHI+RD, WHI+GR ; 9
		DEFB   BLI,    BK,    BK, BLI+CY, BLI+YL, BLI+WH ; 10
	
UpdateAttribs:	CALL	SetAttribs
		JP	ApplyAttribs	; Tail call

	;; The border attribute etc. is saved for the sound routine to modify.
LastOut:	DEFB $00

	;; Set the attribute set, based on number in A.
SetAttribs:	LD	C,A
		ADD	A,A
		ADD	A,C
		ADD	A,A
		LD	C,A		; x6
		LD	B,$00
		LD	HL,AttribTable
		ADD	HL,BC
		LD	A,(HL)		; Index into table
		LD	(Attrib0),A
		RRA
		RRA
		RRA
		OUT	($FE),A		; Output paper colour as border.
		LD	(LastOut),A
		LD	A,(HL)
		INC	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		LD	(AttribL),DE 	; Writes out AttribR at the same time
		LD	DE,Attrib3
		INC	HL
		LDI			; Write out Attrib3
		LDI			; Write out Attrib4
		LDI			; Write out Attrib5
	;; Fill the whole screen with Attrib0.
		LD	C,A
		LD	HL,L5800
AttribLoop:	LD	(HL),C
		INC	HL
		LD	A,H
		CP	$5B
		JR	C,AttribLoop
		RET

;; AttribL is used for the left-hand play area edge, AttribR the right.
AttribL:        DEFB $00
AttribR:        DEFB $00
