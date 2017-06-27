;;
;; patch.asm
;;
;; Do 128K patch if necessary, and shuffle some memory down.
;;

;; Called immediately after installing interrupt handler.
ShuffleMem:
        ;; First, let's check if we're running on a 128K:
                ; Zero end of top page
                LD      HL,$FFFE
                XOR     A
                LD      (HL),A
                ; Switch to bank 1, write top of page
                LD      BC,$7FFD
                LD      D,$10
                LD      E,$11
                OUT     (C),E
                LD      (HL),$FF
                ; Switch back, see if original overwritten...
                OUT     (C),D
                CP      (HL)
                JR      NZ,MoveMem
                ; Ok, we're 128K. We want to copy the sound code into another
                ; bank and wire up the handlers.
                ;
                ; First, zero screen attributes, so no-one can see
                ; we're using it as temp space...
                LD      B,$03
                LD      HL,ATTR_START
ShuffleMem_1:   LD      (HL),$00
                INC     L
                JR      NZ,ShuffleMem_1
                INC     H
                DJNZ    ShuffleMem_1
                ; Stash data in display memory
                LD      BC,BankEnd - BankStart - 1
                LD      DE,$4000
                LD      HL,BankStart
                LDIR
                ; Switch to bank 1 (at address $C000).
                LD      A,$11
                LD      BC,$7FFD
                OUT     (C),A
                ; Reinitialise IRQ handler there.
                LD      A,$18
                LD      ($FFFF),A
                LD      A,$C3
                LD      ($FFF4),A
                LD      HL,IrqHandler
                LD      ($FFF5),HL
                ; Overwrite the 48K sound handler with the 128K one.
                LD      BC,SoundPatchEnd - SoundPatchStart
                LD      DE,PlayTune
                LD      HL,SoundPatchStart
                LDIR
                ; We write a page of $FFs over the 48K sound handler,
                ; and repoint our interrupt vector there. So, on 128K
                ; machines, we don't need to rely on a page of the ROM
                ; being $FFs.
                DEC     DE
                LD      E,$00
                INC     D
                LD      A,D
                LD      I,A
                LD      A,$FF
ShuffleMem_2:   LD      (DE),A
                INC     E
                JR      NZ,ShuffleMem_2
                INC     D
                LD      (DE),A
                ; We unstash the 128K sound code from display mem to the bank.
                LD      BC,BankEnd - BankStart - 1
                LD      DE,BankDest
                LD      HL,$4000
                LDIR
                ; Switch back to bank 0.
                LD      BC,$7FFD
                LD      A,$10
                OUT     (C),A
MoveMem:        ; New that we're done with the 128K music code, we
                ; move the data above it down by 360 bytes, to create
                ; some room for temporary data and buffers.
                LD      HL,MoveDownStart
                LD      DE,MoveDownStart - MAGIC_OFFSET
                LD      BC,MoveDownEnd - MoveDownStart
                LDIR
                RET

;; NB: These are 128K-specific patch functions applied over the
;; 48K sound-playing code.
SoundPatchStart:

                .phase PlayTune

        ;; Patches PlayTune
PlayTune128:    LD      A,(IntSnd)
                CP      $80
                RET     Z
                LD      B,$C3
                JP      PlaySound

        ;; Patches IrqFn
IrqFn128:       LD      A,$11
                LD      BC,$7FFD
                OUT     (C),A           ; Switch bank.
                PUSH    BC
                CALL    Irq128          ; Call the routine.
                POP     BC
RestBank:       LD      A,$10           ; Self-modifying code!
                OUT     (C),A           ; Restore original bank.
                RET

        ;; Make sure that PlaySound128 lines up with PlaySound.
PS_Gap:         DEFS PlaySound - PS_Gap, $00

        ;; Patches PlaySound. Rather like the IrqFn patch with its
        ;; bank-switching, but it patches IrqFn to not bank back should
        ;; an interrupt happen while the routine's running.
PlaySound128:   LD      D,B
                LD      BC,$7FFD
                LD      A,$11
                DI
                LD      (RestBank + 1),A
                OUT     (C),A
                EI
                PUSH    BC
                LD      B,D
                CALL    Play128
                POP     BC
                LD      A,$10
                DI
                LD      (RestBank + 1),A
                OUT     (C),A
                EI
                RET

                .dephase

SoundPatchEnd:

;; This looks like unreferenced patch code. Perhaps an earlier
;; iteration of moving things around?
XB867:
                DI
                LD      HL,$BDD3
                LD      DE,$4000
                LD      BC,$0005
                LDIR
                LD      DE,$5B00 ; Straight after end of screen.
                LD      BC,$A500
                LD      HL,$6054
                JP      $4000

;; I suspect the reference to $BDD3 above originally intended to point
;; at this?
XB87F:          LDIR
                JP      $7030
