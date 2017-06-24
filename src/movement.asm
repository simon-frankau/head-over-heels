	;;
	;; movement.asm
	;;
	;; Performs movement in a direction.
	;;
	;; Only exported value is MoveTbl
	;; Only call out is to DoMove... which calls right back!

	;; Variables used in this file:
	;; MinU
	;; MinV
	;; MaxU
	;; MaxV
	;; DoorHeights
	;; Movement
	;; NextRoom

;; MoveTbl is indexed on a direction, as per LookupDir.
;; First element is bit mask for directions.
;; Second is the function to move that direction.
;; Third element is the function to check collisions.
MoveTbl:        DEFB ~$02
                DEFW Down,DownCollide
                DEFB ~$00
                DEFW DownRight,0
                DEFB ~$04
                DEFW Right,RightCollide
                DEFB ~$00
                DEFW UpRight,0
                DEFB ~$01
                DEFW Up,UpCollide
                DEFB ~$00
                DEFW UpLeft,0
                DEFB ~$08
                DEFW Left,LeftCollide
                DEFB ~$00
                DEFW DownLeft,0

;; The diagonal movement functions rearrange things:
;; * They remove two elements of the stack, removing the call to
;;   PostMove and the return into DoMove (which puts (Direction)
;;   into A).
;; * They call DoMove, and check the resultant carry flag. Carry means
;;   failure to move in that direction. They move one direction, then the
;;   other.
;; * If the first move succeeds, the extents are updated to represent the
;;   successful move, before the second check is attempted.
;; * Depending on what works, they generate a movement direction in A,
;;   and success/failure in the carry flag.
DownRight:      EXX
        ;; Remove original return path, hit DoMove again.
                POP     HL
                POP     DE
        ;; Call Down
                XOR     A
                CALL    DoMove
                JR      C,DR_1
        ;; Update extents in DE
                EXX
                DEC     D
                DEC     E
                EXX
        ;; Call Right
                LD      A,$02
                CALL    DoMove
                LD      A,$01
                RET     NC
                XOR     A
                RET
        ;; Call Right
DR_1:           LD      A,$02
                CALL    DoMove
                RET     C
                AND     A
                LD      A,$02
                RET

UpRight:        EXX
        ;; Remove original return path, hit DoMove again.
                POP     HL
                POP     DE
        ;; Call Up
                LD      A,$04
                CALL    DoMove
                JR      C,UR_1
        ;; Update extents in DE
                EXX
                INC     D
                INC     E
                EXX
        ;; Call Right
                LD      A,$02
                CALL    DoMove
                LD      A,$03
                RET     NC
                LD      A,$04
                AND     A
                RET
        ;; Call Right
UR_1:           LD      A,$02
                CALL    DoMove
                RET     C
                AND     A
                LD      A,$02
                RET

UpLeft:         EXX
        ;; Remove original return path, hit DoMove again.
                POP     HL
                POP     DE
        ;; Call Up
                LD      A,$04
                CALL    DoMove
                JR      C,UL_1
        ;; Update extents in DE
                EXX
                INC     D
                INC     E
                EXX
        ;; Call Left
                LD      A,$06
                CALL    DoMove
                LD      A,$05
                RET     NC
                LD      A,$04
                AND     A
                RET
        ;; Call Left
UL_1:           LD      A,$06
                CALL    DoMove
                RET     C
                LD      A,$06
                RET

DownLeft:       EXX
        ;; Remove original return path, hit DoMove again.
                POP     HL
                POP     DE
        ;; Call Down
                XOR     A
                CALL    DoMove
                JR      C,DL_1
        ;; Update extents in DE
                EXX
                DEC     D
                DEC     E
                EXX
        ;; Call Left
                LD      A,$06
                CALL    DoMove
                LD      A,$07
                RET     NC
                XOR     A
                RET
        ;; Call Left
DL_1:           LD      A,$06
                CALL    DoMove
                RET     C
                AND     A
                LD      A,$06
                RET

;; *Collide functions take an object in HL, and check it against the
;; character whose extents are in DE' and HL'
;;
;; Returned flags are:
;;  Carry = Collided
;;  NZ = No collision, but further collisions are possible.
;;  Z = Stop now, no further collisions possible.

UpCollide:      INC     HL
                INC     HL
                CALL    GetSimpleSize
        ;; Check U coordinate
                LD      A,(HL)
                SUB     C
                EXX
                CP      D
                EXX
                JR      C,CollideContinue ; Too far? Skip.
                JR      NZ,ChkBack        ; Are we done yet?
        ;; U coordinate matches.
                INC     HL
        ;; NB: Fall through

;; U coordinate matches. Check V overlaps.
ChkVCollide:    LD      A,(HL)
                SUB     B
                EXX
                CP      H
                LD      A,L
                EXX
                JR      NC,CollideContinue
                SUB     B
                CP      (HL)
                JR      NC,CollideContinue
        ;; If we reached here, there's a V overlap.
        ;; NB: Fall through

ChkZCollide:    INC     HL
                EXX
                LD      A,C
                EXX
                CP      (HL)
                JR      NC,CollideContinue
                LD      A,(HL)
                SUB     E
                EXX
                CP      B
                EXX
                JR      NC,CollideContinue
        ;; If we reached here, there's a Z overlap.
                SCF             ; Collision!
                RET

ChkBack:
        ;; Check V coordinate
                INC     HL
                LD      A,(HL)
                SUB     B
                EXX
                CP      H
                EXX
                JR      C,CollideContinue
        ;; Check Z coordinate
                INC     HL
                LD      A,(HL)
                SUB     E
                EXX
                CP      B
                EXX
                JR      C,CollideContinue
        ;; Passed our object, can stop now.
                XOR     A
                RET

;; No carry = no collision, non-zero = keep searching.
CollideContinue:LD      A,$FF
                AND     A
                RET

LeftCollide:    INC     HL
                INC     HL
                CALL    GetSimpleSize
        ;; Check U coordinates overlap...
                LD      A,(HL)
                SUB     C
                EXX
                CP      D
                LD      A,E
                EXX
                JR      NC,ChkBack
                SUB     C
                CP      (HL)
                JR      NC,CollideContinue
        ;; U overlaps, check V for contact.
                INC     HL
                LD      A,(HL)
                SUB     B
                EXX
                CP      H
                EXX
                JR      Z,ChkZCollide   ; U and V match.
                JR      CollideContinue ; Not a collision.

DownCollide:    CALL    GetSimpleSize
        ;; Check U coordinate.
                EXX
                LD      A,E
                EXX
                SUB     C
                CP      (HL)
                JR      C,CollideContinue ; Past it? Skip
                INC     HL
                JR      Z,ChkVCollide     ; Are we done yet?
        ;; U coordinate matches.
        ;; NB: Fall through

ChkFront:
        ;; Check U coordinate.
                EXX
                LD      A,L
                EXX
                SUB     B
                CP      (HL)
                JR      C,CollideContinue
        ;; Check Z coordinate.
                INC     HL
                LD      A,(HL)
                ADD     A,E
                EXX
                CP      B
                EXX
                JR      NC,CollideContinue
        ;; Passed our object, can stop now.
                XOR     A
                RET

RightCollide:   CALL    GetSimpleSize
        ;; Check U coordinate overlap...
                EXX
                LD      A,E
                EXX
                SUB     C
                CP      (HL)
                INC     HL
                JR      NC,ChkFront
                DEC     HL
                LD      A,(HL)
                SUB     C
                EXX
                CP      D
                LD      A,L
                EXX
                JR      NC,CollideContinue
        ;; U overlaps, checks V for contact.
                INC     HL
                SUB     B
                CP      (HL)
                JP      Z,ChkZCollide   ; U and V match.
                JR      CollideContinue ; Not a collision.

;; Up, Down, Left and Right
;;
;; Takes U extent in DE, V extent in HL.
;; U/D work in U direction, L/R work in V direction.
;;
;; Sets NZ and C if you can move in a direction.
;; Sets Z and C if you cannot.
;; Leaving room sets direction in NextRoom, sets C and Z.

Down:           CALL    ChkCantLeave
                JR      Z,D_NoExit
        ;; Inside the door frame to the side? Check a limited extent, then.
                CALL    UD_InOtherDoor
                LD      A,DOOR_LOW
                JR      C,D_NoExit2
        ;; If the wall has a door, and
        ;; we're the right height to fit through, and
        ;; we're lined up to go through the frame,
        ;; set 'A' to be the far side of the door.
                BIT     0,(IX-$01) ; HasDoor
                JR      Z,D_NoDoor
                LD      A,(DoorHeights + 3)
                CALL    DoorHeightCheck
                JR      C,D_NoExit
                CALL    UD_InFrame
                JR      C,D_NearDoor
                LD      A,(MinU)
                SUB     $04
                JR      D_Exit
        ;; If there's no wall, put the room end coordinate into 'A'...
D_NoDoor:       BIT     0,(IX-$02) ; HasNoWall
                JR      Z,D_NoExit
                LD      A,(MinU)
        ;; Case where we can exit the room.
D_Exit:         CP      E
                RET     NZ
                LD      A,$01
        ;; NB: Fall through.

LeaveRoom:      LD      (NextRoom),A
                SCF
                RET

        ;; The case where we can't exit the room, but may hit the
        ;; wall.
D_NoExit:       LD      A,(MinU)
        ;; (or some other value given in A).
D_NoExit2:      CP      E
                RET     NZ
                SCF
                RET

        ;; Handle the near-door case: If we're not near the door frame,
        ;; we do the normal "not door" case. Otherwise, we do that and
        ;; then nudge into the door.
D_NearDoor:     CALL    UD_InFrameW
                JR      C,D_NoExit
                CALL    D_NoExit
        ;; NB: Fall through

        ;; Choose a direction to move based on which side of the door
        ;; we're trying to get through.
UD_Nudge:       RET     NZ
                LD      A,L
                CP      DOOR_LOW + 1
                LD      A,~$08
                JR      C,Nudge
                LD      A,~$04
        ;; NB: Fall through

        ;; Update the direction with they way to go to get through the door.
Nudge:          LD      (Movement),A
                XOR     A
                SCF
                RET

Right:          CALL    ChkCantLeave
                JR      Z,R_NoExit
        ;; Inside the door frame to the side? Check a limited extent, then.
                CALL    LR_InOtherDoor
                LD      A,DOOR_LOW
                JR      C,R_NoExit2
        ;; If the wall has a door, and
        ;; we're the right height to fit through, and
        ;; we're lined up to go through the frame,
        ;; set 'A' to be the far side of the door.
                BIT     1,(IX-$01) ; HasDoor
                JR      Z,R_NoDoor
                LD      A,(DoorHeights + 2)
                CALL    DoorHeightCheck
                JR      C,R_NoExit
                CALL    LR_InFrame
                JR      C,R_NearDoor
                LD      A,(MinV)
                SUB     $04
                JR      R_Exit
        ;; If there's no wall, put the room end coordinate into 'A'...
R_NoDoor:       BIT     1,(IX-$02) ; HasNoWall
                JR      Z,R_NoExit
                LD      A,(MinV)
        ;; Case where we can exit the room.
R_Exit:         CP      L
                RET     NZ
                LD      A,$02
                JR      LeaveRoom

        ;; The case where we can't exit the room, but may hit the
        ;; wall.
R_NoExit:       LD      A,(MinV)
        ;; (or some other value given in A).
R_NoExit2:      CP      L
                RET     NZ
                SCF
                RET

        ;; The case where we can't exit the room, but may hit the
        ;; wall.
R_NearDoor:     CALL    LR_InFrameW
                JR      C,R_NoExit
                CALL    R_NoExit
        ;; NB: Fall through

        ;; Choose a direction to move based on which side of the door
        ;; we're trying to get through.
LR_Nudge:       RET     NZ
                LD      A,E
                CP      $25
                LD      A,$FE
                JR      C,Nudge
                LD      A,$FD
                JR      Nudge

Up:             CALL    ChkCantLeave
                JR      Z,U_NoExit
        ;; Inside the door frame to the side? Check a limited extent, then.
                CALL    UD_InOtherDoor
                LD      A,DOOR_HIGH
                JR      C,U_NoExit2
        ;; If the wall has a door, and
        ;; we're the right height to fit through, and
        ;; we're lined up to go through the frame,
        ;; set 'A' to be the far side of the door.
                BIT     2,(IX-$01) ; HasDoor
                JR      Z,U_NoDoor
                LD      A,(DoorHeights + 1)
                CALL    DoorHeightCheck
                JR      C,U_NoExit
                CALL    UD_InFrame
                JR      C,U_NearDoor
                LD      A,(MaxU)
                ADD     A,$04
                JR      U_Exit
        ;; If there's no wall, put the room end coordinate into 'A'...
U_NoDoor:       BIT     2,(IX-$02) ; HasNoWall
                JR      Z,U_NoExit
                LD      A,(MaxU)
        ;; Case where we can exit the room.
U_Exit:         CP      D
                RET     NZ
                LD      A,$03
                JP      LeaveRoom

        ;; The case where we can't exit the room, but may hit the
        ;; wall.
U_NoExit:       LD      A,(MaxU)
        ;; (or some other value given in A).
U_NoExit2:      CP      D
                RET     NZ
                SCF
                RET

        ;; Handle the near-door case: If we're not near the door frame,
        ;; we do the normal "not door" case. Otherwise, we do that and
        ;; then nudge into the door.
U_NearDoor:     CALL    UD_InFrameW
                JR      C,U_NoExit
                CALL    U_NoExit
                JP      UD_Nudge

Left:           CALL    ChkCantLeave
                JR      Z,L_NoExit
        ;; Inside the door frame to the side? Check a limited extent, then.
                CALL    LR_InOtherDoor
                LD      A,DOOR_HIGH
                JR      C,L_NoExit2
        ;; If the wall has a door, and
        ;; we're the right height to fit through, and
        ;; we're lined up to go through the frame,
        ;; set 'A' to be the far side of the door.
                BIT     3,(IX-$01) ; HasDoor
                JR      Z,L_NoDoor
                LD      A,(DoorHeights)
                CALL    DoorHeightCheck
                JR      C,L_NoExit
                CALL    LR_InFrame
                JR      C,L_NearDoor
                LD      A,(MaxV)
                ADD     A,$04
                JR      L_Exit
        ;; If there's no wall, put the room end coordinate into 'A'...
L_NoDoor:       BIT     3,(IX-$02) ; HasNoWall
                JR      Z,L_NoExit
                LD      A,(MaxV)

        ;; Case where we can exit the room.
L_Exit:         CP      H
                RET     NZ
                LD      A,$04
                JP      LeaveRoom

        ;; The case where we can't exit the room, but may hit the
        ;; wall.
L_NoExit:       LD      A,(MaxV)
        ;; (or some other value given in A).
L_NoExit2:      CP      H
                RET     NZ
                SCF
                RET

        ;; Handle the near-door case: If we're not near the door frame,
        ;; we do the normal "not door" case. Otherwise, we do that and
        ;; then nudge into the door.
L_NearDoor:     CALL    LR_InFrameW
                JR      C,L_NoExit
                CALL    L_NoExit
                JP      LR_Nudge

;; If we're not inside the V extent, we must be in the doorframes to
;; the side. Set C if this is the case.
UD_InOtherDoor: LD      A,(MaxV)
                CP      H
                RET     C
                LD      A,L
                CP      A,(IX+$01) ; MinV
                RET

;; If we're not inside the U extent, we must be in the doorframes to
;; the side. Set C if this is the case.
LR_InOtherDoor: LD      A,(MaxU)
                CP      D
                RET     C
                LD      A,E
                CP      A,(IX+$00) ; MinU
                RET

;; Return NC if within the interval associated with the door.
;; Specifically, returns NC if D <= DOOR_HIGH and E >= DOOR_LOW
LR_InFrame:     LD      A,DOOR_HIGH
                CP      D
                RET     C
                LD      A,E
                CP      DOOR_LOW
                RET

;; Same, but for the whole door, not just the inner arch
LR_InFrameW:    LD      A,DOOR_HIGH + 4
                CP      D
                RET     C
                LD      A,E
                CP      DOOR_LOW - 4
                RET

;; Return NC if within the interval associated with the door.
;; Specifically, returns NC if H <= DOOR_HIGH and L >= DOOR_LOW
UD_InFrame:     LD      A,DOOR_HIGH
                CP      H
                RET     C
                LD      A,L
                CP      DOOR_LOW
                RET

;; Same, but for the whole door, not just the inner arch
UD_InFrameW:    LD      A,DOOR_HIGH + 4
                CP      H
                RET     C
                LD      A,L
                CP      DOOR_LOW - 4
                RET

;; Door height check.
;;
;; Checks to see if the character Z coord (in A) is between B
;; and either B + 3 or B + 9 (depending on if you're both head
;; and heels currently). Returns NC if the character is in the right
;; height range to go through door.
DoorHeightCheck:SUB     B
                RET     C
                PUSH    AF
                LD      A,(Character)
                CP      $03
                JR      NZ,DHC_1
                POP     AF
                CP      $03
                CCF
                RET
DHC_1:          POP     AF
                CP      $09
                CCF
                RET

;; Points IX at the room boundaries, sets zero flag (can't leave room) if:
;; Bit 0 of IY+09 is not zero, or bottom 7 bits of IY+0A are not zero.
;;
;; Assumes IY points at the object.
;; Returns with zero flag set if it can't leave the room.
;; Also points IX at the room boundaries.
;;
;; TODO: Can't leave room if it's a not a player, or the object
;; function is zero'd.
ChkCantLeave:   LD      IX,MinU
                BIT     0,(IY+$09)      ; Low bit of sprite flag (TODO: Is player?)
                RET     Z               ; If it's zero, can't leave room.
                LD      A,(IY+$0A)      ; Check the object function...
                AND     $7F
                SUB     $01
                RET     C               ; If fn is 0, zero not set, can leave
                XOR     A
                RET                     ; in other cases, can.

;; HL points to the object to check + 2.
;; Assumes flags are in range 0-3.
;; Returns fixed height of 6 in E.
;; Returns V extent in B, U extent in C.
;; Leaves HL pointing at the U coordinate.
GetSimpleSize:  INC     HL
                INC     HL
                LD      A,(HL)          ; Load flags into A.
                INC     HL
                LD      E,$06           ; Fixed height of 6.
                BIT     1,A
                JR      NZ,GSS_1
        ;; Cases 0, 1:
                RRA
                LD      A,$03
                ADC     A,$00
                LD      B,A
                LD      C,A
                RET                     ; Either 3x3 or 4x4.
        ;; Cases 2, 3:
GSS_1:          RRA
                JR      C,GSS_2
        ;; Case 2:
                LD      BC,$0104
                RET                     ; 1x4
        ;; Case 3:
GSS_2:          LD      BC,$0401        ; 4x1
                RET
