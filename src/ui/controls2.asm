;;
;; controls2.asm
;;
;; Controls-reading functions used from the main game loop.
;;

;; Exported functions:
;; * GetInputCtrls
;; * IsHPressed

;; Return in A a bit mask of currently pressed controls (pressed = low).
GetInputCtrls:  JP      GIC_Kbd         ; If joystick used, this is rewritten as 'CALL'.
                RLCA
                RLCA
                RLCA
                EX      AF,AF'
GIC_Joy:        CALL    Kempston        ; Rewritten with the appropriate joystick call.
                LD      B,0
                LD      E,A
                JR      GIC_2           ; Then feed the joystick moves through the lookup, too.
GIC_Kbd:        LD      B,$FE           ; Port 254 for keyboard
                LD      A,$FF
                LD      HL,KeyMap
        ;; Do one half-row at a time, B from $FE to $7F (one bit low at a time)
GIC_1:          EX      AF,AF'
                LD      C,$FE
                IN      E,(C)
GIC_2:          LD      C,$08           ; We'll loop 8 times, to build a bit-mask
GIC_3:          LD      A,(HL)
                OR      E
                OR      $E0
                CP      $FF             ; Carry if there's a bit low in read value and (HL)
                CCF
                RL      D               ; Which becomes a bit set in D.
                INC     HL
                DEC     C
                JR      NZ,GIC_3        ; And loop, for 8 control bits.
                EX      AF,AF'
                AND     D               ; And in the extra bits...
                RLC     B
                JR      C,GIC_1         ; then do the next half-row
        ;; Bits are currently set as in the order in controls menu, so...
                RRCA
                RRCA
                RRCA
        ;; Now: (MSB) Carry Fire Swop Left Right Down Up Jump (LSB)
                RET

;; Checks to see if the button 'H' is pressed. Returns NZ if it is.
IsHPressed:     LD      A,$BF
                IN      A,($FE)
                AND     $10
                RET
