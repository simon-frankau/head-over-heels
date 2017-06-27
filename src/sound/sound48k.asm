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
Snd2:		DEFB $FF        ; TODO: $FF = end of sound?
L964C:		DEFB $00
L964D:		DEFB $00
SndEnable:	DEFB $80	; Top bit set if sound enabled.

;; (Overwritten by 128K patch)
AltPlaySound:	LD	A,(Snd2)
		CP	$00
		RET	Z
		LD	B,$C3
		JP	PlaySound

;; (Overwritten by 128K patch)
IrqFn:          JP      SndHandler

;; (Overwritten by 128K patch)
;; Ratio between elements are twelth root of two - definitions for
;; notes in a scale.
ScaleTable:     DEFW 1316,1241,1171,1105,1042,983,927,875,825,778,734,692

        ;; This is patched by 128K patch
	;; FIXME: Called from everywhere.
	;; Called with B containing the sound id.
        
;; May play the sound either immediately or using the interrupt-driven
;; mechanism.
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
        ;; Interrupt-driven sound-playing.
		LD	A,C
		AND	$02
		LD	B,$0A
		JR	NZ,PS_7
		LD	B,$92
		RR	C
		JR	C,PS_7
		LD	B,$02
        ;; TODO: SndCtrl is 8|2, 80|10|2 or 2...
	;; Scribble over locations the interrupt handler cares about.
	;; So, disable interrupts.
PS_7:		DI
        ;; Copy SndCount into Snd2.
		LD	HL,SndCount
		LD	A,(HL)
		INC	HL
		LD	(HL),A
        ;; Then write the main sound-triggering variables
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
        ;; Immediate sound-playing case.
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

;; Sound interrupt handler.
SndHandler:     LD      IY,SndCtrl
        ;; If Snd2 == $FF, nothing to do.
                LD      A,(Snd2)
                INC     A
                RET     Z
        ;; Generate the current score pointer, put it in IX.
                LD      IX,(ScorePtr)
                LD      DE,(ScoreIdx)
                LD      D,$00
                ADD     IX,DE
        ;; If $02 bit of SndCtrl is set, start the score
                BIT     1,(IY+SND_CTRL)
                JR      NZ,PlayNextPhrase
        ;; If the note hasn't finished, play more of it.
                LD      A,(NoteLen)
                AND     A
                JP      NZ,DoNoteCont
        ;; If note length has reached zero, at which point we pick
        ;; up the next note.
                RES     4,(IY+SND_CTRL) ; Disable 'glissando complete'
                CALL    GetScoreByte
                LD      D,A
                INC     A
                JR      NZ,PlayNextNote ; Usual next-note case.
        ;; If next byte is $FF, it's a special case:
                CALL    GetScoreByte
                CP      D
                JR      NZ,SH_1
        ;; Following byte also $FF? End of score. Set Snd2 to $FF and return.
                LD      (Snd2),A
                RET
SH_1:           AND     A
                JR      NZ,PlayNextPhrase
        ;; Follwing byte was $00. Loop to start of score.
                LD      (ScoreIdx),A
                LD      IX,(ScorePtr)
        ;; NB: Fall through.

;; Read the next byte and start playing...
PlayNextPhrase: LD      D,(IX+$00)
                CALL    UnpackD
        ;; Load an absolute value for the note.
                LD      (IY+SND_NOTE),D
        ;; Cases for E & $03:
        ;; 0: B = $00 - usual.
        ;; 1: B = $80 - glissando.
        ;; 2: B = $08 - silence.
                LD      B,$08
                LD      A,E
                AND     $02
                JR      NZ,PNP_2
                LD      B,$80
                RRC     E
                JR      C,PNP_2
                LD      B,$00
        ;; Set up the control flags for the new phrase...
PNP_2:          LD      A,(SndCtrl)
                AND     $02             ; Only keep 'new score' flag.
                OR      B
                LD      E,A
        ; Copy $02 flag to $10 - no glissando at start of score.
                AND     $02
                RLA
                RLA
                RLA
        ;; And add in the new phrase control flags.
                OR      E
                LD      (SndCtrl),A
        ;; And now get the first byte to play...
                CALL    GetScoreByte
                LD      D,A
        ;; There's a score byte in D.

;; Play the next note.
PlayNextNote:   LD      A,(SndCtrl)
                AND     ~$06
                LD      (SndCtrl),A     ; Turn off new phrase and rest flags
        ;; Unpack the score byte to length and pitch delta from previous...
                CALL    UnpackD
                LD      C,D
                LD      D,$00
                LD      HL,NoteLens
                ADD     HL,DE
                LD      A,(HL)
                LD      (NoteLen),A
                LD      A,C
                AND     A
        ;; then play it.
                JR      NZ,DoNote       ; Tail call
                SET     2,(IY+SND_CTRL) ; Set rest (silence) if pitch was 0.
                RET

;; Update both the in-register pointer, and the index in memory, and
;; fetch the next byte of score (in A).
GetScoreByte:   INC     IX              ; Contains ScorePtr + ScoreIdx
                INC     (IY+SCORE_IDX)
                LD      A,(IX+$00)
                RET

;; Play a new note, specified in Sound Note.
;; Note is passed in in A, as an offset from previous note.
DoNote:         ADD     A,(IY+SND_NOTE)
        ;; Divide A by 12 to get octave and note:
        ;; Result plus one in C (octave), remainder in A (note in scale).
                LD      B,12
                LD      H,0
                LD      C,H
DN_0:           INC     C
                SUB     B
                JR      NC,DN_0
                ADD     A,B
        ;; Look up the delay constant in the scale table, put in DE.
                LD      L,A
                ADD     HL,HL
                LD      DE,ScaleTable
                ADD     HL,DE
                LD      E,(HL)
                INC     HL
                LD      D,(HL)
                INC     HL              ; (Seems unnecessary??)
        ;; Calculate the sound length:
        ;; Base it on the octave - each octave makes the note last half as
        ;; many cycles, so we'll double the number of cycles to keep the
        ;; note length more-or-less constant.
                LD      B,C
                LD      A,$02
DN_1:           RLCA
                DJNZ    DN_1
        ;; If 'glissando complete' is not set, make the note run a bit longer:
                BIT     4,(IY+SND_CTRL)
                JR      NZ,DN_2
        ;; Double the constant and add 8.
                RLCA
                ADD     A,$08
        ;; Then store it in SndLen.
DN_2:           LD      (SndLen),A
        ;; Now shift the delay constant (in DE), according to the
        ;; octave we're in, to get a note pitched to the right octave.
                LD      B,C
DN_3:           SRL     D
                RR      E
                DJNZ    DN_3
        ;; Now some octave-specific cases:
        ;; I assume this is a minor tweak to improve the tuning.
                LD      A,C
                DEC     A
                JR      Z,DN_5  ; No adjustment for bottom octave (C == 1)
                LD      B,$09
                LD      A,$04
                SUB     C
                JR      C,DN_4  ; B = 9 for octave > 4
                RLA             ; A = 2 * (4 - C)
                NEG             ; A = 2 * C - 8
                ADD     A,B     ; A = 2 * C + 1
                LD      B,A     ; B = 2 * C + 1
DN_4:           LD      A,E     ; And then subtract B from DE
                SUB     B
                LD      E,A
                JR      NC,DN_5
                DEC     D
        ;; Check for glissando
DN_5:           LD      A,(SndCtrl)
                AND     $90
                CP      $80     ; Need glissando set, glissando not complete.
                JR      NZ,DN_8
        ;; Glissando case
                LD      (SndWavelenTgt),DE
                LD      HL,(SndWavelen)
                EX      DE,HL
                XOR     A
                SBC     HL,DE   ; Now contains difference between current and target.
                LD      A,(NoteLen)
        ;; Count significant bits in A.
                LD      B,$08
DN_6:           RLA
                DEC     B
                JR      NC,DN_6
        ;; Divide through by that.
DN_7:           SRA     H
                RR      L
                DJNZ    DN_7
        ;; And that gives us our delta to finish in the appropriate timeframe.
                LD      (SndWavelenDelta),HL
                RES     4,(IY+SND_CTRL) ; Glissando not complete.
                JR      DoCurrSound     ; Tail call
        ;; Non-glissando case
DN_8:           LD      (SndWavelen),DE
        ;; NB: Fall through

;; Play the sound with the current length (cycle count) and wavelength.
DoCurrSound:    LD      B,(IY+SND_LEN)
                LD      DE,(SndWavelen)
                LD      A,(SndThing)
                INC     A
                RET     NZ
        ;; Fall through!

;; Writes out B edges with a delay constant of DE.
DoSound:        LD      A,E
        ;; Bottom two bits control the overwrite of the jump to DS_1 -
        ;; back jump to the OUT, or one of the INC HLs.
                AND     $03
                NEG
                ADD     A,$F0
                LD      (DS_3+1),A
        ;; Divide DE by 4.
                SRL     D
                RR      E
                SRL     D
                RR      E
        ;; Load up previously written value...
                LD      A,(LastOut)
        ;; Jump target area... these are simply delay ops.
                INC     HL
                INC     HL
                INC     HL
        ;; Write/toggle the sound bit.
DS_1:           OUT     ($FE),A
                XOR     $30
        ;; Delay loop.
                LD      C,A
                PUSH    DE
DS_2:           DEC     DE
                LD      A,D
                OR      E
                JP      NZ,DS_2
                POP     DE
                LD      A,C
        ;; And loop.
DS_3:           DJNZ    DS_1            ; Target of self-modifying code!
                RET

;; Play an existing note, performing glissando update step etc. as needed.
DoNoteCont:
        ; Do nothing if NoteLen is zero, and not glissando.
                LD      A,(SndCtrl)
                LD      B,A
                DEC     (IY+NOTE_LEN)
                JR      NZ,DNC_1
                AND     $80
                RET     Z
                LD      A,B
        ;; Silent if 0x8 (silent phrase) or 0x4 (rest) bit set in SndCtrl
DNC_1:          AND     $0C
                RET     NZ
        ;; Just go play sound if not glissando (SndCtrl & 0x90 != 0x80)
                LD      A,B
                AND     $90
                CP      $80
                JR      NZ,DoCurrSound  ; Jump if not glissando.
        ;; With glissando, apply delta to wavelength
                LD      HL,(SndWavelen)
                LD      DE,(SndWavelenDelta)
                ADD     HL,DE
                LD      E,L
                LD      D,H
        ;; Now check if we've hit the limit of the glissando:
                LD      BC,(SndWavelenTgt)
                XOR     A
                SBC     HL,BC
                RRA                     ; Put carry in high bit of A.
        ;; And compare with sign of SndWavelenDelta high byte - have
        ;; we gone past in the right direction?
                XOR     A,(IY+SND_WAVELEN_DELTA)
                RLA
                JR      C,DNC_2
        ;; We have passed the target:
        ;; Set glissando complete bit...
                SET     4,(IY+SND_CTRL)
        ;; And use the target frequency...
                LD      DE,(SndWavelenTgt)
        ;; Update SndWavelen and run the sound.
DNC_2:          LD      (SndWavelen),DE
                JR      DoCurrSound     ; Tail call

;; Given a byte in D, put the bottom three bits in E, and the next
;; five in D (rotated to the bottom).
UnpackD:        LD      BC,$0307
                LD      A,D
                AND     C
                LD      E,A             ; Mask bottom 3 bits into E.
                LD      A,C
                CPL
                AND     D
                LD      D,A             ; Mask top 5 bits of D.
UnpackD_1:      RRC     D
                DJNZ    UnpackD_1
                RET                     ; And rotate into bottom position.

;; Look-up table of note lengths.
NoteLens:	DEFB $01,$02,$04,$06,$08,$0C,$10,$20

;; Flags for SndCtrl:
;; $02 - start score
;; $04 - is a rest - silence
;; $08 - silence for whole phrase
;; $10 - glissando completed
;; $80 - glissando wanted

SndThing:		DEFB $FF
SndCtrl:		DEFB $00
NoteLen:		DEFB $00
ScorePtr:		DEFW $0000
ScoreIdx:		DEFB $00
SndNote:		DEFB $00         ; Musical scale note number.
SndWavelenTgt:		DEFW $0000       ; Target wavelen for glissando.
SndWavelen:		DEFW $0000       ; Delay between edges to play.
SndLen:			DEFB $00         ; Number of edges to play.
SndWavelenDelta:	DEFW $0000       ; Delta to apply when glissando-ing.

;; Offsets from SndCtrl, used with IY.
SND_CTRL:		EQU 0
NOTE_LEN:		EQU 1
SCORE_PTR:		EQU 2
SCORE_IDX:		EQU 4
SND_NOTE:		EQU 5
SND_WAVELEN_TGT:	EQU 6
SND_WAVELENGTH:		EQU 8
SND_LEN:		EQU 10
SND_WAVELEN_DELTA:	EQU 11
        
        
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
