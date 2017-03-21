	;; 
	;; contact.asm
	;;
	;; Handles checking contact between things
	;;

ObjOnChar:	DEFW $0000        ; Pointer to an object above the character.

CAA74:		CALL	CAA7E
		LD		A,(IY+$07)
		SUB		C
		JP		DoContact
CAA7E:		LD		C,$C0
		LD		A,(SavedObjListIdx)
		AND		A
		RET		Z
		LD		IX,DoorLocsCopy
		LD		C,(IX+$00)
		LD		A,(MaxV)
		SUB		$03
		CP		A,(IY+$06)
		RET		C
		LD		C,(IX+$02)
		LD		A,(MinV)
		ADD		A,$02
		CP		A,(IY+$06)
		RET		NC
		LD		C,(IX+$01)
		LD		A,(MaxU)
		SUB		$03
		CP		A,(IY+$05)
		RET		C
		LD		C,(IX+$03)
		RET

NearHitFloor:	CP	$FF     	; This way, only get the start.
	;; NB: Fall through.

;; A is zero. We've hit, or nearly hit, the floor.
HitFloor:	SCF
		LD	(IY+$0D),A
		LD	(IY+$0E),A
		RET	NZ
        ;; Called HitFloor, not NearHitFloor.
		BIT	0,(IY+$09)
		JR	Z,FloorCheck 	; Floor check for non-player objects
        ;; Right, player has hit floor.
        ;; Some check?
		LD	A,(SavedObjListIdx)
		AND	A
		JR	NZ,RetZeroC
        ;; Then handle the possibilities
		LD	A,(FloorCode)
		CP	$06 		; Deadly floor?
		JR	Z,DeadlyFloorCase
		CP	$07 		; No floor?
		JR	NZ,RetZeroC
	;; Code to handle no floor...
        ;; TODO
		CALL	GetCharObj
		PUSH	IY
		POP	DE
		AND	A
		SBC	HL,DE
		JR	Z,HF_1
		LD	HL,SwopPressed
		LD	A,(HL)
		OR	$03
		LD	(HL),A
		JR	RetZeroC 	; Tail call.
HF_1:		LD	A,$05
		LD	(LB218),A
		AND	A
		RET

DeadlyFloorCase:LD	C,(IY+$09)
		LD	B,(IY+$04)
		CALL	DeadlyContact

	;; Return with 0 in A, and carry flag set.
RetZeroC:	XOR	A
		SCF
		RET

;; A non-player object has hit the floor...
FloorCheck:	LD	A,(FloorCode)
		CP	$07 				; No floor?
		JR	NZ,RetZeroC
		LD	(IY+$0A),OBJFN_DISAPPEAR	; Then it disappears.
		JR	RetZeroC

        ;; Object (character?) in IY.
CAB06:		LD	A,(IY+$07)
		SUB	$C0
        ;; NB: Fall through

DoContact:
        ;; Clear what's on character so far.
                LD      BC,L0000
                LD      (ObjOnChar),BC
        ;; If we've hit the floor, go to that case
                JR      Z,HitFloor
        ;; Just above floor? Still call through
                INC     A
                JR      Z,NearHitFloor
        ;; Set C to high-Z plus one (i.e. what we're resting on)
                CALL    GetUVZExtentsE
                LD      C,B
                INC     C
        ;; Looks like we use what we were on previously as our current
        ;; "on" object - avoid recomputation and keeps the object
        ;; consistent?
        ;;
        ;; Load the object charecter's on into IX. Go to ChkObjContact if null.
                EXX
                LD      A,(IY+$0E)
                AND     A
                JR      Z,ChkObjContact
                LD      H,A
                LD      L,(IY+$0D)
                PUSH    HL
                POP     IX
        ;; Various other tests where we switch over to ChkObjContact.
                BIT     7,(IX+$04)
                JR      NZ,ChkObjContact
        ;; Check we're still on it.
                LD      A,(IX+$07)
                SUB     $06
                EXX
                CP      B
                EXX
                JR      NZ,ChkObjContact
                CALL    CheckWeOverlap
                JR      NC,ChkObjContact
        ;; We're still on the object we were on before.
        ;; NB: Fall through

;; Deal with contact between a character and a thing.
;;
;; IY is the character, IX is what it's resting on.
DoObjContact:
        ;; If it's the second part of a double-height...
                BIT     1,(IX+$09)
                JR      Z,DOC_1
        ;; Reset bit 5 of Offset C
                RES     5,(IX-$06)
        ;; Load Offset B
                LD      A,(IX-$07)
                JR      DOC_2
        ;; Otherwise, do the same, but single-height.
DOC_1:          RES     5,(IX+$0C)
                LD      A,(IX+$0B)
        ;; Mask Offset C of IY with top 3 bits of Offset C of stood-on
        ;; object.
DOC_2:          OR      $E0
                LD      C,A
                LD      A,(IY+$0C)
                AND     C
                LD      (IY+$0C),A
        ;; NB: Fall through.

LAB5F:		XOR	A
		SCF
		JP	LB2BF

;; Run through all the objects in the main object list and check their
;; contact with our object in IY.
;;
;; Object extents should be in primed registers.
ChkObjContact:  LD      HL,ObjectLists + 2
COC_1:          LD      A,(HL)
                INC     HL
                LD      H,(HL)
                LD      L,A
                OR      H
                JR      Z,COC_4         ; Done - exit list.
                PUSH    HL
                POP     IX
                BIT     7,(IX+$04)
                JR      NZ,COC_1        ; Bit set? Skip this item
                LD      A,(IX+$07)      ; Check Z coord against B'
                SUB     $06
                EXX
                CP      B
                JR      NZ,COC_3        ; Go to differing height case.
                EXX
                PUSH    HL
                CALL    CheckWeOverlap
                POP     HL
                JR      NC,COC_1        ; Same height, overlap? Skip
COC_2:          LD      (IY+$0D),L      ; Record what we're sitting on.
                LD      (IY+$0E),H
                JR      DoObjContact    ; Hit!
        ;; At differing heights
COC_3:          CP      C
                EXX
                JR      NZ,COC_1        ; Differs other way? Continue.
        ;; It's on top of us, instead.
                LD      A,(ObjOnChar+1)
                AND     A
                JR      NZ,COC_1        ; Some test makes us skip...
                PUSH    HL
                CALL    CheckWeOverlap
                POP     HL
                JR      NC,COC_1        ; If we don't overlap, skip
                LD      (ObjOnChar),HL      ; Update a thing and carry on.
                JR      COC_1
        ;; Completed object list traversal
COC_4:		LD	A,(SavedObjListIdx)
		AND	A
		JR	Z,COC_7
		CALL	GetCharObjIX
		LD	A,(Character)
		CP	$03
		LD	A,$F4
		JR	Z,COC_5
		LD	A,$FA
COC_5:		ADD	A,(IX+$07)
		EXX
		CP	B
		JR	NZ,COC_6
		EXX
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,COC_7
		JR	COC_2
COC_6:		CP	C
		EXX
		JR	NZ,COC_7
		LD	A,(ObjOnChar+1)
		AND	A
		JR	NZ,COC_7
		CALL	GetCharObjIX
		CALL	CheckWeOverlap
		JR	NC,COC_7
		LD	(IY+$0D),$00
		LD	(IY+$0E),$00
		JR	COC_11
COC_7:		LD	HL,(ObjOnChar)
		LD	(IY+$0D),$00
		LD	(IY+$0E),$00
		LD	A,H
		AND	A
		RET	Z
		PUSH	HL
		POP	IX
		BIT	1,(IX+$09)
		JR	Z,COC_9
		BIT	4,(IX-$07)
		JR	COC_10
COC_9:		BIT	4,(IX+$0B)
COC_10:		JR	NZ,COC_11
		RES	4,(IY+$0C)
COC_11:		XOR	A
		SUB	$01
		RET

	;; Called by the purse routine to find something to pick up.
	;; Carry flag set if something is found, and thing returned in HL.
	;;
	;; Loop through all items, finding ones which match on B or C
	;; Then call CheckWeOverlap to see if ok candidate. Return it
	;; in HL if it is.
GetStoodUpon:	CALL	GetUVZExtentsE		; Perhaps getting height as a filter?
		LD	A,B
		ADD	A,$06
		LD	B,A
		INC	A
		LD	C,A
		EXX
	;; Traverse list of objects in main object list
		LD	HL,ObjectLists + 2
GSU_1:		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		OR	H
		RET	Z
		PUSH	HL
		POP	IX
		BIT	6,(IX+$04)
		JR	Z,GSU_1
		LD	A,(IX+$07)
		EXX
		CP	B
		JR	Z,GSU_2
		CP	C
GSU_2:		EXX
		JR	NZ,GSU_1
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,GSU_1
		RET

	;; FIXME: Looks suspiciously like we're checking contact with objects.
;; Object in IY
CAC41:
        ;; Put top of object in B'
		CALL	GetUVZExtentsE
		LD	B,C
		DEC	B
		EXX
        ;; Clear the thing on top of us
		XOR	A
		LD	(ObjOnChar),A
	;; Traverse main list of objects
		LD	HL,ObjectLists + 2
LAC4E:		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		OR	H
		JR	Z,LAC97		; Reached end?
		PUSH	HL
		POP	IX
		BIT	7,(IX+$04)
		JR	NZ,LAC4E 	; Skip if bit set
		LD	A,(IX+$07)
		EXX
		CP	C
		JR	NZ,LAC7F 	; Jump if not at same height
		EXX
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,LAC4E
        ;; Top of us = bottom of them, we have a thing on top.
        ;; Copy flag over and tail call.
LAC6D:		LD	A,(IY+$0B)
		OR	$E0
		AND	$EF
		LD	C,A
		LD	A,(IX+$0C)
		AND	C
		LD	(IX+$0C),A
		JP	LAB5F		; Tail call
        ;; Case for not at the same height...
LAC7F:		CP	B
		EXX
		JR	NZ,LAC4E
        ;; Top of us is one pixel under bottom of them.
		LD	A,(ObjOnChar)
		AND	A
		JR	NZ,LAC4E ; Return if we have an object on top already.
		PUSH	HL
		CALL	CheckWeOverlap
		POP	HL
		JR	NC,LAC4E
		LD	A,$FF
		LD	(ObjOnChar),A ; Set ObjOnChar to $FF and carry on.
		JR	LAC4E
	;; Finished traversing list
LAC97:		LD	A,(SavedObjListIdx) ; TODO: Whether other char is in same room?
		AND	A
		JR	Z,LACCC ; Some check...
		CALL	GetCharObjIX ; Hmmm. Character check.
		LD	A,(IX+$07)
		EXX
		CP	C
		JR	NZ,LACB6 ; Our top != their bottom
		EXX
		CALL	CheckWeOverlap
		JR	NC,LACCC ; Nothing on top
		JR	LAC6D    ; Thing is on top.
        
GetCharObjIX:	CALL	GetCharObj
		PUSH	HL
		POP	IX
		RET

LACB6:		CP	B
		EXX
		JR	NZ,LACCC ; Nothing on top case
		LD	A,(ObjOnChar)
		AND	A
		JR	NZ,LACCC ; Nothing on top case.
		CALL	GetCharObjIX
		CALL	CheckWeOverlap
		JR	NC,LACCC
		LD	A,$FF
		JR	LACCF
LACCC:		LD	A,(ObjOnChar)
LACCF:		AND	A       ; Rather than setting ObjOnChar, we return it?
		RET	Z
		SCF
		RET

	;; Takes object point in IX and checks to see if we overlap with it.
	;; FIXME: May assume our coordinates are in DE',HL'.
CheckWeOverlap:	CALL	GetUVExt
	;; NB: Fall through
	
	;; Assuming X and Y extents in DE,HL and DE',HL', check two boundaries overlap.
	;; Sets carry flag if they do.
CheckOverlap:
	;; Check E < D' and E' < D
		LD	A,E
		EXX
		CP	D
		LD	A,E
		EXX
		RET	NC
		CP	D
		RET	NC
	;; Check L < H' and L' < H
		LD	A,L
		EXX
		CP	H
		LD	A,L
		EXX
		RET	NC
		CP	H
		RET



;; Given an object in IX, returns its U and V extents.
;; Very like GetUVZExtents... but different?!
;;
;; D = high U, E = low U
;; H = high V, L = low V
;;
;; Values are based on the bottom 2 flag bits
;; Flag   U      V
;; 0     0 -6  +0 -6
;; 1    +0 -8  +0 -8
;; 2    +4 -4  +1 -1
;; 3    +1 -1  +4 -4
GetUVExt:
        ;; Check bit 1 of object shape.
                LD      A,(IX+$04)
                BIT     1,A
                JR      NZ,GUVE_1
        ;; Bit was reset: Case 0/1
        ;; C = 3 + bottom bit of object shape
                RRA
                LD      A,$03
                ADC     A,$00
                LD      C,A
        ;; D = U coord, E = U coord - 2 * C
                ADD     A,(IX+$05)
                LD      D,A
                SUB     C
                SUB     C
                LD      E,A
        ;; H = V coord, L = V coord - 2 * C
                LD      A,C
                ADD     A,(IX+$06)
                LD      H,A
                SUB     C
                SUB     C
                LD      L,A
                RET
GUVE_1:
        ;; Jump if bottom bit set.
                RRA
                JR      C,GUVE_2
        ;; Case 2
        ;; D = U coord + 4, E = U coord - 4
                LD      A,(IX+$05)
                ADD     A,$04
                LD      D,A
                SUB     $08
                LD      E,A
        ;; L = V coord - 1, H = V coord + 1
                LD      L,(IX+$06)
                LD      H,L
                INC     H
                DEC     L
                RET
GUVE_2:
        ;; Case 3
        ;; H = V coord + 4, L = V coord - 4
                LD      A,(IX+$06)
                ADD     A,$04
                LD      H,A
                SUB     $08
                LD      L,A
        ;; D = U coord + 1, E = U coord - 1
                LD      E,(IX+$05)
                LD      D,E
                INC     D
                DEC     E
                RET

;; Swap RoomId with the room at the other end of the teleport.
Teleport:       LD      BC,(RoomId)
                LD      HL,Teleports
                CALL    FindPair
                LD      (RoomId),DE
                RET

;; Scans array from HL, looking for BC, scanning in pairs. If the
;; first is equal, it returns the second in DE. If the second is equal,
;; it returns the first.
FindPair:       CALL    CmpBCHL
                JR      Z,CmpBCHL
                PUSH    DE
                CALL    CmpBCHL
                POP     DE
                JR      NZ,FindPair
                RET

;; Loads (HL) into DE, incrementing HL. Compares BC with DE, sets Z if equal.
CmpBCHL:        LD      A,C
                LD      E,(HL)
                INC     HL
                LD      D,(HL)
                INC     HL
                CP      E
                RET     NZ
                LD      A,B
                CP      D
                RET

Teleports:      DEFW $8A40,$7150
                DEFW $8940,$0480
                DEFW $BA70,$1300
                DEFW $4100,$2980
                DEFW $A100,$2600
                DEFW $8100,$E980
                DEFW $8400,$B100
                DEFW $8500,$EF20
                DEFW $A400,$00F0
                DEFW $A500,$88D0
                DEFW $BCD0,$DED0
                DEFW $2DB0,$8BD0
                DEFW $1190,$E1C0
                DEFW $00B0,$E2C0
                DEFW $10B0,$C100
                DEFW $8BF0,$00F0
                DEFW $9730,$EF20
                DEFW $1D00,$A800
                DEFW $BA70,$4E00
                DEFW $8800,$1B30
                DEFW $4C00,$3930
                DEFW $8B30,$8D30
