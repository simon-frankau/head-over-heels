
;; Given a direction bitmask in A, return a direction code.
LookupDir:      AND     $0F
                ADD     A,DirTable & $FF
                LD      L,A
                ADC     A,DirTable >> 8
                SUB     L
                LD      H,A
                LD      A,(HL)
                RET

;; Input into this look-up table is the 4-bit bitmask:
;; Left Right Down Up.
;;
;; Bits are low if direction is pressed.
;;
;; Combinations are mapped to the following directions:
;;
;; $05 $04 $03
;; $06 $FF $02
;; $07 $00 $01
;;
DirTable:       DEFB $FF,$00,$04,$FF,$06,$07,$05,$06
                DEFB $02,$01,$03,$02,$FF,$00,$04,$FF

;; A has a direction, returns Y delta in C, X delta in B, and
;; third entry is the DirTable inverse mapping.
DirDeltas:      LD              L,A
                ADD             A,A
                ADD             A,L
                ADD             A,DirTable2 & $FF
                LD              L,A
                ADC             A,DirTable2 >> 8
                SUB             L
                LD              H,A
                LD              C,(HL)
                INC             HL
                LD              B,(HL)
                INC             HL
                LD              A,(HL)
                RET

        ;; First byte is Y delta, second X, third is reverse lookup?
DirTable2:      DEFB $FF,$00,$0D        ; ~F2
                DEFB $FF,$FF,$09        ; ~F6
                DEFB $00,$FF,$0B        ; ~F4
                DEFB $01,$FF,$0A        ; ~F5
                DEFB $01,$00,$0E        ; ~F1
                DEFB $01,$01,$06        ; ~F9
                DEFB $00,$01,$07        ; ~F8
                DEFB $FF,$01,$05        ; ~FA

UpdateCurrPos:  LD	HL,(CurrObject)
        ;; Fall through

        ;; Takes direction in A.
UpdatePos:      PUSH    HL
                CALL    DirDeltas
        ;; Store the bottom 4 bits of A (dir bitmap) in Object + $0B
                LD      DE,$0B
                POP     HL
                ADD     HL,DE
                XOR     (HL)
                AND     $0F
                XOR     (HL)
                LD      (HL),A
        ;; Update U coordinate with Y delta.
                LD      DE,-$06
                ADD     HL,DE
                LD      A,(HL)
                ADD     A,C
                LD      (HL),A
        ;; Update V coordinate with X delta.
                INC     HL
                LD      A,(HL)
                ADD     A,B
                LD      (HL),A
                RET
