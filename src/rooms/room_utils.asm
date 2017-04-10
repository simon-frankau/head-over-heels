;;
;; room_utils.asm
;;
;; A couple of utility functions for loading room state
;;

;; Fetch bit-packed data.
;; Expects number of bits in B.

;; End marker is the set bit rotated in from carry: The
;; current byte is all read when only that bit remains.
FetchData:      LD      DE,CurrData
                LD      A,(DE)
                LD      HL,(DataPtr)
                LD      C,A
                XOR     A
FD_1:           RL      C
                JR      Z,FD_3
FD_2:           RLA
                DJNZ    FD_1
                EX      DE,HL
                LD      (HL),C
                RET
        ;; Next character case: Load/initially rotate the new
        ;; character, and jump back.
FD_3:           INC     HL
                LD      (DataPtr),HL
                LD      C,(HL)
                SCF
                RL      C
                JP      FD_2

;; Configure the walls for the current room
DoConfigWalls:
        ;; Get the heights of the doors on the back walls.
                LD      HL,(DoorHeightsTmp)
        ;; Take the smaller of H and L - the higher door.
                LD      A,L
                CP      H
                JR      C,CBW_1
                LD      A,H
        ;; Take it away from C0, to convert to a height above ground...
CBW_1:          NEG
                ADD     A,$C0
        ;; Increase HighestDoor if it's a value less than A.
                LD      HL,HighestDoor
                CP      (HL)
                JR      C,CBW_2
                LD      (HL),A
        ;; Get door height into A and tail call ConfigWalls
CBW_2:          LD      A,(HL)
                JP      ConfigWalls     ; NB: Tail call.
