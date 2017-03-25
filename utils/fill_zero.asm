;;
;; fill_zero.asm
;;
;; Provides utility functions: FillZero and FillValue
;;

        ;; HL = Dest, BC = Size
FillZero:       LD      E,$00
        ;; HL = Dest, BC = Size, E = value
FillValue:      LD      (HL),E
                INC     HL
                DEC     BC
                LD      A,B
                OR      C
                JR      NZ,FillValue
                RET
