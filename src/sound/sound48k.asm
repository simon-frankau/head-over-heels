	;;
	;; sound48k.asm
	;;
	;; 48K sound production
	;;

	;; Main exported functions:
	;; * AltPlaySound
	;; * IrqFn
	;; * PlaySound

	;; FIXME: Needs a good, old tidy-up.
	
SndCount:	DEFB $00
Snd2:		DEFB $FF
L964C:		DEFB $00
L964D:		DEFB $00
SndEnable:	DEFB $80	; Top bit set if sound enabled.

        ;; This is patched by the 128K patch
AltPlaySound:	LD	A,(Snd2)
		CP	$00
		RET	Z
		LD	B,$C3
		JP	PlaySound

        ;; This is patched by the 128K patch
IrqFn:		JP	IrqFnCore

        ;; Blatted by 128K patch
	;; Ratio between elements are twelth root of two - definitions for notes in a scale.
ScaleTable:	DEFW 1316,1241,1171,1105,1042,983,927,875,825,778,734,692

        ;; This is patched by 128K patch
	;; FIXME: Called from everywhere.
	;; Called with B containing the sound id.
PlaySound:	LD	A,(SndEnable)
		RLA
		RET	NC		; Exit early if sound disabled.
		LD	HL,Snd2
		LD	A,(HL)
		CP	B
		RET	Z
		LD	A,B
		AND	$3F
		CP	$3F
		JR	NZ,PS_2
		INC	B
		JR	Z,PS_1
		LD	A,(HL)
		AND	A
		RET	Z
		LD	A,B
		DEC	A
		XOR	(HL)
		AND	$C0
		RET	NZ
PS_1:		LD	A,$FF
		LD	(HL),A
		RET
PS_2:		LD	C,A
		LD	A,B
		LD	D,$00
		DEC	HL
		LD	(HL),A
		RLCA
		RLCA
		AND	$03
		LD	B,A
		CP	$03
		JR	NZ,PS_3
		XOR	A
		LD	(HL),A
		LD	HL,$98E5
		JR	PS_6
PS_3:		LD	A,(Snd2)
		AND	A
		RET	Z
		LD	A,B
		CP	$02
		JR	Z,PS_5
		CP	$01
		LD	A,$F9
		JR	Z,PS_4
		LD	A,$FC
PS_4:		ADD	A,C
		RET	NC
		LD	C,A
PS_5:		LD	HL,SoundTable
		LD	E,B
		SLA	E
		ADD	HL,DE
		LD	E,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,E
PS_6:		LD	E,C
		SLA	E
		ADD	HL,DE
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		LD	A,(DE)
		AND	$07
		LD	C,A
		AND	$04
		JR	NZ,PS_8
		LD	A,C
		AND	$02
		LD	B,$0A
		JR	NZ,PS_7
		LD	B,$92
		RR	C
		JR	C,PS_7
		LD	B,$02
	;; Scribble over locations the interrupt handler cares about.
	;; So, disable interrupts.
PS_7:		DI
		LD	HL,SndCount
		LD	A,(HL)
		INC	HL
		LD	(HL),A
		LD	HL,SndCtrl
		LD	(HL),B 		; Write SndCtrl
		INC	HL
		INC	HL
		LD	(HL),E		; Write ScorePtr
		INC	HL
		LD	(HL),D
		XOR	A
		INC	HL
		LD	(HL),A		; Clear ScoreIdx
		EI
		RET
PS_8:		EX	DE,HL
		LD	B,(HL)
		INC	HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		LD	A,B
		AND	$02
		JR	Z,PS_9
		LD	A,(Snd2)
		AND	A
		JR	Z,PS_9
		LD	A,$FF
		LD	(Snd2),A
PS_9:		XOR	A
		LD	(SndThing),A
		CALL	DoSound
		LD	A,$FF
		LD	(SndThing),A
		RET

	;;  Core interrupt handler.
IrqFnCore:	LD	IY,SndCtrl
		LD	A,(Snd2)
		INC	A
		RET	Z
		LD	IX,(ScorePtr)
		LD	DE,(ScoreIdx)
		LD	D,$00
		ADD	IX,DE	   ; Generate current score pointer, put in IX.
		BIT	1,(IY+$00) ; SndCtrl
		JR	NZ,IFC_2
		LD	A,(NoteLen)
		AND	A
		JP	NZ,OtherSoundThing
		RES	4,(IY+$00) ; SndCtrl - turn on glissando
		CALL	GetScoreByte
		LD	D,A
		INC	A
		JR	NZ,IFC_4
		CALL	GetScoreByte
		CP	D
		JR	NZ,IFC_1
		LD	(Snd2),A
		RET
IFC_1:		AND	A
		JR	NZ,IFC_2
		LD	(ScoreIdx),A
		LD	IX,(ScorePtr)
IFC_2:		LD	D,(IX+$00)
		CALL	UnpackD
		LD	(IY+$05),D ; Something
		LD	B,$08
		LD	A,E
		AND	$02
		JR	NZ,IFC_3
		LD	B,$80
		RRC	E
		JR	C,IFC_3
		LD	B,$00
IFC_3:		LD	A,(SndCtrl)
		AND	$02
		OR	B
		LD	E,A
		AND	$02
		RLA
		RLA
		RLA
		OR	E
		LD	(SndCtrl),A
		CALL	GetScoreByte
		LD	D,A
IFC_4:		LD	A,(SndCtrl)
		AND	$F9
		LD	(SndCtrl),A 	; Turn off 0x2 and 0x4
		CALL	UnpackD
		LD	C,D
		LD	D,$00
		LD	HL,IrqArray
		ADD	HL,DE
		LD	A,(HL)
		LD	(NoteLen),A
		LD	A,C
		AND	A
		JR	NZ,IrqBits	; Tail call
		SET	2,(IY+$00)	; SndCtrl
		RET

GetScoreByte:	INC	IX		; Contains ScorePtr + ScoreIdx
		INC	(IY+$04)	; ScoreIdx
		LD	A,(IX+$00)
		RET

	;; More interrupt-related stuff...
IrqBits:	ADD	A,(IY+$05) 	; Something
	;; Divide A by 12, result plus one in C, remainder in A.
		LD	B,12
		LD	H,0
		LD	C,H
IB_0:		INC	C
		SUB	B
		JR	NC,IB_0
		ADD	A,B
	;; Look up the basic delay constant in the scale table.
		LD	L,A
		ADD	HL,HL
		LD	DE,ScaleTable
		ADD	HL,DE
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		INC	HL	; (Seems unnecessary??)
	;; Generate the octave constant in A.
		LD	B,C
		LD	A,$02
IB_1:		RLCA
		DJNZ	IB_1
		BIT	4,(IY+$00) 	; SndCtrl - get glissando bit
		JR	NZ,IB_2
	;; Glissando case: Double the constant and add 8. Don't ask me.
		RLCA			; Glissando case...
		ADD	A,$08
	;; Otherwise, don't.
IB_2:		LD	(SoundLenConst),A
	;; Now shift the delay constant (in DE), according to the octave we're in.
		LD	B,C
IB_3:		SRL	D
		RR	E
		DJNZ	IB_3
	;; Now some octave-specific cases:
		LD	A,C
		DEC	A
		JR	Z,IB_5	; Go to IB_5 if bottom octave/octave 1 (encoded as 0).
		LD	B,$09
		LD	A,$04
		SUB	C
		JR	C,IB_4	; Go to IB_4 if octave > 4
		RLA
		NEG
		ADD	A,B
		LD	B,A
IB_4:		LD	A,E
		SUB	B
		LD	E,A
		JR	NC,IB_5
		DEC	D
	;; Check for glissando
IB_5:		LD	A,(SndCtrl)
		AND	$90
		CP	$80
		JR	NZ,IB_8
	;; Glissando case
		LD	(SoundDelayTarget),DE
		LD	HL,(SoundDelayConst)
		EX	DE,HL
		XOR	A
		SBC	HL,DE		; Now contains difference between current and target.
		LD	A,(NoteLen)
	;; Count significant bits in A.
		LD	B,$08
IB_6:		RLA
		DEC	B
		JR	NC,IB_6
	;; Divide through by that.
IB_7:		SRA	H
		RR	L
		DJNZ	IB_7
	;; And that gives us our delta to finish in the appropriate timeframe.
		LD	(SoundDelayDelta),HL
		RES	4,(IY+$00) 	; SndCtrl - enable glissando.
		JR	DoCurrSound	; Tail call
	;; Non-glissando case
IB_8:		LD	(SoundDelayConst),DE
	;; NB: Fall through

DoCurrSound:	LD	B,(IY+$0A)	; SoundLenConst
		LD	DE,(SoundDelayConst)
		LD	A,(SndThing)
		INC	A
		RET	NZ
	;; Fall through!

	;; Writes out B edges with a delay constant of DE.
DoSound:	LD	A,E
	;; Bottom two bits control the overwrite of the jump to DS_1 -
	;; back jump to the OUT, or one of the INC HLs. 
		AND	$03
		NEG
		ADD	A,$F0
		LD	(DS_3+1),A
	;; Divide DE by 4.
		SRL	D
		RR	E
		SRL	D
		RR	E
	;; Load up previously written value...
		LD	A,(LastOut)
	;; Jump target area... these are simply delay ops.
		INC	HL
		INC	HL
		INC	HL
	;; Write/toggle the sound bit.
DS_1:		OUT	($FE),A
		XOR	$30
	;; Delay loop.
		LD	C,A
		PUSH	DE
DS_2:		DEC	DE
		LD	A,D
		OR	E
		JP	NZ,DS_2
		POP	DE
		LD	A,C
	;; And loop.			
DS_3:		DJNZ	DS_1		; Target of self-modifying code!
		RET

OtherSoundThing:LD	A,(SndCtrl)
		LD	B,A
		DEC	(IY+$01)	; NoteLen
		JR	NZ,OST_1
		AND	$80
		RET	Z		; Do nothing if NoteLen is zero, and top
					; bit of SndCtrl is reset.
		LD	A,B
OST_1:		AND	$0C
		RET	NZ		; Return if 0x8 or 0x4 bit set in SndCtrl
		LD	A,B
		AND	$90
		CP	$80
		JR	NZ,DoCurrSound  ; Skip if IrqFlag & 0x90 != 0x80
		LD	HL,(SoundDelayConst) ; Add SoundDelayDelta to SoundDelayConst
		LD	DE,(SoundDelayDelta)
		ADD	HL,DE
		LD	E,L
		LD	D,H
		LD	BC,(SoundDelayTarget)	; Check if we've hit the limit of the glissando.
		XOR	A
		SBC	HL,BC
		RRA
		XOR	A,(IY+$0B)	; SoundDelayDelta high byte - this bit is for signed check.
		RLA
		JR	C,OST_2
		SET	4,(IY+$00)	; Set 0x10 bit of SndCtrl - turn off glissando.
		LD	DE,(SoundDelayTarget) ; And use the target frequency
OST_2:		LD	(SoundDelayConst),DE
		JR	DoCurrSound 	; Tail call

UnpackD:	LD	BC,$0307
		LD	A,D
		AND	C
		LD	E,A		; Mask bottom 3 bits into E.
		LD	A,C
		CPL
		AND	D
		LD	D,A		; Mask top 5 bits of D.
UnpackD_1:	RRC	D
		DJNZ	UnpackD_1
		RET			; And rotate into bottom position.

IrqArray:	DEFB $01,$02,$04,$06,$08,$0C,$10,$20

SndThing:		DEFB $FF
SndCtrl:		DEFB $00
NoteLen:		DEFB $00
ScorePtr:		DEFW $0000
ScoreIdx:		DEFB $00
Something:		DEFB $00
SoundDelayTarget:	DEFW $0000
SoundDelayConst:	DEFW $0000
SoundLenConst:		DEFB $00
SoundDelayDelta:	DEFW $0000
	;; FIXME: Some constants seem to overlap with the table?
SoundTable:		DEFW $98E1,$98DD,$98CB,L9909,L9914
			DEFW L991F,L9932,L993D,L994A,L994D,L9950,L9958,L996A
			DEFW L995B,L9903,L9906,L9954,L9972,L9983,L99DD,L999E
			DEFW L99A9,L98F7,L99CD,L99D5

L98F7:	DEFB $10,$95,$6A,$62,$6A,$7D,$6D,$04
	DEFB $8D,$96,$FF,$FF

L9903:	DEFB $16,$90,$00

L9906:	DEFB $14,$00,$02

L9909:	DEFB $82,$31,$52,$41,$2A,$31
	DEFB $1A,$29,$42,$FF,$00

L9914:	DEFB $82,$31,$51,$41,$29,$31,$19,$29,$41,$FF,$00
	
L991F:	DEFB $22,$F3,$EB,$E3,$DB,$EB,$E3,$DB,$D3,$E3,$DB,$D3,$CB,$DB,$D3,$CB
	DEFB $C3,$FF,$00

L9932:	DEFB $22,$BB,$A3,$8B,$73,$5B,$43,$2B,$23,$FF,$00

L993D:	DEFB $22,$13
	DEFB $33,$53,$73,$93,$B3,$D3,$DB,$E3,$EE,$FF,$00

L994A:	DEFB $64,$80,$00

L994D:	DEFB $46,$A0
	DEFB $00

L9950:	DEFB $31,$DA,$65,$F4 ; Fall through?

L9954:	DEFB $01,$01,$FF,$FF

L9958:	DEFB $46,$D0,$00 	; Fall through?

L995B:	DEFB $01,$51,$BB,$FF 	; Fall through?
L995F:	DEFB $08,$04,$30,$04,$28,$04,$20,$04,$18,$FF,$FF

L996A:	DEFB $41,$10,$5C,$5C,$43
	DEFB $07,$FF,$FF

L9972:	DEFB $61,$0C,$36,$FF,$60,$35,$35,$35,$45,$35,$45,$FF,$61
	DEFB $56,$56,$FF,$FF
L9983:	DEFB $30,$B2,$BA,$CC,$34,$34,$6A,$5A,$52,$6A,$92,$8A
	DEFB $94,$C2,$CA,$DC,$44,$44,$A2,$92,$8A,$92,$8A,$7A,$6E,$FF,$FF

L999E:	DEFB $11
	DEFB $30,$52,$01,$19,$3A,$01,$09,$22,$FF,$FF

L99A9:	DEFB $20,$45,$FF,$80,$7B,$73
	DEFB $7B,$6B,$FF,$20,$2D,$FF,$80,$63,$5B,$63,$53,$FF,$20,$0D,$FF,$80
	DEFB $43,$3B,$43,$33,$FF,$20,$1D,$FF,$80,$53,$4B,$53,$FF,$FF

L99CD:	DEFB $41,$09,$3E,$5E,$CE,$F6,$FF,$FF

L99D5:	DEFB $41,$F0,$A6,$5E,$3E,$0E,$FF,$FF

L99DD:	DEFB $02,$52
	DEFB $32,$54,$6A,$52,$6C,$82,$6A,$7A,$92,$FF,$61,$F6,$00,$FF,$2A,$52
	DEFB $32,$54,$6A,$52,$6C,$82,$6A,$7A,$92,$FF,$89,$32,$0A,$32,$32,$00
	DEFB $FF,$3A,$52,$32,$54,$6A,$52,$6C,$82,$6A,$7A,$92,$FF,$99,$F6,$FF
	DEFB $62,$F2,$EA,$DA,$CA,$BA,$B2,$A2,$92,$8A,$7A,$6A,$FF,$61,$50,$53
	DEFB $34,$34,$FF,$00,$FF,$FF
