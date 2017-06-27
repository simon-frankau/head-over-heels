;;
;; sound128k.asm
;;
;; 128K sound production. Copied to alternate memory bank.
;;

;; Address of the bank where this code gets mapped.
BankDest:       EQU     $C000

;; AY-3-8912 registers
AY_AFINE:       EQU 0   ; Channel A fine pitch    8-bit (0-255)
AY_ACOARSE:     EQU 1   ; Channel A course pitch  4-bit (0-15)
AY_BFINE:       EQU 2   ; Channel B fine pitch    8-bit (0-255)
AY_BCOARSE:     EQU 3   ; Channel B course pitch  4-bit (0-15)
AY_CFINE:       EQU 4   ; Channel C fine pitch    8-bit (0-255)
AY_CCOARSE:     EQU 5   ; Channel C course pitch  4-bit (0-15)
AY_NOISE:       EQU 6   ; Noise pitch             5-bit (0-31)
AY_MIXER:       EQU 7   ; Mixer                   8-bit
AY_AVOL:        EQU 8   ; Channel A volume        4-bit (0-15)
AY_BVOL:        EQU 9   ; Channel B volume        4-bit (0-15)
AY_CVOL:        EQU 10  ; Channel C volume        4-bit (0-15)

;; Label for start of copyable data
BankStart:

                .phase BankDest

;; Write out the current AYRegs to the AY-3
WriteAY3:       LD      HL,AYRegs
        ;; Write control values 0-10, with consecutive data values.
                LD      D,$00
WAY_1:          LD      E,(HL)
                INC     HL
                CALL    WriteAY3Reg
                INC     D
                LD      A,D
                CP      $0B
                JR      NZ,WAY_1
                RET

;; Write a single AY-3 register: Control value in D, data value in E.
WriteAY3Reg:    LD      BC,$FFFD
                OUT     (C),D
                LD      B,$BF
                OUT     (C),E
                RET

LC01B:		DEFB $EE,$0E,$18,$0E,$4D,$0D,$8E,$0C,$DA,$0B,$2F,$0B,$8F,$0A,$F7,$09
LC02B:		DEFB $68,$09,$E1,$08,$61,$08,$E9,$07,$77,$07

Irq128:
        ;; Top-bit of SndEnable reset means sound is off.
                LD      A,(SndEnable)
                RLA
                RET     NC
                CALL    UpdateSound
        ;; Start with voice 0.
                XOR     A
                LD      (CurrVoice),A
        ;; Disable all voices in mixer.
                LD      A,$3F
                LD      (AYRegs + AY_MIXER),A
                LD      HL,CurrVoice
        ;; And loop over voices...
I128_1:         LD      B,(HL)
        ;; Set bit? Then skip this voice.
                CALL    GetSoundBit
                JR      C,I128_4
        ;; Put voice state into IX.
                CALL    GetCurrVoice
                PUSH    HL
                POP     IX
        ;; If bit 5 is not set, skip this voice.
                BIT     5,(HL)
                JR      NZ,I128_4
        ;; Load IY with AYRegs offset by voice number * 2 (for pitch regs).
                LD      IY,AYRegs
                LD      E,A
                LD      D,$00
                PUSH    DE
                SLA     E
                ADD     IY,DE
        ;; Load HL with volume register address
                LD      HL,AYRegs + AY_AVOL
                POP     DE
                ADD     HL,DE
        ;; Set fine pitch
                LD      A,(IX+$08)
                LD      (IY+$00),A
        ;; Set coarse pitch
                LD      A,(IX+$09)
                LD      (IY+$01),A
        ;; HL = IX[1]
                LD      B,D
                LD      E,(IX+$01)
                LD      D,(IX+$02)
                EX      DE,HL
        ;; HL += IX[3]
                LD      C,(IX+$03)
                ADD     HL,BC
        ;; Deref into A, and take bottom 4 bits.
                EX      DE,HL
                LD      A,(DE)
                AND     $0F
        ;; If non-zero, add IX[0xB], saturating at 0x0F.
                JR      Z,I128_2
                ADD     A,(IX+$0B)
                CP      $10
                JR      C,I128_2
                LD      A,$0F
        ;; And write this back to volume address register.
I128_2:         LD      (HL),A
        ;; Create a bitmask with only current voice bit unset.
                LD      A,(CurrVoice)
                LD      B,A
                INC     B
                LD      A,$FF
                AND     A
I128_3:         RLA
                DJNZ    I128_3
        ;; Notes are active-low, so activate the current voice.
                LD      HL,AYRegs + AY_MIXER
                AND     (HL)
                LD      (HL),A
        ;; Go to next voice.
I128_4:         LD      HL,CurrVoice
                LD      A,$02
                CP      (HL)
                JP      Z,I128_5
                INC     (HL)
                JR      I128_1
        ;; We have finished looping through the voices.
I128_5:
        ;; Write sound state if voice 0's first byte has $20 set, or $08 reset.
                LD      HL,Voices
                LD      A,$08
                XOR     (HL)
                AND     $28
                JP      NZ,WriteAY3     ; Tail call
        ;; Write sound state if voice 0 is disabled (?!)
                LD      A,(SndEnable)
                RRA
                JP      C,WriteAY3
        ;; TODO: ??? Something to do with noise part.
                LD      HL,AYRegs + AY_NOISE
                LD      IY,LC51B
                LD      A,(IY+$07) ; Set noise reg.
                LD      (HL),A
                INC     HL
                LD      A,(IY+$00) ; Maybe disable voice 0
                AND     $01
                OR      (HL)
                AND     ~$08       ; Enable noise gen
                LD      (HL),A
                JP      WriteAY3   ; NB: Tail call

;; Run through the voices. If they're enabled, call UpdateVoice.
UpdateSound:    XOR     A
                LD      (CurrVoice),A
US_1:           LD      B,A
                CALL    GetSoundBit
                CALL    NC,UpdateVoice
                LD      HL,CurrVoice
                LD      A,(HL)
                CP      $02
                RET     Z
                INC     A
                LD      (HL),A
                JR      US_1

;; Extract the nth bit of SndEnable into carry flag.
;; Inverse of SetSoundBit, basically.
;;
;; Bit is set if voice is disabled.
;;
;; Takes the bit number in B.
GetSoundBit:    LD      A,(SndEnable)
                INC     B
GSB_1:          RRCA
                DJNZ    GSB_1
                RET

UpdateVoice:	LD	HL,CurrVoice
		LD	L,(HL)
		LD	DE,LC4DC
		LD	H,$00
		ADD	HL,HL
		ADD	HL,DE
		LD	(LC4D3),HL
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		PUSH	DE
		POP	IX
		CALL	GetCurrVoice
		PUSH	HL
		POP	IY
		BIT	1,(HL)
		JP	NZ,LC2B8
		DEC	(IY+$0D)
		JR	NZ,XE_1
		CALL	CC2F9
		BIT	3,(IY+$00)
		RET	Z
		LD	IY,LC51B
		XOR	A
		LD	(IY+$03),A
		JP	XE_7
XE_1:		DEC	(IY+$04)
		CALL	Z,CC1CB
		LD	L,(IY+$08)
		LD	H,(IY+$09)
		BIT	7,(IY+$00)
		JR	Z,XE_5
		LD	A,$01
		BIT	7,(IY+$0C)
		JR	Z,XE_2
		LD	A,$FF
XE_2:		ADD	A,(IY+$0F)
		LD	(IY+$0F),A
		LD	B,A
		LD	A,(IY+$0C)
		CP	B
		JR	NZ,XE_3
		NEG
		LD	(IY+$0C),A
		NEG
XE_3:		LD	E,(IY+$0E)
		LD	D,$00
		RLCA
		JR	C,XE_4
		SBC	HL,DE
		JR	XE_5
XE_4:		ADD	HL,DE
XE_5:		LD	A,(IY+$00)
		AND	$50
		CP	$40
		JR	NZ,XE_6
		LD	E,(IY+$11)
		LD	D,(IY+$12)
		ADD	HL,DE
		LD	D,H
		LD	E,L
		LD	C,(IY+$06)
		LD	B,(IY+$07)
		XOR	A
		SBC	HL,BC
		RLA
		XOR	A,(IY+$00)
		AND	$01
		EX	DE,HL
		JR	NZ,XE_6
		SET	4,(IY+$00)
		XOR	A
		LD	(IY+$0F),A
		LD	L,(IY+$06)
		LD	H,(IY+$07)
XE_6:		LD	(IY+$08),L
		LD	(IY+$09),H
		BIT	3,(IY+$00)
		RET	Z
		LD	IY,LC51B
		DEC	(IY+$04)
		RET	NZ
XE_7:		CALL	CC1CB
		AND	A
		JR	NZ,XE_8
		OR	A,(IY+$03)
		RET	NZ
XE_8:		LD	A,(HL)
		AND	$0F
		BIT	7,(IY+$00)
		JR	Z,XE_9
		NEG
XE_9:		ADD	A,(IY+$06)
		LD	(IY+$07),A
		RET

CC1CB:		LD	L,(IY+$01)
		LD	H,(IY+$02)
		LD	E,(IY+$03)
		XOR	A
		LD	D,A
		ADD	HL,DE
		BIT	7,(HL)
		JR	NZ,XF_3
		BIT	6,(HL)
		JR	Z,XF_1
		BIT	2,(IY+$00)
		SET	2,(IY+$00)
		JR	Z,XF_2
		RES	2,(IY+$00)
		LD	(IY+$03),A
		JR	XF_2
XF_1:		INC	(IY+$03)
XF_2:		LD	A,(IY+$05)
XF_3:		LD	(IY+$04),A
		RET

DisableCurrVoice:
		LD	HL,IntSnd
		LD	A,(CurrVoice)
		LD	E,A
		LD	D,$00
		ADD	HL,DE
		LD	(HL),$FF
		LD	B,A
        ;; NB: Fall through

;; Normally, SndEnable's top bit is used for enable/disable of sound.
;; We're stashing stuff in the lower bits.
;;
;; Takes the bit number in B.
SetSoundBit:
        ;; Convert bit number to a bit mask.
                INC     B
                LD      HL,SndEnable
                XOR     A
                SCF
SSB_1:          RLA
                DJNZ    SSB_1
                LD      B,A
        ;; "Or" the mask into SndEnable.
                OR      (HL)
                LD      (HL),A
                RET

;; B contains the sound id to play.
Play128:	LD	A,B
        ;; Mask off 0x3F, and if value is 0x3F, make it 0xFF.
		AND	$3F
		CP	$3F
		JR	NZ,P128_1
		LD	A,$FF
P128_1:		LD	C,A
        ;; Take those original top two bits and put them in the low bits of A.
		LD	A,B
		RLCA
		RLCA
		AND	$03
		LD	B,A
        ;; Go to P128_2 for high id sounds.
		CP	$03
		JR	Z,P128_2
        ;; TODO
		LD	HL,IntSnd
		LD	E,B
		LD	D,$00
		ADD	HL,DE
		LD	A,(HL)
		CP	C
		RET	Z
		CP	$80
		RET	Z
		LD	(HL),C
		LD	A,C
		INC	A
		JR	Z,SetSoundBit
		LD	HL,LC6CD
		SLA	E
		ADD	HL,DE
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		LD	E,C
		SLA	E
		ADD	HL,DE
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		PUSH	HL
		LD	HL,VoiceData
		LD	E,B
		SLA	E
		ADD	HL,DE
		PUSH	HL
		LD	A,B
		CALL	GetVoice
		LD	D,H
		LD	E,L
		LD	B,A
		CALL	SetSoundBit
		LD	A,B
		POP	HL
		POP	BC
		LD	(HL),C
		INC	HL
		LD	(HL),B
		EX	DE,HL
		SET	1,(HL)
		LD	HL,SndEnable
		XOR	(HL)
		LD	(HL),A
		RET
        ;; Top two bits of sound id were set.
P128_2:
        ;; HL = C * 6
                LD      H,$00
                LD      L,C
                ADD     HL,HL
                LD      D,H
                LD      E,L
                ADD     HL,HL
                ADD     HL,DE
        ;; Set HL to HiSndTable + C * 6
                LD      DE,HiSndTable
                ADD     HL,DE
        ;; For each voice...
                LD      A,$03
P128_3:
        ;; Read voice data pointer for next voice, push that and
        ;; updated HiSndTable pointer.
                LD      E,(HL)
                INC     HL
                LD      D,(HL)
                INC     HL
                PUSH    DE
                PUSH    HL
        ;; Get voice into HL.
                DEC     A
                CALL    GetVoice
        ;; Bring HiSndTable pointer back into DE, push voice pointer.
                POP     DE
                PUSH    HL
        ;; HST pointer back in HL
                EX      DE,HL
        ;; And loop.
                AND     A
                JR      NZ,P128_3
        ;; Now we have 3 data/state pairs pushed on the stack.
        ;; Set bits [012] of SndEnable, to disable interrupt-driven
        ;; update while we modify.
                LD      HL,SndEnable
                LD      A,$07
                OR      (HL)
                LD      (HL),A
        ;; Load $80 into the 3 elements of the IntSnd array.
                LD      HL,IntSnd
                LD      BC,$0380
                LD      A,B
P128_4:         LD      (HL),C
                INC     HL
                DJNZ    P128_4
        ;; Then process the 3 stack pairs...
                LD      HL,VoiceData
P128_5:         POP     DE      ; Voice pointer
                POP     BC      ; Data pointer
        ;; Stash data in VoiceData.
                LD      (HL),C
                INC     HL
                LD      (HL),B
                INC     HL
        ;; Set bit 1 in first byte of the voice structure.
                EX      DE,HL
                SET     1,(HL)
                EX      DE,HL
                DEC     A
                JR      NZ,P128_5
        ;; And reset bits [012] of SndEnable, so they can be played.
                LD      HL,SndEnable
                LD      A,~$07
                AND     (HL)
                LD      (HL),A
                RET

LC2B8:		CALL	CC2D1
		LD	BC,$0203
		CALL	CC409
		LD	(IY+$0A),D
		LD	(IY+$0B),E
		INC	IX
		CALL	CC418
		INC	IX
		JP	CC2F9

CC2D1:		LD	HL,(LC4D3)
		LD	DE,-6
		ADD	HL,DE
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		PUSH	DE
		POP	IX
		RET

        ;; TODO: A bit messy
LC2DF:		CALL	CC2D1
		INC	IX
		JR	LC2F4
LC2E6:		INC	IX
		CP	A,(IX+$00)
		JR	Z,LC2DF
		DEC	A
		CP	A,(IX+$00)
		JP	Z,DisableCurrVoice
LC2F4:		CALL	CC418
		INC	IX
        ;; Fall through.
        
CC2F9:		RES	4,(IY+$00)
		LD	A,(IX+$00)
		INC	A
		JP	Z,LC2E6
		LD	BC,$0307
		CALL	CC409
		LD	C,D
		LD	HL,LC531
		LD	D,$00
		ADD	HL,DE
		LD	A,(HL)
		LD	(IY+$0D),A
		XOR	A
		CP	C
		JR	NZ,LC330
		SET	5,(IY+$00)
		JP	LC3F5

;; Get the voice structure for the current voice into HL.
GetCurrVoice:   LD      A,(CurrVoice)
        ;; Fall through

;; Get the 19-byte structure for the voice in A (0-2), into HL.
GetVoice:       LD      HL,Voices
                AND     A
                RET     Z
                LD      DE,19
                LD      B,A
GV_1:           ADD     HL,DE
                DJNZ    GV_1
                RET

LC330:		RES	5,(IY+$00)
		LD	A,(IY+$0A)
		ADD	A,C
		LD	BC,$FF0C
XJ_1:		INC	B
		SUB	C
		JR	NC,XJ_1
		ADD	A,C
		ADD	A,A
		LD	E,A
		LD	D,$00
		LD	HL,LC01B
		ADD	HL,DE
		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		INC	HL
		LD	C,(HL)
		INC	HL
		LD	A,(HL)
		INC	B
		JR	XJ_3
XJ_2:		SRL	A
		RR	C
		SRL	D
		RR	E
XJ_3:		DJNZ	XJ_2
		LD	B,A
		LD	A,(IY+$00)
		AND	$42
		CP	$40
		JR	NZ,XJ_4
		LD	(IY+$06),E
		LD	(IY+$07),D
		JR	XJ_5
XJ_4:		LD	(IY+$08),E
		LD	(IY+$09),D
XJ_5:		BIT	7,(IY+$00)
		JR	Z,XJ_11
		EX	DE,HL
		AND	A
		SBC	HL,BC
		SRL	L
		SRL	L
		LD	A,(IY+$10)
		AND	A
		JR	Z,XJ_10
		LD	H,A
		LD	A,L
		JP	M,XJ_8
XJ_6:		RRC	H
		JR	C,XJ_9
		ADD	A,A
		JR	XJ_6
XJ_7:		RRA
XJ_8:		RRC	H
		JR	NC,XJ_7
XJ_9:		LD	L,A
XJ_10:		LD	(IY+$0E),L
		XOR	A
		LD	(IY+$0F),A
XJ_11:		LD	A,(IY+$00)
		BIT	6,A
		JR	Z,XJ_16
		BIT	1,A
		JR	Z,XJ_12
		SET	4,(IY+$00)
		JR	XJ_16
XJ_12:		LD	L,(IY+$06)
		LD	H,(IY+$07)
		LD	E,(IY+$08)
		LD	D,(IY+$09)
		RR	(IY+$00)
		XOR	A
		SBC	HL,DE
		RL	(IY+$00)
		LD	C,(IY+$0D)
		LD	E,$80
		LD	B,$08
XJ_13:		LD	A,E
		AND	C
		JR	NZ,XJ_14
		RRC	E
		DJNZ	XJ_13
XJ_14:		RRCA
		JR	C,XJ_15
		SRA	H
		RR	L
		JR	XJ_14
XJ_15:		LD	(IY+$11),L
		LD	(IY+$12),H
		RES	4,(IY+$00)
XJ_16:		LD	(IY+$03),$00
		LD	A,(IY+$05)
		LD	(IY+$04),A
        ;; Fall through

LC3F5:		RES	1,(IY+$00)
		PUSH	IX
		POP	DE
		INC	DE
		LD	HL,(LC4D3)
		LD	(HL),E
		INC	HL
		LD	(HL),D
		RET

CC404:		LD	BC,$040F
		JR	LC40C

CC409:		LD	D,(IX+$00)
        ;; Fall through

LC40C:		LD	A,D
		AND	C
		LD	E,A
		LD	A,C
		CPL
		AND	D
		LD	D,A
XK_1:		RRC	D
		DJNZ	XK_1
		RET

CC418:		LD	BC,$040F
		CALL	CC409
		LD	A,$02
		AND	A,(IY+$00)
		LD	(IY+$00),A
		BIT	2,D
		JR	Z,XL_1
		SET	6,(IY+$00)
XL_1:		LD	A,$03
		AND	D
		JR	Z,XL_5
		PUSH	DE
		DEC	A
		LD	HL,LC52E
		LD	E,A
		LD	D,$00
		ADD	HL,DE
		LD	D,(HL)
		CALL	CC404
		LD	(IY+$0C),E
		LD	A,D
		CP	E
		LD	A,$00
		JR	Z,XL_4
		JR	NC,XL_2
		LD	A,D
		LD	D,E
		LD	E,A
		LD	A,$80
XL_2:		RR	E
		JR	C,XL_3
		RRC	D
		JR	XL_2
XL_3:		OR	D
XL_4:		LD	(IY+$10),A
		SET	7,(IY+$00)
		POP	DE
XL_5:		LD	HL,LC53F
		LD	D,$00
		ADD	HL,DE
		LD	D,(HL)
		CALL	CC404
		LD	(IY+$05),D
		LD	(IY+$04),D
		CALL	CC4C4
		LD	A,(CurrVoice)
		AND	A
		JR	NZ,XL_6
		RES	3,(IY+$00)
XL_6:		BIT	7,(IX+$00)
		RET	Z
		INC	IX
		AND	A
		RET	NZ
		SET	3,(IY+$00)
		PUSH	IY
		LD	IY,LC51B
		LD	E,(IX+$00)
		LD	A,$C0
		AND	E
		RLCA
		LD	(IY+$00),A
		LD	A,$0F
		AND	E
		LD	E,A
		LD	HL,LC539
		RLC	E
		LD	D,$00
		ADD	HL,DE
		LD	D,(HL)
		CALL	CC404
		LD	(IY+$04),D
		LD	(IY+$05),D
		INC	HL
		LD	A,(HL)
		LD	(IY+$06),A
		CALL	CC4C4
		ADD	A,(HL)
		LD	(IY+$07),A
		XOR	A
		LD	(IY+$03),A
		POP	IY
		RET

CC4C4:		LD	HL,LC54F
		LD	D,$00
		ADD	HL,DE
		LD	E,(HL)
		ADD	HL,DE
		LD	(IY+$01),L
		LD	(IY+$02),H
		RET

LC4D3:	DEFB $00,$00
CurrVoice:      DEFB $00               ; Current voice id (0-2)
VoiceData:      DEFW $0000,$0000,$0000 ; Pointer to voice data for 3 channels.
LC4DC:  DEFB $00,$00,$00,$00,$00,$00

;; 19 byte per-voice structure.
;; * 0x01-0x02: Pointer to vol array
;; * 0x03: Index into vol array
;; * 0x08: Fine pitch
;; * 0x09: Coarse pitch
;; * 0x0B: Volume addition
Voices:         DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


LC51B:  DEFB $00,$00,$00,$00,$00,$00,$00,$00
AYRegs:		DEFB $00,$00,$00,$00,$00,$00,$00,$3F,$00,$00,$00
LC52E:  DEFB $81,$42,$48
LC531:  DEFB $01,$02
XC533:	DEFB $04,$06,$08,$0C,$10,$20
LC539:  DEFB $12,$14,$10,$0C,$36,$00
LC53F:  DEFB $22,$10,$42,$11,$24,$12,$41,$16,$25,$13,$34,$17,$26,$44,$29,$18
LC54F:  DEFB $10,$09,$0F,$10
XC553:	DEFB $12,$1D,$20,$2A,$2C,$2E,$04,$05,$07,$09,$0A,$0B,$8C,$0C,$08,$04
XC563:	DEFB $01,$80,$08,$00,$0C,$00,$07,$00,$04,$00,$02,$00,$01,$80,$0C,$0A
XC573:	DEFB $08,$45,$02,$00,$00,$04,$00,$00,$06,$00,$00,$09,$00,$0C,$00,$40
XC583:	DEFB $08,$0A,$0C,$0C,$0B,$0A,$09,$08,$07,$06,$05,$04,$03,$02,$81

HiSndTable:     DEFW LC7CB,LC7CB,LC7CB ; $C0
                DEFW LC83F,LC853,LC868 ; $C1
                DEFW LC87D,LC899,LC8B5 ; $C2
                DEFW LC612,LC675,LC6A9 ; $C3
                DEFW LC6B5,LC6BD,LC6C5 ; $C4
                DEFW LC8C3,LC8D6,LC8E7 ; $C5
                DEFW LC609,LC5FC,LC5EA ; $C6
                DEFW LC5C8,LC5D2,LC5DF ; $C7
                DEFW LC8F8,LC902,LC90F ; $C8

LC5C8:          DEFB $A0,$7C,$30,$3E,$FF,$7B,$5E,$FE,$FF,$FF
LC5D2:          DEFB $B8,$7C,$31,$3E,$FF,$7B,$5E,$CE,$FF,$52,$AE,$FF,$FF
LC5DF:          DEFB $C3,$7C,$30,$3E,$FF,$FB,$44,$5E,$CE,$FF,$FF
LC5EA:          DEFB $93,$00,$95,$6A,$62,$6A,$7D,$6D,$FF,$82,$C0,$15,$FF,$03,$8D,$96
                DEFB $FF,$FF
LC5FC:          DEFB $90,$23,$F5,$CA,$C2,$CA,$DD,$CD,$05,$5D,$6E,$FF,$FF
LC609:          DEFB $60,$03,$07,$06,$05,$A5,$B6,$FF,$FF
LC612:          DEFB $90,$41,$31,$91,$95,$97,$84,$94,$FF,$22,$96,$06,$CE,$06,$FF,$41
                DEFB $51,$B1,$B5,$B7,$A4,$B4,$FF,$22,$B6,$06,$CE,$06,$FF,$41,$59,$B9
                DEFB $BD,$BF,$AC,$BC,$FF,$22,$BE,$06,$F6,$06,$FF,$41,$31,$91,$95,$97
                DEFB $84,$94,$FF,$22,$96,$06,$CE,$06,$FF,$41,$CA,$CD,$CF,$BC,$CC,$FF
                DEFB $22,$CE,$06,$EE,$06,$FF,$41,$C9,$F1,$F3,$03,$C9,$F1,$F3,$03,$07
                DEFB $C9,$F1,$F3,$03,$FF,$55,$F2,$CA,$EA,$DA,$B2,$CA,$BA,$92,$B2,$A4
                DEFB $6A,$FF,$00
LC675:          DEFB $62,$08,$36,$56,$6E,$7E,$86,$7E,$6E,$56,$36,$56,$6E,$7E,$86,$7E
                DEFB $6E,$56,$5E,$7E,$96,$A6,$AE,$A6,$96,$7E,$36,$56,$6E,$7E,$86,$7E
                DEFB $6E,$56,$6E,$8E,$A6,$B6,$BE,$B6,$A6,$8E,$96,$7E,$6E,$56,$6E,$7E
                DEFB $86,$8E,$FF,$00
LC6A9:          DEFB $93,$05,$34,$94,$54,$B4,$6C,$CC,$7C,$DC,$FF,$00
LC6B5:          DEFB $60,$51,$32,$B5,$55,$32,$FF,$FF
LC6BD:          DEFB $C0,$51,$92,$CD,$95,$92,$FF,$FF
LC6C5:          DEFB $60,$51,$92,$6D,$95,$92,$FF,$FF
LC6CD:          DEFB $F7,$C6,$E5,$C6,$D3,$C6
XC6D3:          DEFB $CF,$C7,$E5,$C7,$F5,$C7,$09,$C8,$15,$C8,$23,$C8,$28,$C8,$2D,$C8
XC6E3:          DEFB $38,$C8,$03,$C7,$10,$C7,$23,$C7,$46,$C7,$62,$C7,$71,$C7,$85,$C7
XC6F3:          DEFB $94,$C7,$9D,$C7,$C8,$C7,$C2,$C7,$DD,$C7,$B1,$C7,$A6,$C7,$BB,$C7
XC703:          DEFB $C0,$0E,$34,$4E,$5C,$6C,$74,$6C,$5E,$44,$26,$FF,$FF,$D0,$0E,$6E
XC713:          DEFB $96,$6E,$56,$FF,$01,$34,$36,$FF,$0E,$7C,$6C,$54,$6E,$47,$FF,$FF
XC723:          DEFB $C3,$03,$94,$8C,$94,$8C,$FF,$26,$76,$FF,$61,$6A,$72,$8A,$FF,$22
XC733:          DEFB $8A,$FF,$03,$94,$8C,$74,$8C,$94,$AC,$A4,$94,$FF,$26,$8F,$FF,$22
XC743:          DEFB $80,$FF,$FF,$60,$02,$6C,$96,$04,$96,$8C,$96,$94,$96,$FF,$0F,$8C
XC753:          DEFB $FF,$01,$AA,$FF,$41,$B2,$FF,$22,$B4,$FF,$02,$04,$96,$FF,$FF,$A8
XC763:          DEFB $0F,$35,$35,$55,$6D,$6E,$04,$55,$56,$04,$35,$36,$FF,$FF,$90,$0E
XC773:          DEFB $0C,$36,$24,$35,$45,$4E,$44,$4D,$35,$26,$34,$25,$0D,$FF,$0E,$27
XC783:          DEFB $FF,$FF,$40,$02,$36,$0C,$24,$36,$0C,$24,$34,$4C,$0C,$4C,$36,$FF
XC793:          DEFB $FF,$F0,$67,$10,$F6,$06,$16,$07,$FF,$FF,$27,$50,$51,$BB,$FF,$5D
XC7A3:          DEFB $97,$FF,$FF,$03,$CA,$44,$F0,$0F,$FF,$8C,$01,$0C,$FF,$FF,$A0,$40
XC7B3:          DEFB $30,$6C,$31,$6C,$41,$6C,$FF,$FF,$B3,$47,$10,$43,$00,$FF,$FF,$00
XC7C3:          DEFB $86,$82,$12,$FF,$FF,$03,$86,$41
LC7CB:          DEFB $11,$03,$FF,$FF,$D3,$29,$31,$51
XC7D3:          DEFB $01,$41,$29,$01,$31,$19,$01,$29,$41,$01,$FF,$00,$F3,$EB,$E3,$DB
XC7E3:          DEFB $FF,$FF,$D3,$09,$31,$51,$00,$41,$29,$00,$31,$19,$00,$29,$41,$00
XC7F3:          DEFB $FF,$00,$D3,$09,$F3,$EB,$E3,$DB,$EB,$E3,$DB,$D3,$E3,$DB,$D3,$CB
XC803:          DEFB $DB,$D3,$CB,$C3,$FF,$00,$D3,$09,$BB,$A3,$8B,$73,$5B,$43,$2B,$23
XC813:          DEFB $FF,$00,$D3,$09,$13,$33,$53,$73,$93,$B3,$D3,$DB,$E3,$EE,$FF,$00
XC823:          DEFB $78,$05,$33,$FF,$FF,$60,$25,$33,$FF,$FF,$D3,$60,$34,$6A,$FF,$09
XC833:          DEFB $01,$BA,$BA,$FF,$FF,$90,$44,$10,$43,$00,$FF,$FF
LC83F:          DEFB $90,$41,$0C,$36
XC843:          DEFB $FF,$02,$35,$35,$35,$45,$35,$45,$FF,$41,$56,$FF,$21,$57,$FF,$FF
LC853:          DEFB $90,$41,$0C,$6E,$FF,$02,$6D,$6D,$6D,$7D,$6D,$7D,$FF,$41,$D5,$FF
XC863:          DEFB $21,$D2,$D7,$FF,$FF
LC868:          DEFB $90,$41,$0C,$E6,$FF,$02,$B5,$B5,$B5,$C5,$B5
XC873:          DEFB $C5,$FF,$41,$8D,$FF,$21,$8A,$8F,$FF,$FF
LC87D:          DEFB $63,$02,$B2,$BA,$CC,$34
XC883:          DEFB $34,$6A,$5A,$52,$6A,$92,$8A,$94,$C2,$CA,$DC,$44,$44,$A2,$92,$8A
XC893:          DEFB $92,$8A,$7A,$6E,$FF,$FF
LC899:          DEFB $C0,$03,$92,$8A,$94,$34,$54,$6A,$5A,$52
XC8A3:          DEFB $6A,$92,$8A,$94,$8A,$92,$A4,$44,$64,$A2,$92,$8A,$92,$8A,$7A,$6D
XC8B3:          DEFB $FF,$FF
LC8B5:          DEFB $30,$02,$04,$36,$0E,$56,$36,$46,$1E,$64,$54,$47,$FF,$FF
LC8C3:          DEFB $33,$43,$09,$33,$FF,$08,$36,$56,$5E,$66,$6C,$0C,$04,$FF,$02,$32
XC8D3:          DEFB $37,$FF,$FF
LC8D6:          DEFB $F0,$08,$04,$96,$86,$7E,$76,$6C,$06,$FF,$41,$94,$FF
XC8E3:          DEFB $3E,$97,$FF,$FF
LC8E7:          DEFB $C0,$22,$04,$96,$86,$7E,$76,$6C,$06,$FF,$41,$6C
XC8F3:          DEFB $FF,$2E,$6F,$FF,$FF
LC8F8:          DEFB $A0,$7B,$F0,$A6,$5E,$FF,$7C,$3E,$FF,$FF
LC902:          DEFB $B8
XC903:          DEFB $7B,$C0,$A6,$5E,$FF,$7C,$3E,$FF,$52,$27,$FF,$FF
LC90F:          DEFB $C3,$FC,$02,$C0
XC913:          DEFB $A6,$5E,$FF,$FB,$44,$3E,$FF,$FF,$92

                .dephase

;; Label for end of copyable data
BankEnd:
