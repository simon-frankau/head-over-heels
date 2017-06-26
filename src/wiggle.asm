
WiggleState:    DEFB $00
WiggleCounter:  DEFB $40

        ;; Start on 5th row of SPR_HEAD2
HEAD_OFFSET:    EQU (7 * 48 + 4) * 3 + 1

WiggleEyebrows:
        ;; Toggle top bit of WiggleState.
                LD      HL,WiggleState
                LD      A,$80
                XOR     (HL)
                LD      (HL),A
        ;; Check bit 0 of $C043 for source choice.
                LD      A,($C043) ; TODO
                BIT     0,A
        ;; Set up destination
                LD      HL,IMG_3x24 - MAGIC_OFFSET + HEAD_OFFSET
                LD      DE,XORs + 12 ; Reset means second image
                JR      Z,WE_1
                DEC     HL
                LD      DE,XORs ; Set means first image, dest 1 byte less.
        ;; Run XORify twice, at HL, and HL+0x48 (the other part of SPR_HEAD2).
WE_1:           PUSH    DE
                PUSH    HL
                CALL    XORify
                LD      DE,$48
                POP     HL
                ADD     HL,DE
                POP     DE
        ;; NB: Fall through

;; Source DE, dest HL, xor 2 bytes of 3 in, 6 times.
;; Used to XOR over 2 of three columns of a 3x24 sprite.
XORify:         LD      C,$06
        ;; C times, repeat the loop below, then HL++.
XOR_1:          LD      B,$02
        ;; XOR (DE++) over (HL++), B times.
XOR_2:          LD      A,(DE)
                XOR     (HL)
                LD      (HL),A
                INC     DE
                INC     HL
                DJNZ    XOR_2
                INC     HL
                DEC     C
                JR      NZ,XOR_1
                RET

        ;; Two images, of bits to flip to wiggle eyebrows, one facing
        ;; left, one right.
XORs:
#insert "../bin/img_2x6.bin"
