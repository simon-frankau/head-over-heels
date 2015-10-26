;;
;; scene.asm
;;
;; Render the scene.
;;

;; Exported functions:
        ;; * CA05D
        ;; * CA098
;; * CA0A5
        ;; * CA0A8
        ;; * GetObjExtents2
        

        ;; Exported variables:
        ;; * SpriteXExtent
        ;; * SpriteYExtent
        ;; * SpriteFlags
        ;; * SpriteRowCount
        ;; * CurrObject2

        
        ;; LSB is upper extent, MSB is lower extent
        ;; X extent is in screen units (2 pixels per unit). Units
	;; increase down and to the right.
SpriteXExtent:	DEFW $6066
SpriteYExtent:	DEFW $5070
SpriteXStart:	DEFB $00
SpriteRowCount:	DEFB $00
LA058:	DEFB $00
LA059:	DEFB $00
LA05A:	DEFB $00
LA05B:	DEFB $00
SpriteFlags:	DEFB $00

CA05D:		INC		HL
		INC		HL
		CALL	GetObjExtents2
		LD		(LA058),BC
		LD		(LA05A),HL
		RET

	
CA06A:		INC		HL
		INC		HL
		CALL		GetObjExtents2
		LD		DE,(LA05A)
		LD		A,H
		CP		D
		JR		NC,LA078
		LD		D,H
LA078:		LD		A,E
		CP		L
		JR		NC,LA07D
		LD		E,L
LA07D:		LD		HL,(LA058)
		LD		A,B
		CP		H
		JR		NC,LA085
		LD		H,B
LA085:		LD		A,L
		CP		C
		RET		NC
		LD		L,C
		RET

;;;  TODO: This section looks like full screen drawing.
        
;; Store X extent, rounded, from HL
PutXExtent:	LD	A,L 		; Round L up
		ADD	A,$03
		AND	~$03
		LD	L,A
		LD	A,H
		AND	~$03    	; Round H down
		LD	H,A
		LD	(SpriteXExtent),HL
		RET


CA098:		CALL	PutXExtent
		JR	LA0AF

LA09D:		LD	A,$48
		CP	E
		RET	NC
		LD	D,$48
		JR	LA0B6

CA0A5:		CALL	CA06A
        ;; NB: Fall through

CA0A8:		CALL	PutXExtent
		LD	A,E
		CP	$F1
		RET	NC
LA0AF:		LD	A,D
		CP	E
		RET	NC
		CP	$48
		JR	C,LA09D

LA0B6:		LD	(SpriteYExtent),DE
		CALL	DrawBkgnd
		LD	A,(L7716)
		AND	$0C
		JR	Z,LA109
		LD	E,A
		AND	$08
		JR	Z,LA0EC
		LD	BC,(SpriteXExtent)
		LD	HL,L84C9
		LD	A,B
		CP	(HL)
		JR	NC,LA0EC
		LD	A,(SpriteYExtent+1)
		ADD	A,B
		RRA
		LD	D,A
		LD	A,(L84C7)
		CP	D
		JR	C,LA0EC
		LD	HL,ObjList5
		PUSH	DE
		CALL	BlitObjects
		POP	DE
		BIT	2,E
		JR	Z,LA109
LA0EC:		LD	BC,(SpriteXExtent)
		LD	A,(L84C9)
		CP	C
		JR	NC,LA109
		LD	A,(SpriteYExtent+1)
		SUB	C
		CCF
		RRA
		LD	D,A
		LD	A,(L84C8)
		CP	D
		JR	C,LA109
		LD	HL,ObjList1
		CALL	BlitObjects
LA109:		LD	HL,ObjList2
		CALL	BlitObjects
		LD	HL,ObjList3
		CALL	BlitObjects
		LD	HL,ObjList4
		CALL	BlitObjects
		JP	BlitScreen 	; NB: Tail call

;; Call BlitObject for each object in the linked list.
;; Note that we're using the second link, so the passed HL is an
;; object + 2.
BlitObjects:    LD      A,(HL)
                INC     HL
                LD      H,(HL)
                LD      L,A
                OR      H
                RET     Z
                LD      (CurrObject2+1),HL      ; Odd way to save an item!
                CALL    BlitObject
CurrObject2:    LD      HL,L0000                ; NB: Self-modifying code
                JR      BlitObjects

;;  Set carry flag if there's overlap
;;  X adjustments in HL', X overlap in A'
;;  Y adjustments in HL,  Y overlap in A
BlitObject:     CALL    IntersectObj
                RET     NC              ; No intersection? Return
                LD      (SpriteRowCount),A
        ;; Find sprite blit destination:
        ;; &SpriteBuff[Y-low * 6 + X-low / 4]
        ;; (X coordinates are in 2-bit units, want byte coordinate)
                LD      A,H
                ADD     A,A
                ADD     A,H
                ADD     A,A
                EXX
                SRL     H
                SRL     H
                ADD     A,H
                LD      E,A
                LD      D,SpriteBuff >> 8
        ;; Push destination.
                PUSH    DE
        ;; Push X adjustments
                PUSH    HL
                EXX
        ;; A = SpriteWidth & 4 ? -L * 4: -L * 3
        ;; (Where L is the Y-adjustment for the sprite)
                LD      A,L
                NEG
                LD      B,A
                LD      A,(SpriteWidth)
                AND     $04
                LD      A,B
                JR      NZ,BO_1
                ADD     A,A
                ADD     A,B
                JR      BO_2
BO_1:           ADD     A,A
                ADD     A,A
BO_2:           PUSH    AF
        ;; Image and mask addressed loaded, and then adjusted by A.
                CALL    GetSpriteAddr
                POP     BC
                LD      C,B
                LD      B,$00
                ADD     HL,BC
                EX      DE,HL
                ADD     HL,BC
        ;; Rotate the sprite if not byte-aligned.
                LD      A,(SpriteXStart)
                AND     $03
                CALL    NZ,BlitRot
        ;; Get X adjustment back.
                POP     BC
                LD      A,C
                NEG
        ;; Rounded up divide by 4 to get byte adjustment...
                ADD     A,$03
                RRCA
                RRCA
        ;; and apply to image and mask.
                AND     $07
                LD      C,A
                LD      B,$00
                ADD     HL,BC
                EX      DE,HL
                ADD     HL,BC
        ;; Set it so thtat destination is in BC', image and mask in HL' and DE'.
                POP     BC
                EXX
        ;; Load DE with an index from the blit functions table. This selects
        ;; the subtable based on the sprite width.
                LD      A,(SpriteWidth)
                SUB     $03
                ADD     A,A
                LD      E,A
                LD      D,$00
                LD      HL,BlitMaskFns
                ADD     HL,DE
                LD      E,(HL)
                INC     HL
                LD      D,(HL)
        ;; X overlap is still in A' from the IntersectObj call
                EX      AF,AF'
        ;; We use this to select the function within the subtable, which will
        ;; blit over n bytes worth, depending on the overlap size...
        ;;
        ;; We convert the overlap in double pixels into the overlap in bytes,
        ;; x2, to get the offset of the function in the table.
                DEC     A
                RRA
                AND     $0E
                LD      L,A
                LD      H,$00
                ADD     HL,DE
                LD      A,(HL)
                INC     HL
                LD      H,(HL)
                LD      L,A
        ;; Call the blit function with number of rows in B, destination in
        ;; BC', source in DE', mask in HL'
                LD      A,(SpriteRowCount)
                LD      B,A
                JP      (HL)            ; Tail call to blitter...

BlitMaskFns:    DEFW BlitMasksOf1
                DEFW BlitMasksOf2
                DEFW BlitMasksOf3
BlitMasksOf1:   DEFW BlitMask1of3, BlitMask2of3, BlitMask3of3
BlitMasksOf2:   DEFW BlitMask1of4, BlitMask2of4, BlitMask3of4, BlitMask4of4
BlitMasksOf3:   DEFW BlitMask1of5, BlitMask2of5, BlitMask3of5, BlitMask4of5, BlitMask5of5

;; Given an object, calculate the intersections with
;; SpriteXExtent and SpriteYExtent. Also saves the X start in
;; SpriteXStart.
;;
;; Parameters: HL contains object+2
;; Returns:
;;  Set carry flag if there's overlap
;;  X adjustments in HL', X overlap in A'
;;  Y adjustments in HL,  Y overlap in A
IntersectObj:   CALL    GetObjExtents
                LD      A,B
                LD      (SpriteXStart),A
                PUSH    HL
                LD      DE,(SpriteXExtent)
                CALL    IntersectExtent
                EXX
                POP     BC
                RET     NC
                EX      AF,AF'
                LD      DE,(SpriteYExtent)
                CALL    IntersectExtent
                RET

;; Like GetObjExtents, except if bit of flags is set, H is adjusted.
;; If bit 5 is set, H is adjusted by -12, not set then -16
;;
;; Parameters: Object+2 in HL
;; Returns: X extent in BC, Y extent in HL
GetObjExtents2: INC     HL
                INC     HL
                LD      A,(HL)
                BIT     3,A             ; object[4] & 0x08?
                JR      Z,GOE_1         ; Tail call out if not set
                CALL    GOE_1           ; Otherwise, call and return
                LD      A,(SpriteFlags)
                BIT     5,A
                LD      A,-16
                JR      Z,GOE2_1
                LD      A,-12
GOE2_1:         ADD     A,H
                LD      H,A             ; Adjust H
                RET

;; Sets SpriteFlags and generates extents for the object.
;;
;; Parameters: Object+2 in HL
;; Returns: X extent in BC, Y extent in HL
GetObjExtents:  INC     HL
                INC     HL
                LD      A,(HL)
        ;; A = (object[4] & 0x10) ? 0x80 : 0x00
GOE_1:          BIT     4,A
                LD      A,$00
                JR      Z,GOE_2
                LD      A,$80
GOE_2:          EX      AF,AF'
                INC     HL
                CALL    UVZtoXY         ; Called with object + 5
                INC     HL
                INC     HL              ; Now at object + 10
                LD      A,(HL)
                LD      (SpriteFlags),A
                DEC     HL
                EX      AF,AF'
                XOR     (HL)            ; Flip flag on top of offset 9?
                JP      GetSprExtents   ; NB: Tail call

;; Calculate parameters to do with overlapping extents
;; Parameters:
;;  BC holds extent of sprite
;;  DE holds current extent
;; Returns:
;;  Sets carry flag if there's any overlap.
;;  H holds the lower adjustment
;;  L holds the upper adjustment
;;  A holds the overlap size.
IntersectExtent:
        ;; Check overlap and return NC if there is none.
                LD      A,D
                SUB     C
                RET     NC      ; C <= D, return
                LD      A,B
                SUB     E
                RET     NC      ; E <= B, return
        ;; There's overlap. Calculate it.
                NEG
                LD      L,A     ; L = E - B
                LD      A,B
                SUB     D       ; A = B - D
                JR      C,IE_1
        ;; B >= D case
                LD      H,A     ; H = B - D
                LD      A,C
                SUB     B       ; A = C - B
                LD      C,L     ; C = E - B
                LD      L,$00   ; L = 0
                CP      C       ; Return A = min(C - B, E - B)
                RET     C
                LD      A,C
                SCF
                RET
IE_1:           LD      L,A     ; L = B - D
                LD      A,C
                SUB     D
                LD      C,A     ; C = C - D
                LD      A,E
                SUB     D       ; A = E - D
                CP      C
                LD      H,$00   ; H = 0
                RET     C       ; Return A = min(E - D, C - D)
                LD      A,C
                SCF
                RET

;; Given HP pointing to an Object + 5, return X coordinate
;; in C, Y coordinate in B. Increments HL by 3.
UVZtoXY:        LD      A,(HL)
                LD      D,A             ; U coordinate
                INC     HL
                LD      E,(HL)          ; V coordinate
                SUB     E
                ADD     A,$80           ; U - V + 128 = X coordinate
                LD      C,A
                INC     HL
                LD      A,(HL)          ; Z coordinate
                ADD     A,A
                SUB     E
                SUB     D
                ADD     A,$7F
                LD      B,A             ; 2 * Z - U - V + 127 = Y coordinate
                RET
