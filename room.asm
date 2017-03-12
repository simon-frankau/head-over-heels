;;
;; room.asm
;;
;; Functions that largely decode the packed room data
;;

;; Exported functions:
;;  * BuildRoom
;;  * ReadRoom
;;  * SetTmpObjUVZ
;;  * SetUVZ
;;  * AddObjOpt
;;  * HasFloorAbove

        ;; Pointer into stack for current origin coordinates
DecodeOrgPtr:   DEFW DecodeOrgStack
        ;; Each stack entry contains UVZ coordinates
DecodeOrgStack: DEFB $00, $00, $00
                DEFB $00, $00, $00
                DEFB $00, $00, $00
                DEFB $00, $00, $00
L76EC:	DEFB $00
L76ED:	DEFB $00

        ;; Buffer for an object used during unpacking
TmpObj:	DEFB $00,$00,$00,$00,$00,$00,$00,$00
	DEFB $00,$00,$00,$FF,$FF,$00,$00,$00
        DEFB $00,$00

UnpackFlags:	DEFB $00

	;; Current pointer to bit-packed data
DataPtr:	DEFW $0000
	;; The remaining bits to read at the current address.
CurrData:	DEFB $00

	;; FIXME: Decode remaining DataPtr/CurrData references...
	
ExpandDone:	DEFB $00
DoorType:	DEFB $00,$00
        ;; Flags that are used for the sprites for each half of each
	;; of the 4 doors.
DoorObjFlags:   DEFB $27, $26
                DEFB $17, $15
                DEFB $05, $04
                DEFB $36, $34

DoorwayTest:	DEFB $00
L7710:	DEFB $00
FloorCode:	DEFB $00
        ;; Set if the room above has a floor.
FloorAboveFlag:	DEFB $00
        ;; Do we skip processing the objects?
SkipObj:	DEFB $00

AttribScheme:	DEFB $00
WorldId:	DEFB $00	; Range 0..7 (I think 7 is 'same as last')
HasNoWall:	DEFB $00        ; $08 = Extra room in V direction, $04 = Extra in U dir
HasDoor:	DEFB $00
        ;; IY is pointed after to byte MaxV to access limits.
MinU:	        DEFB $00
MinV:	        DEFB $00
MaxU:	        DEFB $00
MaxV:	        DEFB $00
        ;; AltLimits is also used as IY.
AltLimits:      DEFB $00
                DEFB $00
                DEFB $00
                DEFB $00

L7720:	DEFB $00
L7721:	DEFB $00
L7722:	DEFB $00
L7723:	DEFB $00

        ;; Something that looks like extents, and looks like it's to do with doors.
DoorExts:	DEFB $08,$08,$48,$48
		DEFB $08,$10,$48,$40
		DEFB $08,$18,$48,$38
		DEFB $08,$20,$48,$30
		DEFB $10,$08,$40,$48
		DEFB $18,$08,$38,$48
		DEFB $20,$08,$30,$48
		DEFB $10,$10,$40,$40

        ;; Copy of DoorLocs?
DoorLocsCopy:	DEFB $00, $00, $00, $00
        ;; Locations of the 4 doors along their respective walls.
DoorLocs:       DEFB $00, $00, $00, $00
DoorHeight:	DEFB $C0
C774D:		LD		A,$FF
		LD		(SkipObj),A
	;; NB: Fall through

        ;; Set up a room.
BuildRoom:	LD	IY,MinU 		; Set the base of where we load limits.
	;; Initialise the sprite extents to cover the full screen.
		LD	HL,L40C0
		LD	(ViewXExtent),HL
		LD	HL,L00FF
		LD	(ViewYExtent),HL
		LD	HL,LC0C0
		LD	(DoorLocs),HL
		LD	(DoorLocs+2),HL
		LD	HL,L0000
		LD	BC,(RoomId)
		CALL	ReadRoom
		XOR	A
		LD	(SkipObj),A
		LD	(DoorHeight),A
		LD	HL,(ObjDest)
		LD	(LAF92),HL
		LD	A,(L7710)
		LD	(DoorwayTest),A
		LD	DE,DoorLocsCopy
		LD	HL,DoorLocs
		LD	BC,L0004
		LDIR
	;; Clear the backdrop info...
		LD	HL,BkgndData
		LD	BC,L0040
		CALL	FillZero
        ;; ???
		CALL	CallBothWalls
		CALL	HasFloorAbove
		LD	A,$00
		RLA
		LD	(FloorAboveFlag),A
		CALL	StoreCorner
		LD	HL,(HasNoWall)
		PUSH	HL
		LD	A,L
		AND	$08
		JR	Z,BRM_1
        ;; Optional ReadRoom pass on object list 1:
        ;; Draw the next room in V direction, tacked on.
		LD	A,$01
		CALL	SetObjList
		LD	BC,(RoomId) ; Increment V nybble of the RoomId
		LD	A,B
		INC	A
		XOR	B
		AND	$0F
		XOR	B
		LD	B,A
		LD	A,(MaxV) ; Set HL offset to MavV
		LD	H,A
		LD	L,$00
		CALL	ReadRoom
		CALL	CallBothWalls
        
BRM_1:		LD	IY,AltLimits + 4
		POP	HL
		PUSH	HL
		LD	A,L
		AND	$04
		JR	Z,BRM_2
        ;; Optional ReadRoom pass on object list 2:
        ;; Draw the next room in U direction, tacked on.
		LD	A,$02
		CALL	SetObjList
		LD	BC,(RoomId) ; Increment U byte of the RoomId
		LD	A,B
		ADD	A,$10
		XOR	B
		AND	$F0
		XOR	B
		LD	B,A
		LD	A,(MaxU) ; Set HL offset to MaxU
		LD	L,A
		LD	H,$00
		CALL	ReadRoom
		CALL	CallBothWalls
        ;; TODO
BRM_2:		LD	A,(DoorHeight)
		LD	HL,(DoorType)
		PUSH	AF
		CALL	OccludeDoorway
		POP	AF
		CALL	SetColHeight
		POP	HL
		LD	(HasNoWall),HL
		XOR	A                       ; Switch back to usual object list.
		JP	SetObjList 		; NB: Tail call.

;; Unpacks a room, adding all its sprites to the lists, and generally
;; setting it up.
;;
;; IY points to where we stash the room size.
;; Takes room id in BC.
;; HL holds the UV origin of the room.
;;
ReadRoom:	LD	(DecodeOrgStack),HL 	; Set UV origin.
		XOR	A
		LD	(DecodeOrgStack + 2),A  ; And Z origin.
		PUSH	BC
		CALL	FindVisitRoom
		LD	B,$03
		CALL	FetchData
		LD	(L7710),A 		; TODO: Probably something to do with doors.
        ;; Load HL with DoorExts + 4 * A
		ADD	A,A
		ADD	A,A
		ADD	A,DoorExts & $FF
		LD	L,A
		ADC	A,DoorExts >> 8
		SUB	L
		LD	H,A

        ;; Loop twice...
		LD	B,$02
		LD	IX,DecodeOrgStack
ER1:
        ;; Load U, then V DoorExt and origin.
        	LD	C,(HL)
		LD	A,(IX+$00)
		AND	A
		JR	Z,ER2
        ;; If origin is non-zero, update by subtracting C and dividing by 8. (?)
		SUB	C
		LD	E,A
		RRA
		RRA
		RRA
		AND	$1F
		LD	(IX+$00),A
		LD	A,E
        ;; And store sum in IY.
ER2:		ADD	A,C
		LD	(IY+$00),A
		INC	HL
		INC	IX
		INC	IY
		DJNZ	ER1

	;; Do this bit twice, too (for U and V again)
		LD	B,$02
        ;; Take previous origin, multiply by 8 and add the DoorExt.
ER3:		LD	A,(IX-$02)
		ADD	A,A
		ADD	A,A
		ADD	A,A
		ADD	A,(HL)
        ;; Then save it.
		LD	(IY+$00),A
		INC	IY
		INC	IX
		INC	HL
		DJNZ	ER3

        ;; Now read the room configuration
                LD      B,$03
                CALL    FetchData
                LD      (AttribScheme),A        ; Fetch the attribute scheme to use.
                LD      B,$03
                CALL    FetchData
                LD      (WorldId),A             ; Fetch the current world identifier
                CALL    DoDoors
                LD      B,$03
                CALL    FetchData
                LD      (FloorCode),A           ; And the floor pattern to use
                CALL    SetFloorAddr
        ;; Then we have a loop to process objects in the room.
ER4:            CALL    ProcEntry
                JR      NC,ER4
                POP     BC
                JP      AddSpecials             ; NB: Tail call.

;; Add a signed 3-bit value in A to (HL), result in A
Add3Bit:        BIT     2,A
                JR      Z,A3B
                OR      $F8
A3B:            ADD     A,(HL)
                RET

;; Recursively do ProcEntry
RecProcEntry:   EX      AF,AF'
        ;; When processing recursively, we read 3 values to adjust the
        ;; origin for the macro-expanded processing, so it can be played
        ;; at whatever offset you like.
        ;;
        ;; Read values into B, C, A
                CALL    FetchData333
                LD      HL,(DecodeOrgPtr)
                PUSH    AF
                LD      A,B             ; Adjust U value
                CALL    Add3Bit
                LD      B,A
                INC     HL
                LD      A,C             ; Adjust V value
                CALL    Add3Bit
                LD      C,A
                INC     HL
                POP     AF
                SUB     $07
                ADD     A,(HL)          ; Adjust Z value (slightly different)
                INC     HL
        ;; Write out origin values, update pointer
                LD      (DecodeOrgPtr),HL
                LD      (HL),B
                INC     HL
                LD      (HL),C
                INC     HL
                LD      (HL),A
        ;; Origin updated, save the current read pointer.
                LD      A,(CurrData)
                LD      HL,(DataPtr)
                PUSH    AF
                PUSH    HL
        ;; Run the macro.
                CALL    FindMacro
                LD      (DataPtr),HL
RPE_1:          CALL    ProcEntry
                JR      NC,RPE_1
        ;; Pop the decode origin stack...
                LD      HL,(DecodeOrgPtr)
                DEC     HL
                DEC     HL
                DEC     HL
                LD      (DecodeOrgPtr),HL
        ;; And restore the read pointer.
                POP     HL
                POP     AF
                LD      (DataPtr),HL
                LD      (CurrData),A
        ;; NB: Fall through, carrying on.

;; Process one entry in the description array. Returns carry when done.
ProcEntry:      LD      B,$08
                CALL    FetchData
        ;; Return with carry set if we hit $FF.
                CP      $FF
                SCF
                RET     Z
        ;; Code >= $C0 means recurse.
                CP      $C0
                JR      NC,RecProcEntry         ; NB: Tail call (falls through back)
        ;; Otherwise, deal with an object.
                PUSH    IY
                LD      IY,TmpObj
                CALL    InitObj
                POP     IY
        ;; Read two bits. Bottom bit is "should loop".
        ;; Top bit is "read flag bit once for all loops?".
                LD      B,$02
                CALL    FetchData
                BIT     1,A
                JR      NZ,PE_1
        ;; We will read per loop. Set "should loop" bit.
                LD      A,$01
                JR      PE_2
PE_1:
        ;; Not reading per-loop. Read once and store in the 0x04 bit position.
                PUSH    AF
                LD      B,$01
                CALL    FetchData
                POP     BC
                RLCA
                RLCA
                OR      B
PE_2:           LD      (UnpackFlags),A
        ;; And then some processing loops thing...
PE_3:           CALL    SetTmpObjFlags
                CALL    SetTmpObjUVZEx
        ;; Only loop if loop bit (bottom bit) is set.
                LD      A,(UnpackFlags)
                RRA
                JR      NC,PE_4
        ;; Although we break out if (ExpandDone) is 0xFF.
                LD      A,(ExpandDone)
                INC     A
                AND     A
                RET     Z
                CALL    AddObjOpt
                JR      PE_3
PE_4:           CALL    AddObjOpt
                AND     A
                RET

;; If SkipObj is zero, do an "AddObject"
AddObjOpt:      LD      HL,TmpObj
                LD      BC,L0012
                PUSH    IY
                LD      A,(SkipObj)
                AND     A
                CALL    Z,AddObject
                POP     IY
                RET

;; Initialise the doors. Coord destination in IY.
DoDoors:
        ;; Read the door type? Looks like dead functionality.
                LD      B,$03
                CALL    FetchData
                CALL    ToDoorId
        ;; A contains door number - load in A*2 and A*2 + 1 into (DoorType).
                ADD     A,A
                LD      L,A
                LD      H,A
                INC     H
                LD      (DoorType),HL
        ;; Do each of the doors, with the room size information coming
        ;; in through IY. Door locations along the walls written out
        ;; to DoorLocs.
                LD      IX,DoorObjFlags
                LD      HL,DoorLocs
                EXX
                LD      A,(IY-$01)
                ADD     A,$04
                CALL    DoDoorU
                LD      HL,DoorLocs + 1
                EXX
                LD      A,(IY-$02)
                ADD     A,$04
                CALL    DoDoorV
                LD      HL,DoorLocs + 2
                EXX
                LD      A,(IY-$03)
                SUB     $04
                CALL    DoDoorU
                LD      HL,DoorLocs + 3
                EXX
                LD      A,(IY-$04)
                SUB     $04
                JP      DoDoorV         ; Tail call

;; Reads the code for the kind of door.
;;
;; It rotates flags into the door flags, and sets the door Z coord in
;; TmpObj and HL'.
;;
;; TODO: Door stuff is currently only a theory...
FetchDoor:      LD      B,$03
                CALL    FetchData
                LD      HL,HasNoWall
                SUB     $02
        ;; Jump for the fetched-a-0-or-1 case
                JR      C,FD2
        ;; Rotate a zero into HasNoWall - there's a wall.
                RL      (HL)
        ;; And rotate a one bit into HasDoor
                INC     HL
                SCF
                RL      (HL)
        ;; Set A = 9 - fetched data
                SUB     $07
                NEG
        ;; Z coordinate set to 6 * A + 0x96
                LD      C,A
                ADD     A,A
                ADD     A,C
                ADD     A,A
                ADD     A,$96
                LD      (TmpObj+7),A
        ;; Set carry flag, switch reg set and save Z coord
                SCF
                EXX
                LD      (HL),A
                RET
FD2:
        ;; No door case:
        ;; Set flag if fetched value was 0.
                CP      $FF
        ;; Complement.
                CCF
        ;; Rotate it into HasNoWall
                RL      (HL)
        ;; And rotate a zero bit into HasDoor
                AND     A
                INC     HL
                RL      (HL)
        ;; Return with no carry
                AND     A
                RET

        ;; These two take the distance along the wall in A,
        ;; and HL' is where the coordinate is stashed.
        ;; IX points to flags to use.

        ;; Build a door parallel to the V axis.
DoDoorV:	LD	(TmpObj+5),A
		LD	HL,TmpObj+6
		LD	A,(DecodeOrgStack + 1)
		JP	DoDoorAux   	; NB: Tail call

        ;; Build a door parallel to the U axis
DoDoorU:	LD	(TmpObj+6),A
		LD	HL,TmpObj+5
		LD	A,(DecodeOrgStack)
        ;; NB: Fall through

        ;; HL points to a place to put a coordinate, and A holds the
	;; base value in that dimension. Takes extra parameters in IX
	;; and HL'.
DoDoorAux:
        ;; Multiply A by 8
		ADD	A,A
		ADD	A,A
		ADD	A,A
		PUSH	AF
        ;; Stash A + $24 in the coordinate
		ADD	A,$24
		LD	(HL),A
		PUSH	HL
        ;; Get the door Z coordinate set up, return if no object to add.
		CALL	FetchDoor       ; NB: Does EXX
		JR	NC,NoDoorRet 	; NB: Tail call
        ;; Draw one half
		LD	A,(IX+$00)
		LD	(TmpObj+4),A 	; Set the flags
		INC	IX
		LD	A,(DoorType)
		LD	(TmpObj+8),A 	; Set the sprite.
        	CALL	DoHalfDoor	; And draw.
        ;; Draw the other (NB: Call deferred to tail call)
		LD	A,(IX+$00)
		LD	(TmpObj+4),A
		INC	IX
		LD	A,(DoorType+1)
		LD	(TmpObj+8),A
        ;; Stash A + $2C in the coordinate this time.
		POP	HL
		POP	AF
		ADD	A,$2C
		LD	(HL),A
        ;; NB: Fall through

        ;; Adds the current object in TmpObj, and creates a step
        ;; underneath it if necessary.
DoHalfDoor:
        ;; Add current object.
                CALL    AddObjOpt
        ;; TODO: Do some flags craziness, returning early if necessary...
                LD      A,(TmpObj+4)
                LD      C,A
                AND     $30
                RET     PO
                AND     $10
                OR      $01
                LD      (TmpObj+4),A
        ;; $C0 is ground level, don't need to put anything underneath.
                LD      A,(TmpObj+7)
                CP      $C0
                RET     Z
        ;; Otherwise, add a step under the doorway (6 down)
                PUSH    AF
                ADD     A,$06
                LD      (TmpObj+7),A    ; Update Z coord
                LD      A,SPR_STEP
                LD      (TmpObj+8),A    ; And sprite
                CALL    AddObjOpt       ; Add the step
                POP     AF
                LD      (TmpObj+7),A    ; And restore.
                RET

;; No door case - unwind variables and return
NoDoorRet:	POP	HL
		POP	AF
		INC	IX
		INC	IX
		RET

;; Clears CurrData and returns a pointer to a specific room description macro
FindMacro:      LD      A,$80
                LD      (CurrData),A    ; Clear buffered byte.
                LD      HL,RoomMacros
                EX      AF,AF'
                LD      D,$00
FM1:            LD      E,(HL)
                INC     HL
                CP      (HL)
                RET     Z
                ADD     HL,DE
                JR      FM1

;; Returns with carry set if the room above has a floor. Unset
;; otherwise.
HasFloorAbove:  LD      BC,(RoomId)
        ;; Find the next room with a lower Z coordinate (above).
                LD      A,C
                DEC     A
                AND     $F0
                LD      C,A
                CALL    FindRoom
                RET     C
        ;; Room found, extract some data
        ;; DE is the data pointer after the room header.
        ;; This code skips ahead to the floor field
                INC     DE
                INC     DE
                INC     DE
                LD      A,(DE)          ; A & $0E contains floor code.
                OR      $F1
                INC     A               ; Floor code of 7 means no floor.
                RET     Z               ; Return with clear carry if no floor.
                SCF
                RET                     ; Set carry if there's a floor.

;; Like FindRoom, but set the "visited" bit.
FindVisitRoom:  CALL    FindRoom
                EXX
                LD      A,C
                OR      (HL)
                LD      (HL),A
                EXX
                RET

;; Find a room. Takes room id in BC. Returns first field in A, and
;; room bit mask location in HL' and C'.
FindRoom:       LD      D,$00
                LD      HL,RoomList1
                CALL    FindRoom2
                RET     NC
                LD      HL,RoomList2
                JR      FindRoomInner ; NB: Tail call

        ;; Set up the room bit field thing, and do the first run.
FindRoom2:      EXX
                LD      HL,RoomMask
                LD      C,$01
                EXX
        ;; NB: Fall through

;; Finds an entry in a room list. The list consists of packed entries.
;;
;; The entry structure is:
;; 1 byte size (excludes this byte)
;; 1.5 bytes id (bottom nibble ignored for matching)
;; Data
;;
;; A size of zero terminates the list.
;;
;; This is called with:
;;  HL pointing to the start of the tagged list
;;  D should be zero - DE will be the entry size
;;  BC should be the id we're looking for
;;  HL' and C' are incremented as the address and bit mask for a bitfield
;;   associated with the nth entry.
;;
;; The carry flag is set if nothing's returned. 
FindRoomInner:
        ;; Return with carry set if (HL) is 0 - not found.
                LD      E,(HL)
                INC     E
                DEC     E
                SCF
                RET     Z
        ;; If HL+1 equals B, go to FR4
                INC     HL
                LD      A,B
                CP      (HL)
                JR      Z,FR4
        ;; Otherwise, increment HL by DE, move the bit pointer in C',
        ;; and increment HL' every time the bit wraps round. Then loop.
FR2:            ADD     HL,DE
                EXX
                RLC     C
                JR      NC,FR3
                INC     HL
FR3:            EXX
                JR      FindRoomInner
        ;; Second check: Does HL+2 & 0xF0 equal C?
FR4:            INC     HL
                DEC     E       ; Incremented HL, so decrement DE.
                LD      A,(HL)
                AND     $F0
                CP      C
                JR      NZ,FR2
        ;; Found item. Step back to start of item.
                DEC     HL
        ;; Initialise DataPtr and CurrData for new data.
                LD      (DataPtr),HL
                LD      A,$80
                LD      (CurrData),A
        ;; Skip that top nibble of id.
                LD      B,$04
                JP      FetchData ; NB: Tail call

;; Called from inside the ProcEntry loop...
SetTmpObjFlags:	LD	A,(UnpackFlags)
		RRA
		RRA
        ;; If the 'read once' bit is set, use the read-once value.
        ;; Otherwise, read another bit.
		JR	C,STOF_1
		LD	B,$01
		CALL	FetchData
STOF_1:		AND	$01
        ;; Flag goes into 0x10 position of the object flag.
		RLCA
		RLCA
		RLCA
		RLCA
		AND	$10
        ;; Set fields of TmpObj
		LD	C,A
		LD	A,(L76ED)
		XOR	C
		LD	(TmpObj+4),A
		LD	BC,(L76EC)
		BIT	4,A
		JR	Z,STOF_3
		BIT	1,A
		JR	Z,STOF_2
		XOR	$01
		LD	(TmpObj+4),A
STOF_2:		DEC	C
		DEC	C
STOF_3:		LD	A,C
		LD	(TmpObj+16),A
		RET

;; Read U, V, Z coords (3 bits each), and set TmpObj's location
SetTmpObjUVZEx: CALL    FetchData333
        ;; NB: Fall through

;; Put B = U coord, C = V coord, A = Z coord
;; Set's TmpObj's location
SetTmpObjUVZ:   EX      AF,AF'
                LD      HL,(DecodeOrgPtr)
                LD      DE,TmpObj+5
        ;; NB: Fall through

;; Calculates U, V and Z coordinates
;;  DE points to where we will write the U, V and Z coordinates
;;  HL points to the address of the origin which we add our coordinates to.
;;  B contains U, C contains V, A' contains Z
;;  U/V coordinates are built on a grid of * 8 + 12
;;  Z coordinate is built on a grid of * 6 + 0x96
;;  Sets ExpandDone to 0xFF (done) if B = 7, C = 7, A' = 0
SetUVZ:         LD      A,B
                CALL    TwiddleHL
                LD      (DE),A          ; Set U coordinate
                LD      A,C
                CALL    TwiddleHL
                INC     DE
                LD      (DE),A          ; Set V coordinate
                EX      AF,AF'
                PUSH    AF
                ADD     A,(HL)
        ;; Take value * 6 + 0x96
                LD      L,A
                ADD     A,A
                ADD     A,L
                ADD     A,A
                ADD     A,$96
                INC     DE
                LD      (DE),A          ; Set Z coordinate
                POP     AF
        ;; Set ExpandDone to 0xFF if Z coord is 0, U and V are 7.
                CPL
                AND     C
                AND     B
                OR      $F8
                LD      (ExpandDone),A
                RET

;; Read a value from (HL), increment HL, return value * 8 + 12
TwiddleHL:      ADD     A,(HL)
                INC     HL
                RLCA
                RLCA
                RLCA
                ADD     A,$0C
                RET

;; Fetch 3 lots of 3 bits to B, C and A.
FetchData333:   LD      B,$03
                CALL    FetchData
                PUSH    AF
                LD      B,$03
                CALL    FetchData
                PUSH    AF
                LD      B,$03
                CALL    FetchData
                POP     HL
                POP     BC
                LD      C,H
                RET
