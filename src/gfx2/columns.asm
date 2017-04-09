;;
;; columns.asm
;;
;; Draws a column of ColHeight into ColBuf.
;;

;; In multiples of 6, for object-sized steps.
ColHeight:      DEFB $00

;; Re-fills the column sprite buffer. Preserves registers.
FillColBuf:     PUSH    DE
                PUSH    BC
                PUSH    HL
                LD      A,(ColHeight)
                CALL    DrawColBuf
                POP     HL
                POP     BC
                POP     DE
                RET

;; Given a column height in A, redraws the column in ColBuf, returns
;; result in DE.
SetColHeight:   LD      (ColHeight),A
        ;; NB: Fall through!

DrawColBuf:     PUSH    AF
        ;; Clear out buffer
                LD      HL,ColBuf
                LD      BC,ColBufLen
                CALL    FillZero
        ;; Drawing buffer, reset flip flag.
                XOR     A
                LD      (IsColBufFlipped),A
        ;; And set the 'filled' flag.
                DEC     A
                LD      (IsColBufFilled),A
                POP     AF
        ;; Zero height? Draw nothing
                AND     A
                RET     Z
        ;; Otherwise, draw in reverse from end of buffer...
                LD      DE,ColBuf + ColBufLen - 1
                PUSH    AF
                CALL    DrawColBottom
DrawColLoop:    POP     AF
                SUB     $06
                JR      Z,DrawColTop
                PUSH    AF
                CALL    DrawColMid
                JR      DrawColLoop

DrawColTop:     LD      HL,IMG_ColTop + 4 * 9 - 1 - MAGIC_OFFSET
                LD      BC, 4 * 9
                JR      DrawColLDDR

DrawColMid:     LD      HL,IMG_ColMid + 4 * 6 - 1 - MAGIC_OFFSET
                LD      BC, 4 * 6
                JR      DrawColLDDR

DrawColBottom:  LD      HL,IMG_ColBottom + 4 * 4 - 1 - MAGIC_OFFSET
                LD      BC, 4 * 4

DrawColLDDR:    LDDR
                RET
