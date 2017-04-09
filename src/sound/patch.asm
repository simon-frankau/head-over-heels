;;
;; patch.asm
;;
;; Do 128K patch if necessary, and shuffle some memory down.
;;

	;; Called immediately after installing interrupt handler.
ShuffleMem:	; Zero end of top page
		LD	HL,$FFFE
		XOR	A
		LD	(HL),A
		; Switch to bank 1, write top of page
		LD	BC,$7FFD ; TODO
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
		LD	HL,ATTR_START
ShuffleMem_1:	LD	(HL),$00
		INC	L
		JR	NZ,ShuffleMem_1
		INC	H
		DJNZ	ShuffleMem_1
		; Stash data in display memory
		LD	BC,BankEnd - BankStart - 1 ; TODO: -1?
		LD	DE,$4000
		LD	HL,BankStart
		LDIR
		; Switch to bank 1
		LD	A,$11
		LD	BC,$7FFD ; TODO
		OUT	(C),A
		; Reinitialise IRQ handler there.
		LD	A,$18
		LD	($FFFF),A
		LD	A,$C3
		LD	($FFF4),A
		LD	HL,IrqHandler
		LD	($FFF5),HL
		; FIXME: Another memory chunk copy.
		LD	BC,SoundPatchEnd - SoundPatchStart ; TODO
		LD	DE,AltPlaySound
		LD	HL,SoundPatchStart ; TODO
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
		LD	BC,BankEnd - BankStart - 1 ; TODO: - 1?
		LD	DE,BankDest
		LD	HL,$4000
		LDIR
		; Switch to bank 0.
		LD	BC,$7FFD
		LD	A,$10
		OUT	(C),A
Have48K:	; Move the data end of things down by 360 bytes...
		LD	HL,MoveDownStart
		LD	DE,MoveDownStart - MAGIC_OFFSET
		LD	BC,MoveDownEnd - MoveDownStart
		LDIR
		RET

;; NB: These are 128K-specific patch functions applied over the
;; 48K sound-playing code.
SoundPatchStart:

        ;; Patches AltPlaySound
AltPlaySound128:LD	A,(Snd2)
		CP	$80
		RET	Z
		LD	B,$C3
		JP	PlaySound

        ;; Patches IrqFn
IrqFn128:       LD      A,$11
                LD      BC,$7FFD
                OUT     (C),A
                PUSH    BC
                CALL    Irq128
                POP     BC
                LD      A,$10
                OUT     (C),A
                RET

        ;; TODO: Gap to ensure this matches up with 48K version.
                DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00

        ;; Patches PlaySound
PlaySound128:   LD      D,B
                LD      BC,$7FFD
                LD      A,$11
                DI
                LD      ($9667),A
                OUT     (C),A
                EI
                PUSH    BC
                LD      B,D
                CALL    Play128
                POP     BC
                LD      A,$10
                DI
                LD      ($9667),A
                OUT     (C),A
                EI
                RET

SoundPatchEnd: