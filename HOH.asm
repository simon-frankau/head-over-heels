	;; 
	;; HOH.asm
	;;
	;; Main Head Over Heels source file
	;;
	;; Glues together all the other assembly files, binaries, etc.
	;; 

#target ROM
#code 0, $10000
	defs $4000, $00

#insert "screen.scr"
	
#include "data_header.asm"

	;; Hack, should be removed.
#include "equs.asm"

MAGIC_OFFSET:	EQU 360 	; The offset high data is moved down by...
	
SpriteBuff:	EQU $B800

	;; The buffer into which we draw the columns doors stand on
ColBuf:		EQU $F944
ColBufLen:	EQU $94

BigSpriteBuf:	EQU $F9D8

#include "mainloop.asm"

C72A0:	XOR		A
		JR		L72A9
C72A3:	LD		A,$FF
		LD		HL,L7305
		PUSH	HL
L72A9:	LD		HL,L7355
		LD		DE,L72EB
		JR		L72BC
L72B1:	XOR		A
		LD		HL,L7B78
		PUSH	HL
		LD		HL,L734B
		LD		DE,L72F3
L72BC:	PUSH	DE
		LD		(L7348+1),HL
		CALL	C7314
		LD		(L72F0),HL
		AND		A
		LD		HL,LFB28
		JR		NZ,L72CD
		EX		DE,HL
L72CD:	EX		AF,AF'
		CALL	C7321
		INC		B
		NOP
		DEC		SP
		LD		(HL),B
		CALL	C7321
		DEC		E
		NOP
		LD		(HL),A
		XOR		A
		CALL	C7321
		ADD		HL,DE
		NOP
		AND		D
		AND		D
		CALL	C7321
		RET		P
		INC		BC
		LD		B,B
		CP		D
		RET
L72EB:	CALL	C7321
		LD		(DE),A
		NOP			
L72F0:		RET		NZ 		; Self-modifying code
		AND		D
		RET
L72F3:	PUSH	DE
		CALL	GetCharObj
		EX		DE,HL
		LD		BC,L0012
		PUSH	BC
		LDIR
		CALL	C7314
		POP		BC
		POP		DE
		LDIR
L7305:		LD		HL,(LAF92) 	; NB: Referenced as data.
		LD		(LAF78),HL
		LD		HL,LAF82
		LD		BC,L0008
		JP		FillZero
	
C7314:		LD		HL,Character
		BIT		0,(HL) 		; Heels?
		LD		HL,HeelsObj	; No Heels case
		RET		Z
		LD		HL,HeadObj 	; Have Heels case
		RET

C7321:	POP		IX
		LD		C,(IX+$00)
		INC		IX
		LD		B,(IX+$00)
		INC		IX
		EX		AF,AF'
		AND		A
		JR		Z,L733B
		LD		E,(IX+$00)
		INC		IX
		LD		D,(IX+$00)
		JR		L7343
L733B:	LD		L,(IX+$00)
		INC		IX
		LD		H,(IX+$00)
L7343:	INC		IX
		EX		AF,AF'
		PUSH	IX
L7348:	JP		L7355	; Self-modifying code
L734B:	LD		A,(DE)
		LDI
		DEC		HL
		LD		(HL),A
		INC		HL
		JP		PE,L734B
		RET
L7355:	LDIR
		RET
C7358:	XOR		A
		RET

	;; Installs the interrupt hook
IrqInstall:	DI
		IM	2
		LD	A,$39		; Page full of FFhs.
		LD	I,A
		LD	A,$18
		LD	(LFFFF),A 	; JR 0xFFF4
		LD	A,$C3		; JP ...
		LD	($FFF4),A
		LD	HL,IrqHandler 	; to IrqHandler
		LD	(LFFF5),HL
		CALL	ShuffleMem
		EI
		RET

	;; The main interrupt hook - calls IrqFn and decrements FrameCounter (if non-zero).
IrqHandler:	PUSH	AF
		PUSH	BC
		PUSH	HL
		PUSH	DE
		PUSH	IX
		PUSH	IY
		CALL	IrqFn
		POP	IY
		POP	IX
		POP	DE
		POP	HL
		POP	BC
		LD	A,(FrameCounter)
		AND	A
		JR	Z,SkipWriteFrame
		DEC	A
		LD	(FrameCounter),A
SkipWriteFrame:	POP	AF
		EI
		RET
	
C7395:		LD	A,$08
		CALL	SetAttribs 	; Set all black attributes
		LD	HL,L4048
		LD	DE,L4857
L73A0:		PUSH	HL
		PUSH	DE
		CALL	CA098
		POP	DE
		POP	HL
		LD	H,L
		LD	A,L
		ADD	A,$14
		LD	L,A
		CP	$C1
		JR	C,L73A0
		LD	HL,L4048
		LD	D,E
		LD	A,E
		ADD	A,$2A
		LD	E,A
		JR	NC,L73A0
		RET

#include "attr_scheme.asm"
	
CHAR_ARR1:	EQU $21
CHAR_ARR2:	EQU $22
CHAR_ARR3:	EQU $23
CHAR_ARR4:	EQU $24
CHAR_LIGHTNING:	EQU $25
CHAR_SPRING:	EQU $26
CHAR_SHIELD:	EQU $27
	
	;; Look up character code (- 0x20 already) to a pointer to the character in DE.
CharCodeToAddr:	CP	$08
		JR	C,CC2A 		; Space ! " # $ % & '
		SUB	$07
		CP	$13
		JR	C,CC2A		; / 0-9
		SUB	$07 		; Alphabetical characters.
CC2A:		ADD	A,A
		ADD	A,A
		LD	L,A
		LD	H,$00
		ADD	HL,HL
		LD	DE,IMG_CHARS - 360
		ADD	HL,DE
		EX	DE,HL
		RET

#include "controls.asm"

	;; In multiples of 6, apparently half the pixel height.
ColHeight:	DEFB $00

	;; Re-fills the column sprite buffer.
FillColBuf:	PUSH	DE
		PUSH	BC
		PUSH	HL
		LD	A,(ColHeight)
		CALL	DrawColBuf
		POP	HL
		POP	BC
		POP	DE
		RET

	;; Pass the column height in A, redraws the column, returns result in DE.
SetColHeight:	LD	(ColHeight),A
	;; NB: Fall through!
	
DrawColBuf:	PUSH	AF
	;; Clear out buffer
		LD	HL,ColBuf
		LD	BC,ColBufLen
		CALL	FillZero
	;; Drawing buffer, reset flip flag.
		XOR	A
		LD	(IsColBufFlipped),A
	;; And set the 'filled' lag.
		DEC	A
		LD	(IsColBufFilled),A
		POP	AF
	;; Zero height? Draw nothing
		AND	A
		RET	Z
	;; Otherwise, draw in reverse from end of buffer...
		LD	DE,ColBuf + ColBufLen - 1
		PUSH	AF
		CALL	DrawColBottom
DrawColLoop:	POP	AF
		SUB	$06
		JR	Z,DrawColTop
		PUSH	AF
		CALL	DrawColMid
		JR	DrawColLoop

DrawColTop:	LD	HL,IMG_ColTop + $23 - MAGIC_OFFSET
		LD	BC,$24
		JR	DrawColLDDR

DrawColMid:	LD	HL,IMG_ColMid + $17 - MAGIC_OFFSET
		LD	BC,L0018
		JR	DrawColLDDR

DrawColBottom:	LD	HL,IMG_ColBottom + $0F - MAGIC_OFFSET
		LD	BC,L0010

DrawColLDDR:	LDDR
		RET

L76DE:	DEFW L76E0
L76E0:	DEFB $00
L76E1:	DEFB $00
L76E2:	DEFB $00
L76E3:	DEFB $00
L76E4:	DEFB $00
L76E5:	DEFB $00
L76E6:	DEFB $00
L76E7:	DEFB $00
L76E8:	DEFB $00
L76E9:	DEFB $00
L76EA:	DEFB $00
L76EB:	DEFB $00
L76EC:	DEFB $00
L76ED:	DEFB $00
L76EE:	DEFB $00
L76EF:	DEFB $00
L76F0:	DEFB $00
L76F1:	DEFB $00
L76F2:	DEFB $00
L76F3:	DEFB $00
L76F4:	DEFB $00
L76F5:	DEFB $00
L76F6:	DEFB $00
L76F7:	DEFB $00
L76F8:	DEFB $00
L76F9:	DEFB $FF
L76FA:	DEFB $FF
L76FB:	DEFB $00
L76FC:	DEFB $00
L76FD:	DEFB $00
L76FE:	DEFB $00
L76FF:	DEFB $00
L7700:	DEFB $00
	
	;; Current pointer to bit-packed data
DataPtr:	DEFW $0000
	;; The remaining bits to read at the current address.
CurrData:	DEFB $00

	;; FIXME: Decode remaining DataPtr/CurrData references...
	
L7704:	DEFB $00
L7705:	DEFB $00
L7706:	DEFB $00
L7707:	DEFB $27
L7708:	DEFB $26
L7709:	DEFB $17
L770A:	DEFB $15
L770B:	DEFB $05
L770C:	DEFB $04
L770D:	DEFB $36
L770E:	DEFB $34
BigSpriteTest:	DEFB $00
L7710:	DEFB $00
FloorCode:	DEFB $00
L7712:	DEFB $00
L7713:	DEFB $00
AttribScheme:	DEFB $00
WorldId:	DEFB $00	; Range 0..7 (I think 7 is 'same as last')
L7716:	DEFB $00
L7717:	DEFB $00
L7718:	DEFB $00
L7719:	DEFB $00
L771A:	DEFB $00
L771B:	DEFB $00
L771C:	DEFB $00
L771D:	DEFB $00
L771E:	DEFB $00
L771F:	DEFB $00
L7720:	DEFB $00
L7721:	DEFB $00
L7722:	DEFB $00
L7723:	DEFB $00

L7724:	DEFB $08,$08,$48,$48
	DEFB $08,$10,$48,$40
	DEFB $08,$18,$48,$38
	DEFB $08,$20,$48,$30
	DEFB $10,$08,$40,$48
	DEFB $18,$08,$38,$48
	DEFB $20,$08,$30,$48
	DEFB $10,$10,$40,$40

L7744:	DEFB $00
L7745:	DEFB $00
L7746:	DEFB $00
L7747:	DEFB $00
L7748:	DEFB $00
L7749:	DEFB $00
L774A:	DEFB $00
L774B:	DEFB $00
L774C:	DEFB $C0
C774D:		LD		A,$FF
		LD		(L7713),A
	;; NB: Fall through

	;; Guess that this is redraw screen, based on setting sprite extend to flul screen...
DrawScreen:	LD	IY,L7718 		; FIXME: ???
	;; Initialise the sprite extents to cover the full screen.
		LD	HL,L40C0
		LD	(SpriteXExtent),HL
		LD	HL,L00FF
		LD	(SpriteYExtent),HL
	;;  FIXME: ???
		LD	HL,LC0C0
		LD	(L7748),HL
		LD	(L774A),HL
		LD	HL,L0000
		LD	BC,(L703B)
		CALL	C780E
		XOR	A
		LD	(L7713),A
		LD	(L774C),A
		LD	HL,(LAF78)
		LD	(LAF92),HL
		LD	A,(L7710)
		LD	(BigSpriteTest),A
		LD	DE,L7744
		LD	HL,L7748
		LD	BC,L0004
		LDIR
	;; Clear the backdrop info...
		LD	HL,BkgndData
		LD	BC,L0040
		CALL	FillZero
		CALL	CA260
		CALL	C7A2E
		LD		A,$00
		RLA
		LD		(L7712),A
		CALL	C84CB
		LD		HL,(L7716)
		PUSH	HL
		LD		A,L
		AND		$08
		JR		Z,L77D0
		LD		A,$01
		CALL	CAF96
		LD		BC,(L703B)
		LD		A,B
		INC		A
		XOR		B
		AND		$0F
		XOR		B
		LD		B,A
		LD		A,(L771B)
		LD		H,A
		LD		L,$00
		CALL	C780E
		CALL	CA260
L77D0:	LD		IY,L7720
		POP		HL
		PUSH	HL
		LD		A,L
		AND		$04
		JR		Z,L77F8
		LD		A,$02
		CALL	CAF96
		LD		BC,(L703B)
		LD		A,B
		ADD		A,$10
		XOR		B
		AND		$F0
		XOR		B
		LD		B,A
		LD		A,(L771A)
		LD		L,A
		LD		H,$00
		CALL	C780E
		CALL	CA260
L77F8:		LD	A,(L774C)
		LD	HL,(L7705)
		PUSH	AF
		CALL	C81DC
		POP	AF
		CALL	SetColHeight
		POP	HL
		LD	(L7716),HL
		XOR	A
		JP	CAF96

	;; FIXME: Called lots
C780E:		LD	(L76E0),HL
		XOR	A
		LD	(L76E2),A
		PUSH	BC
		CALL	C7A45
		LD	B,$03
		CALL	FetchData
		LD	(L7710),A
		ADD	A,A
		ADD	A,A
		ADD	A,L7724 & $FF
		LD	L,A
		ADC	A,L7724 >> 8
		SUB	L
		LD	H,A
		LD	B,$02
		LD	IX,L76E0
L7830:		LD	C,(HL)
		LD	A,(IX+$00)
		AND	A
		JR	Z,L7842
		SUB	C
		LD	E,A
		RRA
		RRA
		RRA
		AND	$1F
		LD	(IX+$00),A
		LD	A,E
L7842:		ADD	A,C
		LD	(IY+$00),A
		INC	HL
		INC	IX
		INC	IY
		DJNZ	L7830
	;; Do this bit twice:
		LD		B,$02
L784F:		LD		A,(IX-$02)
		ADD		A,A
		ADD		A,A
		ADD		A,A
		ADD		A,(HL)
		LD		(IY+$00),A
		INC		IY
		INC		IX
		INC		HL
		DJNZ		L784F
	;; Now update some stuff off FetchData:
		LD	B,$03
		CALL	FetchData
		LD	(AttribScheme),A	; Fetch the attribute scheme to use.
		LD	B,$03
		CALL	FetchData
		LD	(WorldId),A 		; Fetch the current world identifier
		CALL	C7934
		LD	B,$03
		CALL	FetchData
		LD	(FloorCode),A 		; And the floor pattern to use
		CALL	SetFloorAddr
	;; FIXME
L787E:		CALL	C78D4
		JR		NC,L787E
		POP		BC
		JP		L8778
C7887:	BIT		2,A
		JR		Z,L788D
		OR		$F8
L788D:	ADD		A,(HL)
		RET
L788F:	EX		AF,AF'
		CALL	C7AF3
		LD		HL,(L76DE)
		PUSH	AF
		LD		A,B
		CALL	C7887
		LD		B,A
		INC		HL
		LD		A,C
		CALL	C7887
		LD		C,A
		INC		HL
		POP		AF
		SUB		$07
		ADD		A,(HL)
		INC		HL
		LD		(L76DE),HL
		LD		(HL),B
		INC		HL
		LD		(HL),C
		INC		HL
		LD		(HL),A

	;; Save the current data pointer, do some stuff, restore.
		LD	A,(CurrData)
		LD	HL,(DataPtr)
		PUSH	AF
		PUSH	HL
		CALL	C7A1C
		LD	(DataPtr),HL
L78BE:		CALL	C78D4
		JR	NC,L78BE
		LD	HL,(L76DE)
		DEC	HL
		DEC	HL
		DEC	HL
		LD	(L76DE),HL
		POP	HL
		POP	AF
		LD	(DataPtr),HL
		LD	(CurrData),A
	;; NB: Fall through.
	
C78D4:		LD	B,$08
		CALL	FetchData
		CP	$FF
		SCF
		RET	Z
		CP	$C0
		JR	NC,L788F
		PUSH	IY
		LD	IY,L76EE
		CALL	C8232
		POP	IY
		LD	B,$02
		CALL	FetchData
		BIT	1,A
		JR	NZ,L78F9
		LD	A,$01
		JR	L7903
L78F9:		PUSH	AF
		LD	B,$01
		CALL	FetchData
		POP	BC
		RLCA
		RLCA
		OR	B
L7903:		LD	(L7700),A
L7906:		CALL	C7A8D
		CALL	C7AC1
		LD	A,(L7700)
		RRA
		JR	NC,L791D
		LD	A,(L7704)
		INC	A
		AND	A
		RET	Z
		CALL	C7922
		JR		L7906
L791D:		CALL	C7922
		AND	A
		RET

	
C7922:	LD		HL,L76EE
		LD		BC,L0012
		PUSH	IY
		LD		A,(L7713)
		AND		A
		CALL	Z,LAFC6
		POP		IY
		RET

C7934:		LD	B,$03
		CALL	FetchData
		CALL	C7358
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
		CALL	C79B1
		LD	HL,L7749
		EXX
		LD	A,(IY-$02)
		ADD	A,$04
		CALL	C79A5
		LD	HL,L774A
		EXX
		LD	A,(IY-$03)
		SUB	$04
		CALL	C79B1
		LD	HL,L774B
		EXX
		LD	A,(IY-$04)
		SUB	$04
		JP	C79A5		; Tail call
	
C7977:	LD		B,$03
		CALL	FetchData
		LD		HL,L7716
		SUB		$02
		JR		C,L799A
		RL		(HL)
		INC		HL
		SCF
		RL		(HL)
		SUB		$07
		NEG
		LD		C,A
		ADD		A,A
		ADD		A,C
		ADD		A,A
		ADD		A,$96
		LD		(L76F5),A
		SCF
		EXX
		LD		(HL),A
		RET
L799A:	CP		$FF
		CCF
		RL		(HL)
		AND		A
		INC		HL
		RL		(HL)
		AND		A
		RET
C79A5:	LD		(L76F3),A
		LD		HL,L76F4
		LD		A,(L76E1)
		JP		L79BA
C79B1:	LD		(L76F4),A
		LD		HL,L76F3
		LD		A,(L76E0)
L79BA:	ADD		A,A
		ADD		A,A
		ADD		A,A
		PUSH	AF
		ADD		A,$24
		LD		(HL),A
		PUSH	HL
		CALL	C7977
		JR		NC,L7A15
		LD		A,(IX+$00)
		LD		(L76F2),A
		INC		IX
		LD		A,(L7705)
		LD		(L76F6),A
		CALL	C79EB
		LD		A,(IX+$00)
		LD		(L76F2),A
		INC		IX
		LD		A,(L7706)
		LD		(L76F6),A
		POP		HL
		POP		AF
		ADD		A,$2C
		LD		(HL),A
C79EB:	CALL	C7922
		LD		A,(L76F2)
		LD		C,A
		AND		$30
		RET		PO
		AND		$10
		OR		$01
		LD		(L76F2),A
		LD		A,(L76F5)
		CP		$C0
		RET		Z
		PUSH	AF
		ADD		A,$06
		LD		(L76F5),A
		LD		A,$54
		LD		(L76F6),A
		CALL	C7922
		POP		AF
		LD		(L76F5),A
		RET
L7A15:	POP		HL
		POP		AF
		INC		IX
		INC		IX
		RET

	
C7A1C:		LD		A,$80
		LD		(CurrData),A 	; Clear buffered byte.
	;; Get the size of some buffer thing: Start at L5B00, just after attributes.
	;; Take first byte as step size, then scan at that step size until we find a zero.
	;; Return in HL.
		LD		HL,L5B00
		EX		AF,AF'
		LD		D,$00
L7A27:		LD		E,(HL)
		INC		HL
		CP		(HL)
		RET		Z
		ADD		HL,DE
		JR		L7A27

	
C7A2E:	LD		BC,(L703B)
		LD		A,C
		DEC		A
		AND		$F0
		LD		C,A
		CALL	C7A4E
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
	
C7A45:	CALL	C7A4E
		EXX
		LD		A,C
		OR		(HL)
		LD		(HL),A
		EXX
		RET

C7A4E:	LD		D,$00
		LD		HL,L5C71
		CALL	C7A5C
		RET		NC
		LD		HL,L6B16
		JR		L7A63
	
C7A5C:		EXX
		LD		HL,L8AE2
		LD		C,$01
		EXX
	
L7A63:		LD		E,(HL)
		INC		E
		DEC		E
		SCF
		RET		Z
		INC		HL
		LD		A,B
		CP		(HL)
		JR		Z,L7A77

L7A6D:		ADD		HL,DE
		EXX
		RLC		C
		JR		NC,L7A74
		INC		HL
L7A74:		EXX
		JR		L7A63
	
L7A77:		INC		HL
		DEC		E
		LD		A,(HL)
		AND		$F0
		CP		C
		JR		NZ,L7A6D
		DEC		HL
	;; Initialise DataPtr and CurrData for new data.
		LD		(DataPtr),HL
		LD		A,$80
		LD		(CurrData),A
		LD		B,$04
		JP		FetchData

C7A8D:		LD		A,(L7700)
		RRA
		RRA
		JR		C,L7A99
		LD		B,$01
		CALL	FetchData
L7A99:	AND		$01
		RLCA
		RLCA
		RLCA
		RLCA
		AND		$10
		LD		C,A
		LD		A,(L76ED)
		XOR		C
		LD		(L76F2),A
		LD		BC,(L76EC)
		BIT		4,A
		JR		Z,L7ABC
		BIT		1,A
		JR		Z,L7ABA
		XOR		$01
		LD		(L76F2),A
L7ABA:	DEC		C
		DEC		C
L7ABC:	LD		A,C
		LD		(L76FE),A
		RET
C7AC1:	CALL	C7AF3
C7AC4:	EX		AF,AF'
		LD		HL,(L76DE)
		LD		DE,L76F3
C7ACB:	LD		A,B
		CALL	C7AEB
		LD		(DE),A
		LD		A,C
		CALL	C7AEB
		INC		DE
		LD		(DE),A
		EX		AF,AF'
		PUSH	AF
		ADD		A,(HL)
		LD		L,A
		ADD		A,A
		ADD		A,L
		ADD		A,A
		ADD		A,$96
		INC		DE
		LD		(DE),A
		POP		AF
		CPL
		AND		C
		AND		B
		OR		$F8
		LD		(L7704),A
		RET
C7AEB:	ADD		A,(HL)
		INC		HL
		RLCA
		RLCA
		RLCA
		ADD		A,$0C
		RET
C7AF3:	LD		B,$03
		CALL	FetchData
		PUSH	AF
		LD		B,$03
		CALL	FetchData
		PUSH	AF
		LD		B,$03
		CALL	FetchData
		POP		HL
		POP		BC
		LD		C,H
		RET
	
InitStuff:	CALL	IrqInstall
		JP	InitRevTbl

InitNewGame:	XOR	A
		LD	(L866B),A
		LD	(LB218),A
		LD	(Continues),A
		LD	A,$18
		LD	(LA2C8),A
		LD	A,$1F
		LD	(LA2DA),A
		CALL	InitNewGame1
		CALL	Reinitialise
		DEFW	StatusReinit
		CALL	InitNewGame2
		LD	HL,L8940
		LD	(L703B),HL
		LD	A,$01
		CALL	C7B43
		LD	HL,L8A40
		LD	(L703B),HL
		XOR	A
		LD	(LB218),A
		RET

C7B43:		LD	(Character),A
		PUSH	AF
		LD	(LFB28),A
		CALL	C7BBF
		XOR	A
		LD	(LA297),A
		CALL	CharThing15
		JR	L7B59		; Tail call

L7B56:		CALL	CharThing
L7B59:		LD	A,(LA2BC)
		AND	A
		JR	NZ,L7B56
		POP	AF
		XOR	$03
		LD	(Character),A
		CALL	CharThing3
		JP	C72A0		; Tail call

InitContinue:	CALL	Reinitialise
		DEFW	StatusReinit
		LD	A,$08
		CALL	UpdateAttribs	; Blacked-out attributes
		JP	DoContinue	; Tail call

L7B78:		CALL	C774D
		CALL	Reinitialise
		DEFW	ReinitThing
		CALL	SetCharThing
		CALL	C7C1A
		CALL	C7395
		XOR	A
		LD	(LA295),A
		JR	C7BB3		; Tail call

L7B8F:	DEFB $00
WorldIdSnd:	DEFB $00

	;; NB: Called from main loop...
C7B91:		CALL	C7BBF
		LD	A,(MENU_SOUND)
		AND	A
		JR	NZ,L7BAD
		LD	A,(WorldId)
		CP	$07
		JR	NZ,L7BA4
		LD	A,(WorldIdSnd)
L7BA4:		LD	(WorldIdSnd),A
		OR	$40
		LD	B,A
		CALL	PlaySound
L7BAD:		CALL	C7395
		CALL	CharThing15
	;; NB: Fall through

C7BB3:		LD	A,(AttribScheme)
		CALL	UpdateAttribs
		CALL	PrintStatus
		JP	DrawScreenPeriphery		; Tail call

C7BBF:		CALL	Reinitialise
		DEFW	LAF5B
		CALL	Reinitialise
		DEFW	ReinitThing
		LD	A,(Character)
		CP	$03
		JR	NZ,L7BDC
		LD	HL,LFB28
		SET	0,(HL)
		CALL	DrawScreen
		LD	A,$01
		JR	L7C14
L7BDC:		CALL	C728C
		JR	NZ,L7C10
		CALL	C72A3
		CALL	C774D
		LD	HL,HeelsObj
		CALL	GetUpdatedCoords
		EXX
		LD	HL,HeadObj
		CALL	GetUpdatedCoords
		CALL	CheckOverlap
		JR	NC,L7C0C
		LD	A,(Character)
		RRA
		JR	C,L7C00
		EXX
L7C00:		LD	A,B
		ADD	A,$05
		EXX
		CP	B
		JR	C,L7C0C
		LD	A,$FF
		LD	(L7B8F),A
L7C0C:		LD	A,$01
		JR	L7C14
L7C10:		CALL	DrawScreen
		XOR	A
L7C14:		LD	(LA295),A
		JP	C7C1A


	;;    ^
	;;   / \
	;;  /   \
	;; H     L
	
C7C1A:		LD	HL,(L7718)
		LD	A,(L7717)
		PUSH	AF
		BIT	1,A
		JR	Z,L7C29
		DEC	H
		DEC	H
		DEC	H
		DEC	H
L7C29:		RRA
		LD		A,L
		JR		NC,L7C30
		SUB		$04
		LD		L,A
L7C30:		SUB		H
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
		CALL		FloorFn
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

	;; A funky shuffle routine: Load a pointer from the top of stack.
	;; (i.e. our return address contains data to skip over)
	;; The pointed value points to a size. We copy that much data
	;; from directly after it to a size later.
	;; i.e. 5 A B C D E M N O P Q becomes 5 A B C D E A B C D E.
	;; Useful for reinitialising structures.
Reinitialise:
	;; Dereference top of stack into HL, incrementing pointer
		POP	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		INC	HL
		PUSH	HL
		EX	DE,HL
	;; Dereference /that/ into bottom of BC
		LD		C,(HL)
		LD		B,$00
	;; Then increment HL and set DE = HL + BC
		INC		HL
		LD		D,H
		LD		E,L
		ADD		HL,BC
		EX		DE,HL
	;; Finally LDIR
		LDIR
		RET
	
#include "menus.asm"
	
C81DC:	PUSH	AF
		LD		A,L
		LD		H,$00
		LD		(SpriteCode),A
		CALL	Sprite3x56
		EX		DE,HL
		LD		DE,BigSpriteBuf
		PUSH	DE
		LD		BC,L0150
		LDIR
		POP		HL
		POP		AF
		ADD		A,A
		ADD		A,$08
		CP		$39
		JR		C,L81FB
		LD		A,$38
L81FB:	LD		B,A
		ADD		A,A
		ADD		A,B
		LD		E,A
		LD		D,$00
		ADD		HL,DE
		EX		DE,HL
		LD		HL,L00A8
		ADD		HL,DE
		LD		A,B
		NEG
		ADD		A,$39
		LD		B,A
		LD		C,$FC
		JR		L8224
L8211:	LD		A,(DE)
		AND		C
		LD		(DE),A
		INC		DE
		INC		DE
		INC		DE
		LD		A,C
		CPL
		OR		(HL)
		LD		(HL),A
		INC		HL
		INC		HL
		INC		HL
		AND		A
		RL		C
		AND		A
		RL		C
L8224:	DJNZ	L8211
		XOR		A
		LD		(BigSpriteFlipped),A
		RET
CurrObject:	DEFW $0000
L822D: 	DEFB $FF
L822E:	DEFW $3D00,$3D8E
C8232:	LD		(IY+$09),$00
		LD		L,A
		LD		E,A
		LD		D,$00
		LD		H,D
		ADD		HL,HL
		ADD		HL,DE
		LD		DE,L8406
		ADD		HL,DE
		LD		B,(HL)
		INC		HL
		LD		A,(HL)
		AND		$3F
		LD		(IY+$0A),A
		LD		A,(HL)
		INC		HL
		RLCA
		RLCA
		AND		$03
		JR		Z,L8264
		ADD		A,L822E & $FF
		LD		E,A
		ADC		A,L822E >> 8
		SUB		E
		LD		D,A
		LD		A,(DE)
		SET		5,(IY+$09)
		BIT		2,(HL)
		JR		Z,L8264
		LD		C,B
		LD		B,A
		LD		A,C
L8264:	LD		(L822E),A
		LD		A,B
		CALL	C828B
		LD		A,(HL)
		OR		$9F
		INC		A
		LD		A,(HL)
		JR		NZ,L8278
		SET		7,(IY+$09)
		AND		$BF
L8278:	AND		$FB
		CP		$80
		RES		7,A
		LD		(IY-$01),A
		LD		(IY-$02),$02
		RET		C
		SET		4,(IY+$09)
		RET
C828B:	LD		(IY+$0F),$00
		LD		(IY+$08),A
		CP		$80
		RET		C
		ADD		A,A
		ADD		A,A
		ADD		A,A
		LD		(IY+$0F),A
		PUSH	HL
		CALL	C82E8
		POP		HL
		RET

	;; Takes an object pointer in DE, and index thing in A
CallObjFn:	LD	(CurrObject),DE
		PUSH	DE
		POP	IY
		DEC	A
	;; Get word from ObjFnTbl[A] into HL.
		ADD	A,A
		ADD	A, ObjFnTbl & $FF
		LD	L,A
		ADC	A,ObjFnTbl >> 8
		SUB	L
		LD	H,A
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
	;; Do some stuff...
		XOR	A
		LD	(L8ED8),A
		LD	A,(IY+$0B)
		LD	(L822D),A
		LD	(IY+$0B),$FF
		BIT	6,(IY+$09)
		RET	NZ
	;; And function table jump
		JP	(HL)

C82C9:		BIT		5,(IY+$09)
		JR		Z,C82E8
		CALL	C82E8
		EX		AF,AF'
		LD		C,(IY+$10)
		LD		DE,L0012
		PUSH	IY
		ADD		IY,DE
		CALL	C938D
		CALL	C82E8
		POP		IY
		RET		C
		EX		AF,AF'
		RET
	
C82E8:	LD		C,(IY+$0F)
		LD		A,C
		AND		$F8
		CP		$08
		CCF
		RET		NC
		RRCA
		RRCA
		SUB		$02
		ADD		A,$30
		LD		L,A
		ADC		A,$83
		SUB		L
		LD		H,A
		LD		A,C
		INC		A
		AND		$07
		LD		B,A
		ADD		A,(HL)
		LD		E,A
		INC		HL
		ADC		A,(HL)
		SUB		E
		LD		D,A
		LD		A,(DE)
		AND		A
		JR		NZ,L8313
		LD		B,$00
		LD		A,(HL)
		DEC		HL
		LD		L,(HL)
		LD		H,A
		LD		A,(HL)
L8313:	LD		(IY+$08),A
		LD		A,B
		XOR		C
		AND		$07
		XOR		C
		LD		(IY+$0F),A
		AND		$F0
		CP		$80
		LD		C,$02
		JR		Z,L832A
		CP		$90
		LD		C,$01
L832A:	LD		A,C
		CALL	Z,CharThing11
		SCF
		RET
L8330:	DEFB $6E,$83,$73,$83,$75,$83,$77,$83,$77,$83,$7C,$83,$7C,$83,$81,$83
L8340:	DEFB $81,$83,$84,$83,$84,$83,$8A,$83,$8F,$83,$94,$83,$94,$83,$9B,$83
L8350:	DEFB $9D,$83,$9F,$83,$9F,$83,$A4,$83,$A4,$83,$A7,$83,$A9,$83,$AB,$83
L8360:	DEFB $AD,$83,$AF,$83,$B1,$83,$B3,$83,$B5,$83,$B7,$83,$B7,$83,$A4,$24
L8370:	DEFB $25,$26,$00,$10,$00,$11,$00,$24,$25,$25,$24,$00,$2D,$2D,$2E,$2E
L8380:	DEFB $00,$57,$D7,$00,$2B,$2B,$2C,$2B,$2C,$00,$32,$32,$33,$33,$00,$34
L8390:	DEFB $34,$35,$35,$00,$26,$25,$26,$A6,$A5,$A6,$00,$36,$00,$37,$00,$38
L83A0:	DEFB $39,$B9,$B8,$00,$3A,$BA,$00,$3B,$00,$3C,$00,$3E,$00,$3F,$00,$40
L83B0:	DEFB $00,$41,$00,$42,$00,$43,$00,$44,$45,$C5,$C4,$00

	;; Table has base index of 1 in CallObjFn
ObjFnTbl:
	DEFW ObjFn1, ObjFn2, ObjFn3, ObjFn4
	DEFW ObjFn5, ObjFn6, ObjFn7, ObjFn8
	DEFW ObjFn9, ObjFn10,ObjFn11,ObjFn12
	DEFW ObjFn13,ObjFn14,ObjFn15,ObjFn16
	DEFW ObjFn17,ObjFn18,ObjFn19,ObjFn20
	DEFW ObjFn21,ObjFn22,ObjFn23,ObjFn24
	DEFW ObjFn25,ObjFn26,ObjFn27,ObjFn28
	DEFW ObjFn29,ObjFn30,ObjFn31,ObjFn32
	DEFW ObjFn33,ObjFn34,ObjFn35,ObjFn36
	DEFW ObjFn37

L8406:	DEFB $88,$1B,$01,$2B,$1C,$40,$31,$00,$02,$4A
L8410:	DEFB $01,$40,$9E,$17,$00,$5D,$00,$01,$56,$02,$11,$56,$03,$11,$56,$04
L8420:	DEFB $01,$56,$05,$01,$46,$01,$40,$4B,$01,$40,$90,$8F,$6C,$4C,$0A,$00
L8430:	DEFB $58,$00,$21,$5E,$00,$21,$30,$0E,$00,$94,$09,$60,$96,$4F,$6C,$9A
L8440:	DEFB $DD,$0C,$49,$1E,$00,$5A,$01,$01,$5F,$00,$01,$5F,$14,$01,$48,$00
L8450:	DEFB $00,$92,$0B,$60,$31,$18,$02,$82,$06,$68,$84,$CC,$6C,$47,$0A,$20
L8460:	DEFB $5C,$1F,$01,$55,$15,$01,$96,$CD,$6C,$5B,$00,$21,$5D,$14,$01,$59
L8470:	DEFB $14,$01,$59,$00,$01,$3D,$20,$60,$92,$21,$60,$9E,$12,$00,$55,$01
L8480:	DEFB $01,$5F,$13,$01,$8C,$07,$60,$5A,$16,$01,$5D,$08,$01,$55,$23,$01
L8490:	DEFB $9C,$CD,$6C,$42,$00,$20,$47,$0A,$00,$2D,$00,$20,$56,$14,$01,$5D
L84A0:	DEFB $0A,$01,$5D,$01,$01,$98,$4F,$6C,$98,$CD,$6C,$82,$08,$68,$36,$00
L84B0:	DEFB $20,$37,$00,$20,$1E,$00,$00,$18,$00,$00,$4C,$24,$00,$4C,$A5,$2C
L84C0:	DEFB $84,$21,$60
PanelBase:	DEFW $0000
PanelFlipsPtr:	DEFW $0000	; Pointer to byte full of whether panels need to flip
L84C7:	DEFB $00
L84C8:	DEFB $00
L84C9:	DEFB $00
L84CA:	DEFB $00
C84CB:	CALL	C8603
		LD		A,C
		SUB		$06
		LD		C,A
		ADD		A,B
		RRA
		LD		(L84C7),A
		LD		A,B
		NEG
		ADD		A,C
		RRA
		LD		(L84C8),A
		LD		A,B
		LD		(L84C9),A
		RET
	
L84E4:		LD	(L84CA),A
		CALL	C8506
		LD	A,(L7716)
		AND	$04
		RET	NZ
		LD	B,$04
		EXX
		LD	A,$80
		LD	(L8591+1),A
		CALL	C8603
		LD	DE,L0002
		LD	A,(IY-$01)
		SUB	(IY-$03)
		JR	L8521
C8506:		LD	A,(L7716)
		AND	$08
		RET	NZ
		LD	B,$08
		EXX
		XOR	A
		LD	(L8591+1),A
		CALL	C8603
		DEC	L
		DEC	L
		LD	DE,LFFFE
		LD	A,(IY-$02)
		SUB	(IY-$04)
	;; NB: Fall through

L8521:		RRA
		RRA
		RRA
		RRA
		AND	$0F
		PUSH	HL
		POP	IX
		EXX
		LD	C,A
		LD	A,(L7717)
		AND	B
		CP	$01
		EX	AF,AF'
	;; WorldId-based configuration...
		LD	A,(WorldId)
		LD	B,A
	;; Put $C038 + WorldId into $84C5.
		ADD	A,$38
		LD	L,A
		ADC	A,$C0
		SUB	L
		LD	H,A
		LD	(PanelFlipsPtr),HL
	;; Update DataPtr etc. for FetchData.
		LD	A,B
		ADD	A,A
		LD	B,A 		; B updated to 2x
		ADD	A,A
		ADD	A,A   		; A is 8x
		ADD	A,$2A
		LD	L,A
		ADC	A,$86
		SUB	L
		LD	H,A   		; HL is $862A + 8xWorldId (data starts at $862B=WorldData)
		LD	(DataPtr),HL
		LD	A,$80
		LD	(CurrData),A
	;; Update PanelBase
		LD	A,$1B
		ADD	A,B
		LD	L,A
		ADC	A,$86
		SUB	L
		LD	H,A 		; HL is $861B (aka PanelBases) + 2xWorldId
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		LD	(PanelBase),HL	; Set the panel codes for the current world.
	;; FIXME
		LD	A,$FF
		EX	AF,AF'
		LD	A,C
		PUSH	AF
		SUB	$04
		LD	B,$01
		JR	Z,L857B
		LD	B,$0F
		INC	A
		JR	Z,L857B
		LD	B,$19
		INC	A
		JR	Z,L857B
		LD	B,$1F
L857B:		POP	AF
		JR	C,L8584
		LD	A,C
		ADD	A,A
		ADD	A,B
		LD	B,A
		LD	A,C
		EX	AF,AF'
L8584:		CALL	FetchData2b
		DJNZ	L8584
		LD	B,C
		SLA	B
L858C:		EX	AF,AF'
		DEC	A
		JR	Z,L85C2
		EX	AF,AF'
L8591:		OR	$00	; NB: Target of self-modifying code.
		LD	(IX+$01),A
		EXX
		LD	A,C
		ADD	A,$08
		LD	(IX+$00),C
		LD	C,A
		ADD	IX,DE
		EXX
		CALL	FetchData2b
L85A4:		DJNZ	L858C
		EXX
		PUSH	IX
		POP	HL
		LD	A,L
		CP	$40
		RET	NC
		LD	A,(IX+$00)
		AND	A
		RET	NZ
		LD	A,(L8591+1)
		OR	$05
		LD	(IX+$01),A
		LD	A,C
		SUB	$10
		LD	(IX+$00),A
		RET
L85C2:		EXX
		LD	A,(L84CA)
		AND	A
		LD	A,C
		JR	Z,L85CD
		ADD	A,$10
		LD	C,A
L85CD:		SUB	$10
		LD	(IX+$00),A
		LD	A,(L8591+1)
		OR	$04
		LD	(IX+$01),A
		ADD	IX,DE
		LD	(IX+$01),A
		LD	A,C
		SUB	$08
		LD	(IX+$00),A
		ADD	A,$18
		LD	C,A
		LD	A,(L84CA)
		AND	A
		JR	Z,L85F2
		LD	A,C
		SUB	$10
		LD	C,A
L85F2:		ADD	IX,DE
		LD	A,$FF
		EX	AF,AF'
		EXX
		DEC	B
		JR	L85A4

	;; Call FetchData for 2 bits
FetchData2b:	PUSH	BC
		LD	B,$02
		CALL	FetchData
		POP	BC
		RET

C8603:	LD		A,(IY-$02)
		LD		D,A
		LD		E,(IY-$01)
		SUB		E
		ADD		A,$80
		LD		B,A
		RRA
		RRA
		AND		$3E
		LD		L,A
		LD		H,BkgndData >> 8
		LD		A,$07
		SUB		E
		SUB		D
		LD		C,A
		RET

PanelBases:	DEFW $C050,$C1A0,$C2F0,$C3D0,$C4B0,$C670,$C750,$C8A0
	;; 8-byte chunks referenced by setting DataPtr etc.
WorldData:	DEFB $46,$91,$65,$94,$A1,$69,$69,$AA
		DEFB $49,$24,$51,$49,$12,$44,$92,$A4
		DEFB $04,$10,$10,$41,$04,$00,$44,$00
		DEFB $04,$10,$10,$41,$04,$00,$10,$00
		DEFB $4E,$31,$B4,$E7,$4E,$42,$E4,$99
		DEFB $45,$51,$50,$51,$54,$55,$55,$55
		DEFB $64,$19,$65,$11,$A4,$41,$28,$55
		DEFB $00,$00,$00,$00,$00,$00,$00,$00
L866B:	DEFB $00
L866C:	DEFB $70,$14,$00,$72,$60,$30,$01,$40,$B0,$2E,$09,$34,$B0,$00,$1A
L867B:	DEFB $00,$F0,$9A,$0B,$70,$40,$A7,$1C,$44,$30,$37,$7D,$37,$70,$15,$68
L868B:	DEFB $34,$60,$89,$48,$47,$60,$C5,$68,$76,$80,$1B,$68,$76,$D0,$BC,$28
L869B:	DEFB $35,$D0,$1C,$28,$71,$F0,$87,$38,$74,$20,$FB,$28,$71,$60,$31,$48
L86AB:	DEFB $05,$C0,$E2,$38,$54,$20,$69,$68,$07,$60,$52,$62,$77,$60,$47,$72
L86BB:	DEFB $27,$C0,$E3,$42,$07,$F0,$63,$12,$70,$20,$AA,$22,$05,$30,$6C,$22
L86CB:	DEFB $46,$60,$47,$73,$57,$80,$FA,$63,$67,$F0,$70,$13,$60,$10,$7B,$73
L86DB:	DEFB $31,$60,$64,$74,$70,$80,$1A,$44,$45,$F0,$46,$74,$74,$60,$C5,$66
L86EB:	DEFB $74,$70,$98,$76,$00,$00,$32,$76,$50,$80,$29,$76,$40,$A0,$E0,$16
L86FB:	DEFB $40,$A0,$0F,$66,$47,$B0,$03,$26,$44,$F0,$83,$36,$17,$40,$8A,$06
L870B:	DEFB $06,$20,$99,$76,$14,$60,$C5,$65,$75,$60,$77,$75,$44,$00,$36,$75
L871B:	DEFB $66,$A0,$FE,$75,$22,$F0,$42,$65,$61,$20,$AE,$75,$04
L8728:	DEFB $30,$8D,$7E
L872B:	DEFB $47,$30,$8D,$6E,$17,$30,$8D,$7E,$07,$30,$8D,$6E,$37,$30,$8D,$3E
L873B:	DEFB $27,$27,$28,$29,$2A,$2A,$2A,$2A,$00,$86,$2F,$2F,$2F,$2F,$2F,$2F

C874B:	LD		BC,(L703B)
C874F:	LD		HL,L866C
		LD		E,$34
L8754:	LD		A,C
		CP		(HL)
		INC		HL
		JR		NZ,C875C
		LD		A,B
		CP		(HL)
		RET		Z
C875C:	INC		HL
		INC		HL
		INC		HL
		DEC		E
		JR		NZ,L8754
		DEC		E
L8763:		RET		; FIXME: Self-modifying code??
C8764:	INC		HL
		XOR		A
		RLD
		LD		E,A
		RLD
		LD		D,A
		RLD
		INC		HL
		RLD
		LD		B,A
		RLD
		LD		C,A
		RLD
		RET
L8778:	PUSH	BC
		LD		HL,L8728
		LD		A,(L866B)
		CPL
		LD		B,$05
		LD		DE,L0004
L8785:	RR		(HL)
		RRA
		RL		(HL)
		ADD		HL,DE
		DJNZ	L8785
		POP		BC
		CALL	C874F
L8791:	RET		NZ
		PUSH	HL
		PUSH	DE
		PUSH	BC
		PUSH	IY
		CALL	C8764
		LD		IY,L76EE
		LD		A,D
		CP		$0E
		LD		A,$60
		JR		NZ,L87A6
		XOR		A
L87A6:	LD		(IY+$04),A
		LD		(IY+$11),D
		LD		(IY+$0A),$1A
		LD		A,D
		ADD		A,$3C
		LD		L,A
		ADC		A,$87
		SUB		L
		LD		H,A
		LD		A,(HL)
		PUSH	BC
		PUSH	DE
		CALL	C828B
		POP		DE
		POP		BC
		POP		IY
		LD		A,E
		CALL	C7AC4
		CALL	C7922
		POP		BC
		POP		DE
		POP		HL
		CALL	C875C
		JR		L8791
InitNewGame2:	LD		HL,L866C
		LD		DE,L0004
		LD		B,$34
L87D9:	RES		0,(HL)
		ADD		HL,DE
		DJNZ	L87D9
		RET
L87DF:	LD		D,A
		CALL	C874B
L87E3:	RET		NZ
		INC		HL
		LD		A,(HL)
		DEC		HL
		AND		$0F
		CP		D
		JR		Z,L87F1
		CALL	C875C
		JR		L87E3
L87F1:	DEC		HL
		SET		0,(HL)
		ADD		A,A
		ADD		A,$0A
		LD		L,A
		ADC		A,$88
		SUB		L
		LD		H,A
		LD		E,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,E
		LD		IX,L8805
		JP		(HL)
L8805:		LD		B,$C5 ; Self-modifying code?
		JP		PlaySound
L880A:	LD		H,$88
		LD		H,$88
		DEC		(HL)
		ADC		A,B
		LD		B,H
		ADC		A,B
		LD		C,L
		ADC		A,B
		LD		E,C
		ADC		A,B
		LD		E,L
		ADC		A,B
		NOP
		NOP
		AND		(HL)
		ADC		A,B
		SUB		L
		ADC		A,B
		SUB		L
		ADC		A,B
		SUB		L
		ADC		A,B
		SUB		L
		ADC		A,B
		SUB		L
		ADC		A,B
		LD		A,D
	;; NB: Fall through

	;; Pick up an inventory item. Item number in A.
PickUp:		LD	HL,Inventory
		CALL	SetBit
		CALL	DrawScreenPeriphery
		LD	B,$C2
		JP	PlaySound

#include "status.asm"
	
L8ADC:	DEFB $00,$00
L8ADE:	DEFB $00
L8ADF:	DEFB $00,$00,$00
L8AE2:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8AEE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8AFE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B0E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B1E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B2E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B3E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B4E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B5E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B6E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B7E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B8E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8B9E:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BAE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BBE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BCE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BDE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BEE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8BFE:	DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
L8C0E:	DEFB $00

	;; FIXME: Run out of donuts
C8C0F:		LD		HL,Inventory
		RES		2,(HL)
L8C14:	EXX
		LD		BC,L0001
		JR		L8C26
C8C1A:	LD		HL,L866B
		JR		L8C14
C8C1F:	LD		HL,L8AE2
		EXX
		LD		BC,L012D
L8C26:	EXX
		LD		DE,L0000
		EXX
L8C2B:	EXX
		LD		C,(HL)
		SCF
		RL		C
L8C30:	LD		A,E
		ADC		A,$00
		DAA
		LD		E,A
		LD		A,D
		ADC		A,$00
		DAA
		LD		D,A
		SLA		C
		JR		NZ,L8C30
		INC		HL
		EXX
		DEC		BC
		LD		A,B
		OR		C
		JR		NZ,L8C2B
		EXX
		RET
InitNewGame1:	LD		HL,L8AE2
		LD		BC,L012D
		JP		FillZero
C8C50:	CALL	C708B
		PUSH	AF
		CALL	C8C1F
		POP		AF
		LD		HL,L0000
		JR		NZ,L8C69
		LD		HL,L0501
		LD		A,(LA295)
		AND		A
		JR		Z,L8C69
		LD		HL,L1002
L8C69:	LD		BC,L0010
		CALL	C8C82
		PUSH	HL
		CALL	C8C0F
		POP		HL
		LD		BC,L01F4
		CALL	C8C82
		PUSH	HL
		CALL	C8C1A
		POP		HL
		LD		BC,L027C
C8C82:	LD		A,E
		ADD		A,L
		DAA
		LD		L,A
		LD		A,H
		ADC		A,D
		DAA
		LD		H,A
		DEC		BC
		LD		A,B
		OR		C
		JR		NZ,C8C82
		RET

	;; Given a direction bitmask in A, return a direction code.
LookupDir:	AND		$0F
		ADD		A,DirTable & $FF
		LD		L,A
		ADC		A,DirTable >> 8
		SUB		L
		LD		H,A
		LD		A,(HL)
		RET

	;; Input into this look-up table is the 4-bit bitmask:
	;; Left Right Down Up.
	;; 
	;; Combinations are mapped to the following directions:
	;;
	;; $05 $04 $03
	;; $06 $FF $02
	;; $07 $00 $01
	;;
DirTable:	DEFB $FF,$00,$04,$FF,$06,$07,$05,$06
		DEFB $02,$01,$03,$02,$FF,$00,$04,$FF
	
	
C8CAB:	LD		L,A
		ADD		A,A
		ADD		A,L
		ADD		A,$BB
		LD		L,A
		ADC		A,$8C
		SUB		L
		LD		H,A
		LD		C,(HL)
		INC		HL
		LD		B,(HL)
		INC		HL
		LD		A,(HL)
		RET
L8CBB:	DEFB $FF,$00,$0D,$FF,$FF,$09,$00,$FF,$0B,$01,$FF,$0A,$01,$00,$0E,$01
L8CCB:	DEFB $01,$06,$00,$01,$07,$FF,$01,$05
C8CD3:	LD		HL,(CurrObject)
C8CD6:	PUSH	HL
		CALL	C8CAB
		LD		DE,L000B
		POP		HL
		ADD		HL,DE
		XOR		(HL)
		AND		$0F
		XOR		(HL)
		LD		(HL),A
		LD		DE,LFFFA
		ADD		HL,DE
		LD		A,(HL)
		ADD		A,C
		LD		(HL),A
		INC		HL
		LD		A,(HL)
		ADD		A,B
		LD		(HL),A
		RET
C8CF0:	INC		(HL)
		LD		A,(HL)
		ADD		A,L
		LD		E,A
		ADC		A,H
		SUB		E
		LD		D,A
		LD		A,(DE)
		AND		A
		RET		NZ
		LD		(HL),$01
		INC		HL
		LD		A,(HL)
		RET
L8CFF:	LD		A,(HL)
		INC		(HL)
		ADD		A,A
		ADD		A,L
		LD		E,A
		ADC		A,H
		SUB		E
		LD		D,A
		INC		DE
		LD		A,(DE)
		AND		A
		JR		Z,L8D11
		EX		DE,HL
		LD		E,A
		INC		HL
		LD		D,(HL)
		RET
L8D11:	LD		(HL),$01
		INC		HL
		LD		E,(HL)
		INC		HL
		LD		D,(HL)
		RET
	
C8D18:		LD		HL,(L8D49)
		LD		D,L
		ADD		HL,HL
		ADC		HL,HL
		LD		C,H
		LD		HL,(L8D47)
		LD		B,H
		RL		B
		LD		E,H
		RL		E
		RL		D
		ADD		HL,BC
		LD		(L8D47),HL
		LD		HL,(L8D49)
		ADC		HL,DE
		RES		7,H
		LD		(L8D49),HL
		JP		M,L8D43
		LD		HL,L8D47
L8D3F:		INC		(HL)
		INC		HL
		JR		Z,L8D3F
L8D43:		LD		HL,(L8D47)
		RET

L8D47:	DEFB $4A,$6F
L8D49:	DEFB $6E,$21

	;; Pointer to object in HL
RemoveObject:	PUSH	HL
		PUSH	HL
		PUSH	IY
		PUSH	HL
		POP	IY
		CALL	CB0C6
		POP	IY
		POP	HL
		CALL	C8D6F
		POP	IX
		SET	7,(IX+$04)
		LD	A,(L703D)
		LD	C,(IX+$0A)
		XOR	C
		AND	$80
		XOR	C
		LD	(IX+$0A),A
		RET

C8D6F:	PUSH	IY
		INC		HL
		INC		HL
		CALL	CA1D8
		EX		DE,HL
		LD		H,B
		LD		L,C
		CALL	CA0A8
		POP		IY
		RET
	
InsertObject:	PUSH	HL
		PUSH	HL
		PUSH	IY
		PUSH	HL
		POP	IY
		CALL	CB03B
		POP	IY
		POP	HL
		CALL	C8D6F
		POP	IX
		RES	7,(IX+$04)
		LD	(IX+$0B),$FF
		LD	(IX+$0C),$FF
		RET
	
#include "sprite_stuff.asm"
	
L8ED8:	DEFB $00
L8ED9:	DEFB $FF
L8EDA:	DEFB $FF

#include "obj_fns.asm"
	
L9376:	DEFB $FD,$F9,$FB,$FA,$FE,$F6,$F7,$F5
C937E:	LD		C,(IY+$10)
		BIT		1,C
		RES		4,(IY+$04)
		JR		NZ,C938D
		SET		4,(IY+$04)
C938D:	LD		A,(IY+$0F)
		AND		A
		RET		Z
		BIT		2,C
		LD		C,A
		JR		Z,L939E
		BIT		3,C
		RET		NZ
		LD		A,$08
		JR		L93A2
L939E:	BIT		3,C
		RET		Z
		XOR		A
L93A2:	XOR		C
		AND		$0F
		XOR		C
		LD		(IY+$0F),A
		RET
L93AA:	DEFB $00,$00,$00,$00,$00,$00
	
DoObjects:	LD	A,(L703D)
		XOR	$80
		LD	(L703D),A 		; Toggle top bit of L703D
		CALL	CharThing
	;; Loop over object list...
		LD	HL,(ObjectList)
		JR	DO_3
DO_1:		PUSH	HL
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		EX	(SP),HL			; Next item on top of stack, curr item in HL
		EX	DE,HL
		LD	HL,L000A
		ADD	HL,DE
	;; Check position +10
		LD	A,(L703D)
		XOR	(HL)
		CP	$80			; Skip if top bit doesn't match 703D
		JR	C,DO_2
		LD	A,(HL)
		XOR	$80
		LD	(HL),A			; Flip top bit
		AND	$7F
		CALL	NZ,CallObjFn 		; And if any other bits set, call CallObjFn
DO_2:		POP	HL
DO_3:		LD	A,H			; loop until null pointer.
		OR	L
		JR	NZ,DO_1
		RET

	;; Room origin, in double-pixel coordinates, for attrib-drawing
RoomOrigin:	DEFW $0000
	
Attrib0:	DEFB $00
Attrib3:	DEFB $43
Attrib4:	DEFB $45
Attrib5:	DEFB $46

#include "blit_screen.asm"

#include "screen_bits.asm"

#include "controls2.asm"

#include "sound.asm"
	
#include "blit_mask.asm"

#include "background.asm"
	
#include "blit_rot.asm"
	
SpriteXExtent:	DEFW $6066
SpriteYExtent:	DEFW $5070
LA056:	DEFB $00
SpriteByteCount:	DEFB $00
LA058:	DEFB $00
LA059:	DEFB $00
LA05A:	DEFB $00
LA05B:	DEFB $00
SpriteFlags:	DEFB $00

CA05D:		INC		HL
		INC		HL
		CALL	CA1D8
		LD		(LA058),BC
		LD		(LA05A),HL
		RET

	
CA06A:		INC		HL
		INC		HL
		CALL		CA1D8
		LD		DE,(LA05A)
		LD		A,H
		CP		D
		JR		NC,LA078
		LD		D,H
LA078:		LD		A,E
		CP		L
		JR		NC,LA07D
		LD		E,L
LA07D:		LD		HL,(LA058)
		LD		A,B
		CP		H
		JR		NC,LA085
		LD		H,B
LA085:		LD		A,L
		CP		C
		RET		NC
		LD		L,C
		RET


CA08A:		LD		A,L
		ADD		A,$03
		AND		$FC
		LD		L,A
		LD		A,H
		AND		$FC
		LD		H,A
		LD		(SpriteXExtent),HL
		RET


CA098:		CALL	CA08A
		JR	LA0AF

LA09D:		LD	A,$48
		CP	E
		RET	NC
		LD	D,$48
		JR	LA0B6

CA0A5:		CALL	CA06A
CA0A8:		CALL	CA08A
		LD	A,E
		CP	$F1
		RET	NC
LA0AF:		LD	A,D
		CP	E
		RET	NC
		CP	$48
		JR	C,LA09D

LA0B6:		LD	(SpriteYExtent),DE
		CALL	DrawBkgnd
		LD	A,(L7716)
		AND	$0C
		JR	Z,LA109
		LD	E,A
		AND	$08
		JR	Z,LA0EC
		LD	BC,(SpriteXExtent)
		LD	HL,L84C9
		LD	A,B
		CP	(HL)
		JR	NC,LA0EC
		LD	A,(SpriteYExtent+1)
		ADD	A,B
		RRA
		LD	D,A
		LD	A,(L84C7)
		CP	D
		JR	C,LA0EC
		LD	HL,LAF82
		PUSH	DE
		CALL	CA11E
		POP	DE
		BIT	2,E
		JR	Z,LA109
LA0EC:		LD	BC,(SpriteXExtent)
		LD	A,(L84C9)
		CP	C
		JR	NC,LA109
		LD	A,(SpriteYExtent+1)
		SUB	C
		CCF
		RRA
		LD	D,A
		LD	A,(L84C8)
		CP	D
		JR	C,LA109
		LD	HL,LAF86
		CALL	CA11E
LA109:		LD	HL,LAF8A
		CALL	CA11E
		LD	HL,LAF7E
		CALL	CA11E
		LD	HL,LAF8E
		CALL	CA11E
		JP	BlitScreen

	;; TODO: This function is seriously epic...	
CA11E:		LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		OR		H
		RET		Z
		LD		(BigSpriteThing+1),HL
		CALL	CA12F
BigSpriteThing:		LD		HL,L0000 	; NB: Self-modifying code
		JR		CA11E
CA12F:		CALL	CA1BD
		RET		NC
		LD		(SpriteByteCount),A
		LD		A,H
		ADD		A,A
		ADD		A,H
		ADD		A,A
		EXX
		SRL		H
		SRL		H
		ADD		A,H
		LD		E,A
		LD		D,SpriteBuff >> 8
		PUSH	DE
		PUSH	HL
		EXX
		LD		A,L
		NEG
		LD		B,A
		LD		A,(SpriteWidth)
		AND		$04
		LD		A,B
		JR		NZ,LA156
		ADD		A,A
		ADD		A,B
		JR		LA158
LA156:		ADD		A,A
		ADD		A,A
LA158:		PUSH	AF
		CALL	GetSpriteAddr
		POP		BC
		LD		C,B
		LD		B,$00
		ADD		HL,BC
		EX		DE,HL
		ADD		HL,BC
		LD		A,(LA056)
		AND		$03
		CALL	NZ,BlitRot
		POP		BC
		LD		A,C
		NEG
		ADD		A,$03
		RRCA
		RRCA
		AND		$07
		LD		C,A
		LD		B,$00
		ADD		HL,BC
		EX		DE,HL
		ADD		HL,BC
		POP		BC
		EXX
		LD		A,(SpriteWidth)
		SUB		$03
		ADD		A,A
		LD		E,A
		LD		D,$00
		LD		HL,LA19F
		ADD		HL,DE
		LD		E,(HL)
		INC		HL
		LD		D,(HL)
		EX		AF,AF'
		DEC		A
		RRA
		AND		$0E
		LD		L,A
		LD		H,$00
		ADD		HL,DE
		LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		LD		A,(SpriteByteCount)
		LD		B,A
		JP		(HL)
LA19F:		AND		L 	; FIXME: Might just be data?!
		AND		C
		XOR		E
		AND		C
		OR		E
		AND		C
		DEC		H
		SBC		A,D
		LD		A,(L569A)
		SBC		A,D
		LD		A,C
		SBC		A,D
		SUB		B
		SBC		A,D
		XOR		(HL)
		SBC		A,D
		OUT		($9A),A
		CP		$9A
		RLA
		SBC		A,E
		SCF
		SBC		A,E
		LD		E,(HL)
		SBC		A,E
		ADC		A,E
		SBC		A,E
CA1BD:		CALL	CA1F0
		LD		A,B
		LD		(LA056),A
		PUSH	HL
		LD		DE,(SpriteXExtent)
		CALL	CA20C
		EXX
		POP		BC
		RET		NC
		EX		AF,AF'
		LD		DE,(SpriteYExtent)
		CALL	CA20C
		RET


	
CA1D8:	INC		HL
		INC		HL
		LD		A,(HL)
		BIT		3,A
		JR		Z,CA1F3
		CALL	CA1F3
		LD		A,(SpriteFlags)
		BIT		5,A
		LD		A,$F0
		JR		Z,LA1ED
		LD		A,$F4
LA1ED:	ADD		A,H
		LD		H,A
		RET
CA1F0:	INC		HL
		INC		HL
		LD		A,(HL)
CA1F3:	BIT		4,A
		LD		A,$00
		JR		Z,LA1FB
		LD		A,$80
LA1FB:	EX		AF,AF'
		INC		HL
		CALL	CA231
		INC		HL
		INC		HL
		LD		A,(HL)
		LD		(SpriteFlags),A
		DEC		HL
		EX		AF,AF'
		XOR		(HL)
		JP		LADB7
CA20C:	LD		A,D
		SUB		C
		RET		NC
		LD		A,B
		SUB		E
		RET		NC
		NEG
		LD		L,A
		LD		A,B
		SUB		D
		JR		C,LA224
		LD		H,A
		LD		A,C
		SUB		B
		LD		C,L
		LD		L,$00
		CP		C
		RET		C
		LD		A,C
		SCF
		RET
LA224:	LD		L,A
		LD		A,C
		SUB		D
		LD		C,A
		LD		A,E
		SUB		D
		CP		C
		LD		H,$00
		RET		C
		LD		A,C
		SCF
		RET
CA231:	LD		A,(HL)
		LD		D,A
		INC		HL
		LD		E,(HL)
		SUB		E
		ADD		A,$80
		LD		C,A
		INC		HL
		LD		A,(HL)
		ADD		A,A
		SUB		E
		SUB		D
		ADD		A,$7F
		LD		B,A
		RET

	;; Fetch bit-packed data.
	;; Expects number of bits in B.
	
	;; End marker is the set bit rotated in from carry: The
	;; current byte is all read when only that bit remains.
FetchData:	LD	DE,CurrData
		LD	A,(DE)
		LD	HL,(DataPtr)
		LD	C,A
		XOR	A
FD_1:		RL	C
		JR	Z,FD_3
FD_2:		RLA
		DJNZ	FD_1
		EX	DE,HL
		LD	(HL),C
		RET
	;; Next character case: Load/initially rotate the new character, and jump back.
FD_3:		INC	HL
		LD	(DataPtr),HL
		LD	C,(HL)
		SCF
		RL	C
		JP	FD_2

	
CA260:	LD		HL,(L7748)
		LD		A,L
		CP		H
		JR		C,LA268
		LD		A,H
LA268:	NEG
		ADD		A,$C0
		LD		HL,L774C
		CP		(HL)
		JR		C,LA273
		LD		(HL),A
LA273:	LD		A,(HL)
		JP		L84E4

FillZero:	LD	E,$00
	;; HL = Dest, BC = Size, E = value
FillValue:	LD	(HL),E
		INC	HL
		DEC	BC
		LD	A,B
		OR	C
		JR	NZ,FillValue
		RET

StatusReinit:	DEFB $09	; Number of bytes to reinit with
	
		DEFB $00	; Inventory reset
		DEFB $00	; Speed reset
		DEFB $00	; Springs reset
		DEFB $00	; Heels invuln reset
		DEFB $00	; Head invuln reset
		DEFB $08	; Heels lives reset
		DEFB $08	; Head lives reset
		DEFB $00	; Donuts reset
		DEFB $00	; FIXME
	
Inventory:	DEFB $00	; Bit 0 purse, bit 1 hooter, bit 2 donuts FIXME
Speed:		DEFB $00	; Speed
		DEFB $00	; Springs
Invuln:		DEFB $00	; Heels invuln
		DEFB $00	; Head invuln
Lives:		DEFB $04	; Heels lives
		DEFB $04	; Head lives
Donuts:		DEFB $00	; Donuts
LA293:		DEFB $00
Character:	DEFB $03	; $3 = Both, $2 = Head, $1 = Heels
LA295:	DEFB $01
LA296:	DEFB $00
LA297:	DEFB $00
LA298:	DEFB $03
LA299:	DEFB $02
	
ReinitThing:	DEFB $03	; Three bytes to reinit with
	
		DEFB $00
		DEFB $00
		DEFB $FF
	
LA29E:		DEFB $00
LA29F:		DEFB $00
LA2A0:		DEFB $FF
	
LA2A1:	DEFB $02
LA2A2:	DEFB $00
LA2A3:	DEFB $00,$00,$00
LA2A6:	DEFB $03
Carrying:	DEFW $0000	 ; Pointer to carried object.
	
FiredObj:	DEFB $00,$00,$00,$00,$20
		DEFB $28,$0B,$C0
		DEFB $24,$08
		DEFB $12
		DEFB $FF,$FF,$00,$00
		DEFB $08,$00,$00
	
LA2BB:	DEFB $0F
LA2BC:	DEFB $00
LA2BD:	DEFB $00
LA2BE:	DEFB $00
LA2BF:	DEFB $FF
	
HeelsObj:	DEFB $00
LA2C1:	DEFB $00,$00,$00,$08
LA2C5:	DEFB $28,$0B,$C0
LA2C8:	DEFB $18,$21,$00,$FF,$FF
LA2CD:	DEFB $00,$00,$00,$00
LA2D1:	DEFB $00
	
HeadObj:	DEFB $00,$00,$00,$00,$08
LA2D7:	DEFB $28,$0B,$C0
LA2DA:	DEFB $1F,$25,$00,$FF,$FF
LA2DF:	DEFB $00,$00
LA2E1:	DEFB $00,$00,$00
	
LA2E4:	DEFB $00,$18,$19,$18,$1A,$00
LA2EA:	DEFB $00,$1B,$1C,$1B,$1D,$00
LA2F0:	DEFB $00
LA2F1:	DEFB $1E,$1F,$1E,$20,$00
LA2F6:	DEFB $00,$21,$22,$21,$23,$00
LA2FC:	DEFB $00,$24,$A4,$A5,$25
LA301:	DEFB $A5,$A6,$26,$26,$A6,$A6,$26,$26,$00
LA30A:	DEFB $00,$26,$A6,$26,$A6,$A5,$25
LA311:	DEFB $24,$A5,$00
LA314:	DEFB $00
LA315:	DEFB $40
LA316:	LD		HL,LA314
		LD		A,$80
		XOR		(HL)
		LD		(HL),A
		LD		A,(LC043)
		BIT		0,A
		LD		HL,LD12D
		LD		DE,LA355
		JR		Z,LA32E
		DEC		HL
		LD		DE,LA349
LA32E:	PUSH	DE
		PUSH	HL
		CALL	CA339
		LD		DE,L0048
		POP		HL
		ADD		HL,DE
		POP		DE
CA339:	LD		C,$06
LA33B:	LD		B,$02
LA33D:	LD		A,(DE)
		XOR		(HL)
		LD		(HL),A
		INC		DE
		INC		HL
		DJNZ	LA33D
		INC		HL
		DEC		C
		JR		NZ,LA33B
		RET
LA349:	DEFB $00,$C0,$01,$D8,$00,$1C,$00,$84,$00,$10,$00,$20
LA355:	DEFB $03,$00,$1B,$80,$38,$00,$21,$00,$08,$00,$04,$00

#include "character.asm"
	
LAA72:	DEFB $00
LAA73:	DEFB $00

CAA74:		CALL	CAA7E
		LD		A,(IY+$07)
		SUB		C
		JP		LAB0B
CAA7E:	LD		C,$C0
		LD		A,(LA2BC)
		AND		A
		RET		Z
		LD		IX,L7744
		LD		C,(IX+$00)
		LD		A,(L771B)
		SUB		$03
		CP		A,(IY+$06)
		RET		C
		LD		C,(IX+$02)
		LD		A,(L7719)
		ADD		A,$02
		CP		A,(IY+$06)
		RET		NC
		LD		C,(IX+$01)
		LD		A,(L771A)
		SUB		$03
		CP		A,(IY+$05)
		RET		C
		LD		C,(IX+$03)
		RET

FloorThing1:	CP	$FF
	;; NB: Fall through.
FloorThing2:	SCF
		LD	(IY+$0D),A
		LD	(IY+$0E),A
		RET	NZ
		BIT	0,(IY+$09)
		JR	Z,FloorCheck
		LD	A,(LA2BC)
		AND	A
		JR	NZ,RetZeroC
		LD	A,(FloorCode)
		CP	$06 		; Deadly floor?
		JR	Z,DeadlyFloorCase
		CP	$07 		; No floor?
		JR	NZ,RetZeroC
	;; Code to handle no floor...
		CALL	GetCharObj
		PUSH	IY
		POP	DE
		AND	A
		SBC	HL,DE
		JR	Z,FloorThing3
		LD	HL,SwopPressed
		LD	A,(HL)
		OR	$03
		LD	(HL),A
		JR	RetZeroC

FloorThing3:	LD	A,$05
		LD	(LB218),A
		AND	A
		RET

DeadlyFloorCase:LD	C,(IY+$09)
		LD	B,(IY+$04)
		CALL	CB2F8

	;; Return with 0 in A, and carry flag set.
RetZeroC:	XOR	A
		SCF
		RET

FloorCheck:	LD	A,(FloorCode)
		CP	$07 		; No floor?
		JR	NZ,RetZeroC
		LD	(IY+$0A),$22 	; Update this, then.
		JR	RetZeroC

CAB06:		LD	A,(IY+$07)
		SUB	$C0
LAB0B:		LD	BC,L0000
		LD	(LAA72),BC
		JR	Z,FloorThing2
		INC	A
		JR	Z,FloorThing1
		CALL	CB0F9
		LD	C,B
		INC	C
		EXX
		LD	A,(IY+$0E)
		AND	A
		JR	Z,LAB64
		LD	H,A
		LD	L,(IY+$0D)
		PUSH	HL
		POP	IX
		BIT	7,(IX+$04)
		JR	NZ,LAB64
		LD	A,(IX+$07)
		SUB	$06
		EXX
		CP	B
		EXX
		JR	NZ,LAB64
		CALL	CheckWeOverlap
		JR	NC,LAB64
LAB3F:		BIT	1,(IX+$09)
		JR	Z,LAB4E
		RES	5,(IX-$06)
		LD	A,(IX-$07)
		JR	LAB55

LAB4E:		RES		5,(IX+$0C)
		LD		A,(IX+$0B)

LAB55:		OR		$E0
		LD		C,A
		LD		A,(IY+$0C)
		AND		C
		LD		(IY+$0C),A
LAB5F:	XOR		A
		SCF
		JP		LB2BF
	;; Run through all the objects
LAB64:		LD	HL,ObjectList
LAB67:		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		OR	H
		JR	Z,LABA6
		PUSH	HL
		POP	IX
		BIT	7,(IX+$04)
		JR	NZ,LAB67 	; Bit set? Skip this item
		LD	A,(IX+$07)
		SUB	$06
		EXX
		CP	B
		JR	NZ,LAB90
		EXX
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,LAB67
LAB88:		LD	(IY+$0D),L
		LD	(IY+$0E),H
		JR	LAB3F
LAB90:		CP	C
		EXX
		JR	NZ,LAB67
		LD	A,(LAA73)
		AND	A
		JR	NZ,LAB67
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,LAB67
		LD	(LAA72),HL
		JR	LAB67
	;; Completed object list traversal
LABA6:	LD		A,(LA2BC)
		AND		A
		JR		Z,LABE7
		CALL	GetCharObjIX
		LD		A,(Character)
		CP		$03
		LD		A,$F4
		JR		Z,LABBA
		LD		A,$FA
LABBA:	ADD		A,(IX+$07)
		EXX
		CP		B
		JR		NZ,LABCB
		EXX
		PUSH	HL
		CALL	CheckWeOverlap
		POP		HL
		JR		NC,LABE7
		JR		LAB88
LABCB:	CP		C
		EXX
		JR		NZ,LABE7
		LD		A,(LAA73)
		AND		A
		JR		NZ,LABE7
		CALL	GetCharObjIX
		CALL	CheckWeOverlap
		JR		NC,LABE7
		LD		(IY+$0D),$00
		LD		(IY+$0E),$00
		JR		LAC0E
LABE7:	LD		HL,(LAA72)
		LD		(IY+$0D),$00
		LD		(IY+$0E),$00
		LD		A,H
		AND		A
		RET		Z
		PUSH	HL
		POP		IX
		BIT		1,(IX+$09)
		JR		Z,LAC04
		BIT		4,(IX-$07)
		JR		LAC08
LAC04:	BIT		4,(IX+$0B)
LAC08:	JR		NZ,LAC0E
		RES		4,(IY+$0C)
LAC0E:	XOR		A
		SUB		$01
		RET

	;; Called by the purse routine to find something to pick up.
	;; Carry flag set if something is found, and thing returned in HL.
	;;
	;; Loop through all items, finding ones which match on B or C
	;; Then call CheckWeOverlap to see if ok candidate. Return if it is.
GetStoodUpon:	CALL	CB0F9		; Perhaps getting height as a filter?
		LD	A,B
		ADD	A,$06
		LD	B,A
		INC	A
		LD	C,A
		EXX
	;; Traverse list of objects
		LD	HL,ObjectList
GSU_1:		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		OR	H
		RET	Z
		PUSH	HL
		POP	IX
		BIT	6,(IX+$04)
		JR	Z,GSU_1
		LD	A,(IX+$07)
		EXX
		CP	B
		JR	Z,GSU_2
		CP	C
GSU_2:		EXX
		JR	NZ,GSU_1
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,GSU_1
		RET

	;; FIXME: Looks suspiciously like we're checking contact with objects.
CAC41:		CALL	CB0F9
		LD	B,C
		DEC	B
		EXX
		XOR	A
		LD	(LAA72),A
	;; Traverse list of objects
		LD	HL,ObjectList
LAC4E:		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		OR	H
		JR	Z,LAC97		; Reached end?
		PUSH	HL
		POP	IX
		BIT	7,(IX+$04)
		JR	NZ,LAC4E 	; Skip if bit set
		LD	A,(IX+$07)
		EXX
		CP	C
		JR	NZ,LAC7F
		EXX
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,LAC4E
LAC6D:		LD	A,(IY+$0B)
		OR	$E0
		AND	$EF
		LD	C,A
		LD	A,(IX+$0C)
		AND	C
		LD	(IX+$0C),A
		JP	LAB5F		; Tail call
LAC7F:		CP	B
		EXX
		JR	NZ,LAC4E
		LD	A,(LAA72)
		AND	A
		JR	NZ,LAC4E
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,LAC4E
		LD	A,$FF
		LD	(LAA72),A
		JR	LAC4E
	;; Finished traversing list
LAC97:		LD	A,(LA2BC)
		AND	A
		JR	Z,LACCC
		CALL	GetCharObjIX
		LD	A,(IX+$07)
		EXX
		CP	C
		JR	NZ,LACB6
		EXX
		CALL	CheckWeOverlap
		JR	NC,LACCC
		JR	LAC6D

GetCharObjIX:	CALL	GetCharObj
		PUSH	HL
		POP	IX
		RET

LACB6:	CP		B
		EXX
		JR		NZ,LACCC
		LD		A,(LAA72)
		AND		A
		JR		NZ,LACCC
		CALL	GetCharObjIX
		CALL	CheckWeOverlap
		JR		NC,LACCC
		LD		A,$FF
		JR		LACCF
LACCC:	LD		A,(LAA72)
LACCF:	AND		A
		RET		Z
		SCF
		RET

	;; Takes object point in IX and checks to see if we overlap with it.
	;; FIXME: May assume our coordinates are in DE',HL'.
CheckWeOverlap:	CALL	CACE6
	;; NB: Fall through
	
	;; Assuming X and Y extents in DE,HL and DE',HL', check two boundaries overlap.
	;; Sets carry flag if they do.
CheckOverlap:
	;; Check E < D' and E' < D
		LD	A,E
		EXX
		CP	D
		LD	A,E
		EXX
		RET	NC
		CP	D
		RET	NC
	;; Check L < H' and L' < H
		LD	A,L
		EXX
		CP	H
		LD	A,L
		EXX
		RET	NC
		CP	H
		RET

CACE6:		LD		A,(IX+$04)
		BIT		1,A
		JR		NZ,LAD03
		RRA
		LD		A,$03
		ADC		A,$00
		LD		C,A
		ADD		A,(IX+$05)
		LD		D,A
		SUB		C
		SUB		C
		LD		E,A
		LD		A,C
		ADD		A,(IX+$06)
		LD		H,A
		SUB		C
		SUB		C
		LD		L,A
		RET
LAD03:	RRA
		JR		C,LAD16
		LD		A,(IX+$05)
		ADD		A,$04
		LD		D,A
		SUB		$08
		LD		E,A
		LD		L,(IX+$06)
		LD		H,L
		INC		H
		DEC		L
		RET
LAD16:	LD		A,(IX+$06)
		ADD		A,$04
		LD		H,A
		SUB		$08
		LD		L,A
		LD		E,(IX+$05)
		LD		D,E
		INC		D
		DEC		E
		RET
CAD26:	LD		BC,(L703B)
		LD		HL,LAD4C
		CALL	CAD35
		LD		(L703B),DE
		RET
CAD35:	CALL	CAD42
		JR		Z,CAD42
		PUSH	DE
		CALL	CAD42
		POP		DE
		JR		NZ,CAD35
		RET
CAD42:	LD		A,C
		LD		E,(HL)
		INC		HL
		LD		D,(HL)
		INC		HL
		CP		E
		RET		NZ
		LD		A,B
		CP		D
		RET
LAD4C:	DEFB $40,$8A,$50,$71,$40,$89,$80,$04,$70,$BA,$00,$13,$00,$41,$80,$29
LAD5C:	DEFB $00,$A1,$00,$26,$00,$81,$80,$E9,$00,$84,$00,$B1,$00,$85,$20,$EF
LAD6C:	DEFB $00,$A4,$F0,$00,$00,$A5,$D0,$88,$D0,$BC,$D0,$DE,$B0,$2D,$D0,$8B
LAD7C:	DEFB $90,$11,$C0,$E1,$B0,$00,$C0,$E2,$B0,$10,$00,$C1,$F0,$8B,$F0,$00
LAD8C:	DEFB $30,$97,$20,$EF,$00,$1D,$00,$A8,$70,$BA,$00,$4E,$00,$88,$30,$1B
LAD9C:	DEFB $00,$4C,$30,$39,$30,$8B,$30,$8D

SpriteWidth:	DEFB $04	; Width of sprite in bytes.

	;; Current sprite we're drawing.
SpriteCode:	DEFB $00

RevTable:	EQU $B900
	
	;; Initialise a look-up table of byte reverses.
InitRevTbl:	LD	HL,RevTable
RevLoop_1:	LD	C,L
		LD	A,$01
		AND	A
RevLoop_2:	RRA
		RL	C
		JR	NZ,RevLoop_2
		LD	(HL),A
		INC	L
		JR	NZ,RevLoop_1
		RET

LADB7:		LD	(SpriteCode),A
		AND	$7F
		CP	$10
		JR	C,LADF4
		LD	DE,L0606
		LD	H,$12
		CP	$54
		JR	C,LADCE
		LD	DE,L0808
		LD	H,$14
LADCE:	CP		$18
		JR	NC,LADE1
		LD	A,(SpriteFlags)
		AND	$02
		LD	D,$04
		LD	H,$0C
		JR	Z,LADE1
		LD	D,$00
		LD	H,$10
LADE1:	LD		A,B
		ADD	A,D
		LD	L,A
		SUB	D
		SUB	H
		LD	H,A
		LD	A,C
		ADD	A,E
		LD	C,A
		SUB	E
		SUB	E
		LD	B,A
		LD	A,E
		AND	A
		RRA
		LD	(SpriteWidth),A
		RET
LADF4:	LD		HL,(BigSpriteThing+1)
		INC	HL
		INC	HL
		BIT	5,(HL)
		EX	AF,AF'
		LD	A,(HL)
		SUB	$10
		CP	$20
		LD	L,$04
		JR	NC,LAE07
		LD	L,$08
LAE07:	LD		A,B
		ADD	A,L
		LD	L,A
		SUB	$38
		LD	H,A
		EX	AF,AF'
		LD	A,C
		LD	B,$08
		JR	NZ,LAE15
		LD	B,$04
LAE15:	ADD		A,B
		LD	C,A
		SUB	$0C
		LD	B,A
		LD	A,$03
		LD	(SpriteWidth),A
		RET


#include "get_sprite.asm"
	
BigSpriteFlipped:	DEFB $00
LAF5B:	DEFB $1B		; Reinitialisation size

	DEFB $00
	DEFW LBA40
	DEFW LAF7E
	DEFW ObjectList
	DEFW $0000
	DEFW $0000
	DEFW $0000,$0000
	DEFW $0000,$0000
	DEFW $0000,$0000
	DEFW $0000,$0000

LAF77:	DEFB $00
LAF78:	DEFW LBA40
LAF7A:	DEFW LAF7E
LAF7C:	DEFW ObjectList
LAF7E:	DEFW $0000
ObjectList:	DEFW $0000
LAF82:	DEFW $0000,$0000
LAF86:	DEFW $0000,$0000
LAF8A:	DEFW $0000,$0000
LAF8E:	DEFW $0000,$0000
	
LAF92:	DEFW LBA40
LAF94:	DEFW $0000
	
CAF96:		LD		(LAF77),A
		ADD		A,A
		ADD		A,A
		ADD		A,$7E
		LD		L,A
		ADC		A,$AF
		SUB		L
		LD		H,A
	;; HL = $AF7E + (LAF77) * 4
		LD		(LAF7A),HL
		INC		HL
		INC		HL
		LD		(LAF7C),HL
		RET

CAFAB:	LD		HL,L0012
		ADD		HL,DE
		PUSH	HL
		EX		DE,HL
		LD		BC,L0005
		LDIR
		LD		A,(HL)
		SUB		$06
		LD		(DE),A
		INC		DE
		INC		HL
		INC		HL
		BIT		5,(HL)
		JR		NZ,LAFC4
		DEC		HL
		LDI
LAFC4:	POP		HL
		RET
LAFC6:	PUSH	HL
		PUSH	BC
		INC		HL
		INC		HL
		CALL	CA1BD
		POP		BC
		POP		HL
		RET		NC
		LD		DE,(LAF78)
		PUSH	DE
		LDIR
		LD		(LAF78),DE
		POP		HL
		PUSH	HL
		POP		IY
		BIT		3,(IY+$04)
		JR		Z,CB010
		LD		BC,L0009
		PUSH	HL
		LDIR
		EX		DE,HL
		LD		A,(DE)
		OR		$02
		LD		(HL),A
		INC		HL
		LD		(HL),$00
		LD		DE,L0008
		ADD		HL,DE
		LD		(LAF78),HL
		BIT		5,(IY+$09)
		JR		Z,LB00F
		PUSH	IY
		LD		DE,L0012
		ADD		IY,DE
		LD		A,(L822E)
		CALL	C828B
		POP		IY
LB00F:	POP		HL
CB010:	LD		A,(LAF77)
		DEC		A
		CP		$02
		JR		NC,CB03B
		INC		HL
		INC		HL
		BIT		3,(IY+$04)
		JR		Z,CB034
		PUSH	HL
		CALL	CB034
		POP		DE
		CALL	CAFAB
		PUSH	HL
		CALL	GetUpdatedCoords2
		EXX
		PUSH	IY
		POP		HL
		INC		HL
		INC		HL
		JR		LB085
CB034:	PUSH	HL
		CALL	GetUpdatedCoords2
		EXX
		JR		LB082

	
CB03B:		INC		HL
		INC		HL
		BIT		3,(IY+$04)
		JR		Z,CB057
		PUSH		HL
		CALL		CB057
		POP		DE
		CALL		CAFAB
		PUSH		HL
		CALL		GetUpdatedCoords2
		EXX
		PUSH		IY
		POP		HL
		INC		HL
		INC		HL
		JR		LB085

CB057:		PUSH		HL
		CALL		GetUpdatedCoords2
		LD		A,$03
		EX		AF,AF'
		LD		A,(L771A)
		CP		D
		JR		C,LB07D
		LD		A,(L771B)
		CP		H
		JR		C,LB07D
		LD		A,$04
		EX		AF,AF'
		LD		A,(L7718)
		DEC		A
		CP		E
		JR		NC,LB07D
		LD		A,(L7719)
		DEC		A
		CP		L
		JR		NC,LB07D
		XOR		A
		EX		AF,AF'
LB07D:	EXX
		EX		AF,AF'
		CALL	CAF96
LB082:	LD		HL,(LAF7A)
LB085:	LD		(LAF94),HL
LB088:	LD		A,(HL)
		INC		HL
		LD		H,(HL)
		LD		L,A
		OR		H
		JR		Z,LB09C
		PUSH	HL
		CALL	GetUpdatedCoords2
		CALL	CB17A
		POP		HL
		JR		NC,LB085
		AND		A
		JR		NZ,LB088
LB09C:	LD		HL,(LAF94)
		POP		DE
		LD		A,(HL)
		LDI
		LD		C,A
		LD		A,(HL)
		LD		(DE),A
		DEC		DE
		LD		(HL),D
		DEC		HL
		LD		(HL),E
		LD		L,C
		LD		H,A
		OR		C
		JR		NZ,LB0B4
		LD		HL,(LAF7C)
		INC		HL
		INC		HL
LB0B4:	DEC		HL
		DEC		DE
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

	
CB17A:	LD		A,L
		EXX
		CP		H
		LD		A,L
		EXX
		JR		NC,LB184
		CP		H
		JR		C,LB1BB
LB184:	LD		A,E
		EXX
		CP		D
		LD		A,E
		EXX
		JR		NC,LB18E
		CP		D
		JR		C,LB1F2
LB18E:	LD		A,C
		EXX
		CP		B
		LD		A,C
		EXX
		JR		NC,LB198
		CP		B
		JR		C,LB1AF
LB198:	LD		A,L
		ADD		A,E
		ADD		A,C
		LD		L,A
		ADC		A,$00
		SUB		L
		LD		H,A
		EXX
		LD		A,L
		ADD		A,E
		ADD		A,C
		EXX
		LD		E,A
		ADC		A,$00
		SUB		E
		LD		D,A
		SBC		HL,DE
		LD		A,$FF
		RET
LB1AF:	LD		A,L
		ADD		A,E
		LD		L,A
		EXX
		LD		A,L
		ADD		A,E
		EXX
		CP		L
		CCF
		LD		A,$FF
		RET
LB1BB:	LD		A,E
		EXX
		CP		D
		LD		A,E
		EXX
		JR		NC,LB1C5
		CP		D
		JR		C,LB1EB
LB1C5:	LD		A,C
		EXX
		CP		B
		LD		A,C
		EXX
		JR		NC,LB1CF
		CP		B
		JR		C,LB1E4
LB1CF:	EXX
		ADD		A,E
		EXX
		LD		L,A
		ADC		A,$00
		SUB		L
		LD		H,A
		LD		A,C
		ADD		A,E
		LD		E,A
		ADC		A,$00
		SUB		E
		LD		D,A
		SBC		HL,DE
		CCF
		LD		A,$FF
		RET
LB1E4:	LD		A,E
		EXX
		CP		E
		EXX
		LD		A,$00
		RET
LB1EB:	LD		A,C
		EXX
		CP		C
		EXX
		LD		A,$00
		RET
LB1F2:	LD		A,C
		EXX
		CP		B
		LD		A,C
		EXX
		JR		NC,LB1FC
		CP		B
		JR		C,LB210
LB1FC:	EXX
		ADD		A,L
		EXX
		LD		E,A
		ADC		A,$00
		SUB		E
		LD		D,A
		LD		A,C
		ADD		A,L
		LD		L,A
		ADC		A,$00
		SUB		L
		LD		H,A
		SBC		HL,DE
		LD		A,$FF
		RET
LB210:	LD		A,L
		EXX
		CP		L
		EXX
		LD		A,$00
		RET
LB217:	DEFB $00
LB218:	DEFB $00
LB219:	DEFB $00
LB21A:	DEFB $00
LB21B:	DEFB $00
	
TableCall:	PUSH	AF
		CALL	CB0F9
		EXX
		POP	AF
		LD	(LB21B),A
	;; NB: Fall through

DoTableCall:	CALL	SomeTableCall
		LD	A,(LB21B)
		RET

	;; Takes value in A, indexes into table, writes variable, makes call...
SomeTableCall:	LD	DE,LB24B
		PUSH	DE
		LD	C,A
		ADD	A,A
		ADD	A,A
		ADD	A,C		; Multiply by 5
		ADD	A,FnTbl & $FF
		LD	L,A
		ADC	A,FnTbl >> 8
		SUB	L
		LD	H,A		; Generate index into table
		LD	A,(HL)
		LD	(LB217),A 	; Load first value here
		INC	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)		; Next two in DE
		INC	HL
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A		; Next two in HL
		PUSH	DE
		EXX			; Save regs, and...
		RET			; tail call DE.
	
LB24B:	DEFB $D9,$C8,$E5,$DD,$E1,$CB,$51,$20,$15,$21,$7E,$AF,$7E,$23,$66,$6F
LB25B:	DEFB $B4,$28,$24,$E5,$CD,$F4,$9D,$E1,$38,$3B,$20,$F0,$18,$19,$21,$80
LB26B:	DEFB $AF,$7E,$23,$66,$6F,$B4,$28,$09,$E5,$CD,$F4,$9D,$E1,$38,$28,$20
LB27B:	DEFB $F0,$CD,$4B,$A9,$5D,$18,$06,$CD,$4B,$A9,$5D,$23,$23,$FD,$CB,$09
LB28B:	DEFB $46,$28,$04,$FD,$7D,$BB,$C8,$3A,$BC,$A2,$A7,$C8,$CD,$F4,$9D,$D0
LB29B:	DEFB $CD,$4B,$A9,$23,$23,$2B,$2B,$E5,$DD,$E1,$3A,$17,$B2,$DD,$CB,$09
LB2AB:	DEFB $4E,$28,$08,$DD,$A6,$FA,$DD,$77,$FA,$18,$06,$DD,$A6,$0C,$DD,$77
LB2BB:	DEFB $0C,$AF,$D6,$01
LB2BF:	PUSH	AF
		PUSH	IX
		PUSH	IY
		CALL	CB2CD
		POP		IY
		POP		IX
		POP		AF
		RET
CB2CD:	BIT		0,(IY+$09)
		JR		NZ,LB2DF
		BIT		0,(IX+$09)
		JR		Z,LB34F
		PUSH	IY
		EX		(SP),IX
		POP		IY
LB2DF:	LD		C,(IY+$09)
		LD		B,(IY+$04)
		BIT		5,(IX+$04)
		RET		Z
		BIT		6,(IX+$04)
		JR		NZ,LB333
		AND		A
		JR		Z,CB2F8
		BIT		4,(IX+$09)
		RET		NZ
CB2F8:		BIT		3,B
		LD		B,$03
		JR		NZ,LB304
		DEC		B
		BIT		2,C
		JR		NZ,LB304
		DEC		B
LB304:		XOR		A
		LD		HL,Invuln
		CP		(HL)
		JR		Z,LB30D
		RES		0,B
LB30D:		INC		HL
		CP		(HL)
		JR		Z,LB313
		RES		1,B
LB313:		LD		A,B
		AND		A
		RET		Z
		LD		HL,LB21A
		OR		(HL)
		LD		(HL),A
		DEC		HL
		LD		A,(HL)
		AND		A
		RET		NZ
		LD		A,(L866B)
		CP		$1F
		RET		Z
		LD		(HL),$0C
		LD		A,(LB218)
		AND		A
		CALL	NZ,BoostInvuln
		LD		B,$C6
		JP		PlaySound
LB333:	LD		(IX+$0F),$08
		LD		(IX+$04),$80
		LD		A,(IX+$0A)
		AND		$80
		OR		$11
		LD		(IX+$0A),A
		RES		6,(IX+$09)
		LD		A,(IX+$11)
		JP		L87DF
LB34F:	BIT		3,(IY+$09)
		JR		NZ,LB35E
		BIT		3,(IX+$09)
		RET		Z
		PUSH	IY
		POP		IX
LB35E:	BIT		1,(IX+$09)
		JR		Z,LB369
		LD		DE,LFFEE
		ADD		IX,DE
LB369:	BIT		7,(IX+$09)
		RET		Z
		SET		6,(IX+$09)
		LD		(IX+$0B),$FF
		RET

#include "fn_tbl_stuff.asm"
	
#include "print_char.asm"

	;; Called immediately after installing interrupt handler.
ShuffleMem:	; Zero end of top page
		LD	HL,LFFFE
		XOR	A
		LD	(HL),A
		; Switch to bank 1, write top of page
		LD	BC,L7FFD
		LD	D,$10
		LD	E,$11
		OUT	(C),E
		LD	(HL),$FF
		; Switch back, see if original overwritten...
		OUT	(C),D
		CP	(HL)
		JR	NZ,Have48K
		; Ok, we're 128K...
		; Zero screen attributes, so no-one can see we're using it as temp space...
		LD	B,$03
		LD	HL,L5800
ShuffleMem_1:	LD	(HL),$00
		INC	L
		JR	NZ,ShuffleMem_1
		INC	H
		DJNZ	ShuffleMem_1
		; Stash data in display memory
		LD	BC,L091B
		LD	DE,L4000
		LD	HL,LB884
		LDIR
		; Switch to bank 1
		LD	A,$11
		LD	BC,L7FFD
		OUT	(C),A
		; Reinitialise IRQ handler there.
		LD	A,$18
		LD	(LFFFF),A
		LD	A,$C3
		LD	($FFF4),A
		LD	HL,IrqHandler
		LD	(LFFF5),HL
		; FIXME: Another memory chunk copy.
		LD	BC,L0043
		LD	DE,AltPlaySound
		LD	HL,LB824
		LDIR
		; FIXME: Repoint interrupt vector.
		DEC	DE
		LD	E,$00
		INC	D
		LD	A,D
		LD	I,A
		LD	A,$FF
ShuffleMem_2:	LD	(DE),A
		INC	E
		JR	NZ,ShuffleMem_2
		INC	D
		LD	(DE),A
		; Unstash from display memory
		LD	BC,L091B
		LD	DE,LC000
		LD	HL,L4000
		LDIR
		; Switch to bank 0.
		LD	BC,L7FFD
		LD	A,$10
		OUT	(C),A
Have48K:	; Move the data end of things down by 360 bytes...
		LD	HL,LC1A0
		LD	DE,LC038
		LD	BC,L390C ; Up to 0xFAAC
		LDIR
		RET

#include "data_trailer.asm"
	
#end
