
;; Takes a pointer in HL to an index which is incremented into a byte
;; array that follows it. Next item is returned in A. Array is
;; terminated with 0, at which point we read the first item
;; again.
ReadLoop:
        ;; On to the next item.
                INC     (HL)
        ;; DE = HL + *HL
                LD      A,(HL)
                ADD     A,L
                LD      E,A
                ADC     A,H
                SUB     E
                LD      D,A
        ;; if (*DE != 0) return
                LD      A,(DE)
                AND     A
                RET     NZ
        ;; Otherwise, go back to the first item:
        ;; *HL = 1 (reset it?) and return *(HL+1)
                LD      (HL),$01
                INC     HL
                LD      A,(HL)
                RET

;; Word version of ReadLoop. Apparently unused?
ReadLoopW:      LD              A,(HL)
                INC             (HL)
        ;; DE = HL + 2 * *HL++
                ADD             A,A
                ADD             A,L
                LD              E,A
                ADC             A,H
                SUB             E
                LD              D,A
        ;; Zero index should be *after* HL, not at HL.
                INC             DE
        ;; Entry is zero? Jump to loop-to-start case.
                LD              A,(DE)
                AND             A
                JR              Z,RLW_1
        ;; Otherwise, return result in DE.
                EX              DE,HL
                LD              E,A
                INC             HL
                LD              D,(HL)
                RET
        ;; Loop-to-start: Set next time to index 1, return first entry.
RLW_1:          LD              (HL),$01
                INC             HL
                LD              E,(HL)
                INC             HL
                LD              D,(HL)
                RET

;; Build-your-own pseudo-random number generator...
Random:         LD      HL,(Rand2)
                LD      D,L
                ADD     HL,HL
                ADC     HL,HL
                LD      C,H
                LD      HL,(Rand1)
                LD      B,H
                RL      B
                LD      E,H
                RL      E
                RL      D
                ADD     HL,BC
                LD      (Rand1),HL
                LD      HL,(Rand2)
                ADC     HL,DE
                RES     7,H
                LD      (Rand2),HL
                JP      M,RND_2
                LD      HL,Rand1
RND_1:          INC     (HL)
                INC     HL
                JR      Z,RND_1
RND_2:          LD      HL,(Rand1)
                RET

Rand1:          DEFW $6F4A
Rand2:          DEFW $216E
