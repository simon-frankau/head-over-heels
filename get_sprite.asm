	;; 
	;; get_sprite.asm
	;;
	;; Function to return pointer to data for a particular sprite id
	;;
	;; Incorporates code to do horizontal flipping, etc.
	;;
	;; FIXME: Needs tidying.
	;; 

	;; Names for all the sprites...
	
SPR_FLIP:	EQU $80
	
SPR_HEELS1:	EQU $18
SPR_HEELS2:	EQU $19
SPR_HEELS3:	EQU $1A
SPR_HEELSB1:	EQU $1B
SPR_HEELSB2:	EQU $1C
SPR_HEELSB3:	EQU $1D

SPR_HEAD1:	EQU $1E
SPR_HEAD2:	EQU $1F
SPR_HEAD3:	EQU $20
SPR_HEADB1:	EQU $21
SPR_HEADB2:	EQU $22
SPR_HEADB3:	EQU $23

SPR_VAPE1:	EQU $24
SPR_VAPE2:	EQU $25
SPR_VAPE3:	EQU $26
	
SPR_PURSE:	EQU $27
SPR_HOOTER:	EQU $28
SPR_DONUTS:	EQU $29
SPR_BUNNY:	EQU $2A
SPR_SPRING:	EQU $2B
SPR_SPRUNG:	EQU $2C

SPR_FISH1:	EQU $2D
SPR_FISH2:	EQU $2E
SPR_CROWN:	EQU $2F
SPR_SWITCH:	EQU $30
SPR_GRATING:	EQU $31

SPR_MONOCAT1:	EQU $32
SPR_MONOCAT2:	EQU $33
SPR_MONOCATB1:	EQU $34
SPR_MONOCATB2:	EQU $35

SPR_ROBOMOUSE:	EQU $36
SPR_ROBOMOUSEB:	EQU $37

SPR_BEE1:	EQU $38
SPR_BEE2:	EQU $39
SPR_BEACON:	EQU $3A
SPR_FACE:	EQU $3B
SPR_FACEB:	EQU $3C
SPR_TAP:	EQU $3D

SPR_CHIMP:	EQU $3E
SPR_CHIMPB:	EQU $3F
SPR_CHARLES:	EQU $40
SPR_CHARLESB:	EQU $41
SPR_TRUNK:	EQU $42
SPR_TRUNKB:	EQU $43

SPR_HELIPLAT1:	EQU $44
SPR_HELIPLAT2:	EQU $45
SPR_BONGO:	EQU $46
SPR_DRUMM:	EQU $47
SPR_WELL:	EQU $48
SPR_STICK:	EQU $49

SPR_TRUNKS:	EQU $4A
SPR_DECK:	EQU $4B
SPR_BALL:	EQU $4C
SPR_HEAD:	EQU $4D

	
	;; Looks up based on SpriteCode.
	;; Return height in B, image in DE, mask in HL.
GetSpriteAddr:	LD	A,(SpriteCode)
		AND	$7F			; Top bit holds 'reverse?'. Ignore.
		CP	$54			; >= 0x54 -> 4x28
		JP	NC,Sprite4x28
		CP	$18			; >= 0x18 -> 3x24
		JR	NC,Sprite3x24
		CP	$10			; >= 0x10 -> 3x32
		LD	H,$00
		JR	NC,Sprite3x32
	;; TODO: Somewhat mysterious below here...
		LD	L,A
		LD	DE,(LA12A+1)
		INC	DE
		INC	DE
		LD	A,(DE)
		OR	$FC
		INC	A
		JR	NZ,Sprite3x56
		LD	A,(SpriteCode)
		LD	C,A
		RLA
		LD	A,(L770F)
		JR	C,GSA_1		; Top bit set?
		CP	$06
		JR	GSA_2
GSA_1:		CP	$03
GSA_2:		JR	Z,Sprite3x56
		LD	A,(LAF5A)
		XOR	C
		RLA
		LD	DE,LF9D8
		LD	HL,LFA80
		RET	NC
		LD	A,C
		LD	(LAF5A),A
		LD	B,$70
		JR	FlipSprite3	; Tail call

	;; Deal with a 3 byte x sprite 56 pixels high.
Sprite3x56:	LD	A,L
		LD	E,A
		ADD	A,A 		; 2x
		ADD	A,A 		; 4x
		ADD	A,E 		; 5x
		ADD	A,A 		; 10x
		LD	L,A
		ADD	HL,HL 		; 20x
		ADD	HL,HL 		; 40x
		ADD	HL,HL 		; 80x
		LD	A,E
		ADD	A,H
		LD	H,A 		; 336x = 3x56x2x
		LD	DE,IMG_3x56 - MAGIC_OFFSET
		ADD	HL,DE
		LD	DE,L00A8
		LD	B,$70
		JR	Sprite3Wide

	;; Deal with a 3 byte x 32 pixel high sprite.
Sprite3x32:	SUB	$10
		LD	L,A
		ADD	A,A		; 2x
		ADD	A,L		; 3x
		LD	L,A
		ADD	HL,HL		; 3x2x
		ADD	HL,HL		; 3x4x
		ADD	HL,HL		; 3x8x
		ADD	HL,HL		; 3x16x
		ADD	HL,HL		; 3x32x
		ADD	HL,HL		; 3x32x2x
		LD	DE,IMG_3x32 - MAGIC_OFFSET
		ADD	HL,DE
		LD	DE,L0060
		LD	B,$40
		EX	DE,HL
		ADD	HL,DE
		EXX
		CALL	NeedsFlip
		EXX
		CALL	NC,FlipSprite3
		LD	A,(LA05C)
		AND	$02
		RET	NZ
		LD	BC,L0030
		ADD	HL,BC
		EX	DE,HL
		ADD	HL,BC
		EX	DE,HL
		RET
	
	;; Deal with a 3 byte x 24 pixel high sprite
Sprite3x24:	SUB	$18
		LD	D,A
		LD	E,$00
		LD	H,E
		ADD	A,A 		; 2x
		ADD	A,A		; 4x
		LD	L,A
		ADD	HL,HL		; 8x
		ADD	HL,HL		; 16x
		SRL	D
		RR	E		; 128x
		ADD	HL,DE		; 144x = 3x24x2x
		LD	DE,IMG_3x24 - MAGIC_OFFSET
		ADD	HL,DE
		LD	DE,L0048
		LD	B,$30
Sprite3Wide:	EX	DE,HL
		ADD	HL,DE
		EXX
		CALL	NeedsFlip
		EXX
		RET	C		; NB: Fall-through.
	;; Flip a 3-character-wide sprite. Height in B, source in DE.
FlipSprite3:	PUSH	HL
		PUSH	DE
		EX	DE,HL
		LD	D,$B9
FS3_1:		LD	C,(HL)
		LD	(FS3_2+1),HL	; Self-modifying code!
		INC	HL
		LD	E,(HL)
		LD	A,(DE)
		LD	(HL),A
		INC	HL
		LD	E,(HL)
		LD	A,(DE)
FS3_2:		LD	(L0000),A 	; Target of self-modifying code.
		LD	E,C
		LD	A,(DE)
		LD	(HL),A
		INC	HL
		DJNZ	FS3_1
		POP	DE
		POP	HL
		RET

	;; Looks up a 4x28 sprite.
Sprite4x28:	SUB	$54
		LD	D,A
		RLCA			; 2x
		RLCA			; 4x
		LD	H,$00
		LD	L,A
		LD	E,H
		ADD	HL,HL		; 8x
		ADD	HL,HL		; 16x
		ADD	HL,HL		; 32x
		EX	DE,HL
		SBC	HL,DE		; 224x = 4x28x2x
		LD	DE,IMG_4x28 - MAGIC_OFFSET
		ADD	HL,DE
		LD	DE,L0070
		LD	B,$38		; 56 high (including image and mask)
		EX	DE,HL
		ADD	HL,DE
		EXX
		CALL	NeedsFlip
		EXX
		RET	C		; NB: Fall through
	;; Flip a 4-character-wide sprite. Height in B, source in DE.
FlipSprite4:	PUSH	HL
		PUSH	DE
		EX	DE,HL
		LD	D,$B9
FS4_1:		LD	C,(HL)
		LD	(FS4_2+1),HL	; Self-modifying code
		INC	HL
		LD	E,(HL)
		INC	HL
		LD	A,(DE)
		LD	E,(HL)
		LD	(HL),A
		DEC	HL
		LD	A,(DE)
		LD	(HL),A
		INC	HL
		INC	HL
		LD	E,(HL)
		LD	A,(DE)
FS4_2:		LD	(L0000),A 	; Target of self-modifying code
		LD	E,C
		LD	A,(DE)
		LD	(HL),A
		INC	HL
		DJNZ	FS4_1
		POP	DE
		POP	HL
		RET

	;; Look up the sprite in the bitmap, returns with C set if the top bit of SpriteCode
	;; matches the bitmap, otherwise updates the bitmap (assumes that the caller will
	;; flip the sprite if we return NC). In effect, a simple cache.
NeedsFlip:	LD	A,(SpriteCode)
		LD	C,A
		AND	$07
		INC	A
		LD	B,A
		LD	A,$01
NF_1:		RRCA
		DJNZ	NF_1
		LD	B,A		; B now contains bitmask from low 3 bits of SpriteCode
		LD	A,C
		RRA
		RRA
		RRA
		AND	$0F		; A contains next 4 bits.
		LD	E,A
		LD	D,$00
		LD	HL,LC040
		ADD	HL,DE
		LD	A,B
		AND	(HL)		; Perform bit-mask look-up
		JR	Z,NF_2		; Bit set?
		RL	C		; Bit was non-zero
		RET	C
		LD	A,B
		CPL
		AND	(HL)
		LD	(HL),A		; If top bit of SpriteCode wasn't set, reset bit mask
		RET
NF_2:		RL	C		; Bit was zero
		CCF
		RET	C
		LD	A,B
		OR	(HL)
		LD	(HL),A		; If top bit of SpriteCode was set, set bit mask
		RET
