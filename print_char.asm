	;; Text-printing functions
	
CharDoublerBuf:	DEFS $10,$00 	; 16 bytes to hold double-height character.

AttrIdx:	DEFB $02	; Which attribute number to use.
CharCursor:	DEFW $8040	; Where we're going to put the character, on screen.
IsDoubleHeight:	DEFB $00	; Non-zero if printing double-height.
KeepAttr:	DEFB $FF	; If set to zero, step through attribute codes 1, 2, 3.

	;; Main character-printing entry point.
PrintChar:	JP	PrintCharBase	; NB: Target of self-modifying code.

	;; Default character printer
PrintCharBase:	CP	$80
		JR	NC,PCB_3
		SUB	$20
		JR	C,ControlCode 	; Tail call!
	;; Printable character!
		CALL	CharCodeToAddr 	; Address now in DE
		LD	HL,L0804	; 8x8 sprite
		LD	A,(IsDoubleHeight)
		AND	A
		CALL	NZ,CharDoubler 	; Double the height if necessary.
		LD	BC,(CharCursor) ; Load the destination cursor...
		LD	A,C
		ADD	A,$04
		LD	(CharCursor),A 	; And advance the cursor.
		LD	A,(KeepAttr)
		AND	A
		LD	A,(AttrIdx) 	; Load the attribute index to use.
		JR	NZ,PCB_2
		INC	A		; If KeepAttr was zero, cycle through attrs 1-3.
		AND	$03
		SCF			; (?)
		JR	NZ,PCB_1
		INC	A
PCB_1:		LD	(AttrIdx),A
PCB_2:		JP	DrawSprite
	;; Code >= 0x80: Print a string from the string tables.
PCB_3:		AND	$7F
		CALL	GetStrAddr
	;; NB: Fall through.

	;; Print characters in HL until $FF is reached.
PrintChars:	LD	A,(HL)
		CP	$FF
		RET	Z
		INC	HL
		PUSH	HL
		CALL	PrintChar
		POP	HL
		JR	PrintChars

	;; Code < 0x20:
	;; Code 0: ScreenWipe
	;; Code 1: Newline
	;; Code 2: Spaces to end of line
	;; Code 3: Double height off
	;; Code 4: Double height on
	;; Code 5: Set attribute index (0 means cycle, all others set specifically)
	;; Code 6: Set cursor
	;; Code 7: Set the screen attributes mode
ControlCode:	ADD	A,$20		; Add the 0x20 back.
		CP	$05
		JR	NC,CC_GE5
		AND	A
		JP	Z,ScreenWipe 	; Tail call
		SUB	$02
		JR	C,CC_EQ1
		JR	Z,CC_EQ2
		DEC	A
		LD	(IsDoubleHeight),A
		RET

	;; Print spaces to the end of line.
CC_EQ2:		LD	A,(CharCursor)
		CP	$C0
		RET	NC
		LD	A,$20
		CALL	PrintChar
		JR	CC_EQ2

CC_EQ1:		LD	HL,(CharCursor)
		LD	A,(IsDoubleHeight) 	; Go down one or two rows, depending on height,
		AND	A
		LD	A,H
		JR	Z,CC_NotDbl
		ADD	A,$08
CC_NotDbl:	ADD	A,$08
		LD	H,A
		LD	L,$40			; and return X position to centre of screen.
		LD	(CharCursor),HL
		RET

	;; These cases change the interpretation of the next character...
CC_GE5:		LD	HL,PrintFn5
		JR	Z,SetPrintFn
		CP	$07
		LD	HL,PrintFn7
		JR	Z,SetPrintFn
		LD	HL,PrintFn6
	;; NB: Fall-through.

	;; Set the function called when you 'PrintChar'.
SetPrintFn:	LD	(PrintChar+1),HL
		RET

PrintFn7:	CALL	SetAttribs
		JR	RestorePrintFn
	
PrintFn5:	AND	A
		LD	(KeepAttr),A
		JR	Z,RestorePrintFn
		LD	(AttrIdx),A
	;; NB: Fall-through
	
	;;  Restore the default function called when you 'PrintChar'.
RestorePrintFn:	LD	HL,PrintCharBase
		JR	SetPrintFn

PrintFn6:	LD	HL,PrintFn6b 	; Next time, we'll set X coordinate
		ADD	A,A
		ADD	A,A
		ADD	A,$40		; Convert from character to half-pixel coordinates
		LD	(CharCursor),A	; and store
		JR	SetPrintFn
	
PrintFn6b:	ADD	A,A		; Convert from character to pixel-based coordinates
		ADD	A,A
		ADD	A,A
		LD	(CharCursor+1),A ; Store X coordinate of CharCursor.
		JR	RestorePrintFn


	;; Execute a simple command string to set the cursor position.
SetCursor:	LD	(SetCursorBuf+1),BC
		LD	HL,SetCursorBuf
		JP	PrintChars

SetCursorBuf:	DEFB $06,$00,$00,$FF

	;; Get the string's address, from an index.
GetStrAddr:	LD	B,A
		LD	HL,Strings
		SUB	$60
		JR	C,GSpA_1
		LD	HL,Strings2
		LD	B,A
GSpA_1:		INC	B
	;; Search for Bth occurence of $FF.
		LD	A,$FF
GSpA_2:		LD	C,A
		CPIR
		DJNZ	GSpA_2
		RET

	;; Copy the character, doubling its height, into the buffer
CharDoubler:	LD	B,$08
		LD	HL,CharDoublerBuf
CD_1:		LD	A,(DE)
		LD	(HL),A
		INC	HL
		LD	(HL),A
		INC	HL
		INC	DE
		DJNZ	CD_1
		LD	HL,L1004 	; New width/height - 8 pixels by 16.
		LD	DE,CharDoublerBuf
		RET
