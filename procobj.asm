;;
;; procobj.asm
;;
;; Mystery set of functions that handle an object?
;;

;; Exported functions:
;;  * ProcDataObj
;;  * GetUVZExtents
;;  * ProcObjUnk1
;;  * ProcObjUnk5
;;  * ProcObjUnk2
;;  * ProcObjUnk4
;;  * GetUVZExtents2

;; Called during the ProcEntry loop to copy an object into the dest
;; buffer and process it.
;;
;; HL points to an object.
;; BC contains the size of the object (always 18 bytes!).
ProcDataObj:
        ;; First, just return if there's no intersection with the view window.
                PUSH    HL
                PUSH    BC
                INC     HL
                INC     HL
                CALL    IntersectObj   ; HL now contains an object + 2
                POP     BC
                POP     HL
                RET     NC
        ;; Copy BC bytes of object to what ObjDest pointer, updating ObjDest
                LD      DE,(ObjDest)
                PUSH    DE
                LDIR
                LD      (ObjDest),DE
                POP     HL
        ;; HL now points at copied object
                PUSH    HL
                POP     IY
                BIT     3,(IY+$04)      ; Check bit 3 of flags...
                JR      Z,ProcObjUnk1   ; NB: Tail call if not set
        ;; Bit 3 set = tall object
		LD	BC,L0009
		PUSH	HL
		LDIR
		EX	DE,HL
		LD	A,(DE)  	; Load A with offset 10 of original
		OR	$02
		LD	(HL),A  	; Set bit 1, write out.
		INC	HL
		LD	(HL),$00 	; Write 0 to offset 11
		LD	DE,L0008
		ADD	HL,DE
		LD	(ObjDest),HL 	; Update pointer to after new object.
        ;; If bit 5 of offset 9 set, set the sprite on this second object.
		BIT	5,(IY+$09)
		JR	Z,PDO2
		PUSH	IY
		LD	DE,L0012
		ADD	IY,DE
		LD	A,(L822E)
		CALL	SetObjSprite
		POP	IY
PDO2:		POP	HL
        ;; NB: Fall through.

;; HL points at an object, as does IY.
ProcObjUnk1:	LD	A,(LAF77)
		DEC	A
		CP	$02
		JR	NC,ProcObjUnk2 	; NB: Tail call
		INC	HL
		INC	HL
		BIT	3,(IY+$04)
		JR	Z,CB034
		PUSH	HL
		CALL	CB034
		POP	DE
		CALL	CAFAB
		PUSH	HL
		CALL	GetUVZExtents2
		EXX
		PUSH	IY
		POP	HL
		INC	HL
		INC	HL
		JR	DepthInsert

CB034:		PUSH	HL
		CALL	GetUVZExtents2
		EXX
		JR	DepthInsertHd

;; TODO
ProcObjUnk2:	INC	HL
		INC	HL
		BIT	3,(IY+$04)
		JR	Z,ProcObjUnk3 	; NB: Tail call
		PUSH	HL
		CALL	ProcObjUnk3
		POP	DE
		CALL	CAFAB
		PUSH	HL
		CALL	GetUVZExtents2
		EXX
		PUSH	IY
		POP	HL
		INC	HL
		INC	HL
		JR	DepthInsert   	; NB: Tail call

        ;; TODO
ProcObjUnk3:	PUSH	HL
		CALL	GetUVZExtents2
		LD	A,$03
		EX	AF,AF'
		LD	A,(L771A)
		CP	D
		JR	C,LB07D
		LD	A,(L771B)
		CP	H
		JR	C,LB07D
		LD	A,$04
		EX	AF,AF'
		LD	A,(L7718)
		DEC	A
		CP	E
		JR	NC,LB07D
		LD	A,(L7719)
		DEC	A
		CP	L
		JR	NC,LB07D
		XOR	A
		EX	AF,AF'
LB07D:		EXX
		EX	AF,AF'
		CALL	CAF96
        ;; NB: Fall through

;; Does DepthInsert on the list pointed to by ObjListPtr
DepthInsertHd:	LD	HL,(ObjListPtr)
        ;; NB: Fall through

        ;; Object extents in alt registers, obj+2 in HL.
        ;;
        ;; I believe this traverses a list sorted far-to-near, and
        ;; loads up HL with the nearest object further away from our
        ;; object.
DepthInsert:    LD      (SortObj),HL
DepIns2:        LD      A,(HL)          ; Load next object into HL...
                INC     HL
                LD      H,(HL)
                LD      L,A
                OR      H
                JR      Z,DepIns3         ; Zero? Done!
                PUSH    HL
                CALL    GetUVZExtents2
                CALL    DepthCmp
                POP     HL
                JR      NC,DepthInsert  ; Update SortObj if current HL is far away
                AND     A
                JR      NZ,DepIns2      ; Break out of loop if past point of caring
DepIns3:        LD      HL,(SortObj)
        ;; TODO: I assume this updates the object pointers?
        ;; Load our object in DE, HL contains object to chain after.
		POP	DE
        ;; Copy HL obj's 'next' pointer into DE obj's.
		LD	A,(HL)
		LDI
		LD	C,A
		LD	A,(HL)
		LD	(DE),A
        ;; Now copy address of DE into HL's 'next' pointer.
		DEC	DE
		LD	(HL),D
		DEC	HL
		LD	(HL),E
        ;; Put DE's 'next' pointer into HL.
		LD	L,C
		LD	H,A
        ;; And if it's zero, load HL with object referred to at LAF7C
		OR	C
		JR	NZ,DepIns4
		LD	HL,(LAF7C)
		INC	HL
		INC	HL
        ;; FIXME... and then some final pointer update stuff? What?
DepIns4:	DEC	HL
		DEC	DE
		LDD
		LD	A,(HL)
		LD	(DE),A
		LD	(HL),E
		INC	HL
		LD	(HL),D
		RET

        ;; FIXME: Other functions!
ProcObjUnk4:	PUSH	HL
		CALL	ProcObjUnk5
		POP	HL
		JP	ProcObjUnk2

ProcObjUnk5:	BIT	3,(IY+$04)
		JR	Z,CB0D5
		PUSH	HL
		CALL	CB0D5
		POP	DE
		LD	HL,L0012
		ADD	HL,DE
        ;; NB: Fall through.

CB0D5:		LD	E,(HL)
		INC	HL
		LD	D,(HL)
		INC	HL
		PUSH	DE
		LD	A,D
		OR	E
		INC	DE
		INC	DE
		JR	NZ,LB0E4
		LD	DE,(ObjListPtr)
LB0E4:		LD	A,(HL)
		LDI
		LD	C,A
		LD	A,(HL)
		LD	(DE),A
		LD	H,A
		LD	L,C
		OR	C
		DEC	HL
		JR	NZ,LB0F4
		LD	HL,(LAF7C)
		INC	HL
LB0F4:		POP	DE
		LD	(HL),D
		DEC	HL
		LD	(HL),E
		RET

;; Like GetUVZExtents, but applies extra height adjustment -
;; increases height by 6 if flag bit 3 is set.
GetUVZExtentsE: CALL    GetUVZExtents
                AND     $08
                RET     Z
                LD      A,C
                SUB     $06
                LD      C,A
                RET

;; Given an object in HL, returns its U, V and Z extents.
;; moves in a particular direction:
;;
;; D = high U, E = low U
;; H = high V, L = low V
;; B = high Z, C = low Z
;; It also returns flags in A.
;;
;; Values are based on the bottom 3 flag bits
;; Flag   U      V      Z
;; 0    +3 -3  +3 -3  0  -6
;; 1    +4 -4  +4 -4  0  -6
;; 2    +4 -4  +1 -1  0  -6
;; 3    +1 -4  +4 -4  0  -6
;; 4    +4  0  +4  0  0 -18
;; 5     0 -4  +4  0  0 -18
;; 6    +4  0   0 -4  0 -18
;; 7     0 -4   0 -4  0 -18
GetUVZExtents:  INC     HL
                INC     HL
        ;; NB: Fall through!

;; GetUVZExtents, except HL has a pointer + 2 to an object.
GetUVZExtents2: INC     HL
                INC     HL
                LD      A,(HL)          ; Offset 4: Flags
                INC     HL
                LD      C,A
                EX      AF,AF'
                LD      A,C
                BIT     2,A
                JR      NZ,GUVZE5       ; If bit 2 set
                BIT     1,A
                JR      NZ,GUVZE3       ; If bit 1 set
                AND     $01
                ADD     A,$03
                LD      B,A             ; Bit 0 + 3 in B
                ADD     A,A
                LD      C,A             ; x2 in C
                LD      A,(HL)          ; Load U co-ord
                ADD     A,B
                LD      D,A             ; Store added co-ord in D
                SUB     C
                LD      E,A             ; And subtracted co-ord in E
                INC     HL
                LD      A,(HL)          ; Load V co-ord
                INC     HL
                ADD     A,B
                LD      B,(HL)          ; Load Z co-ord for later
                LD      H,A             ; Store 2nd added co-ord in H
                SUB     C
                LD      L,A             ; And 2nd subtracted co-ored in L
GUVZE2:         LD      A,B
                SUB     $06
                LD      C,A             ; Put Z co-ord - 6 in C
                EX      AF,AF'
                RET

        ;; Bit 1 was set in the object flags
GUVZE3:         RRA
                JR      C,GUVZE4
        ;; Bit 1 set, bit 0 not set
                LD      A,(HL)
                ADD     A,$04
                LD      D,A
                SUB     $08
                LD      E,A             ; D/E given added/subtracted U co-ords of 4
                INC     HL
                LD      A,(HL)
                INC     HL
                LD      B,(HL)
                LD      H,A
                LD      L,A             ; H/L given added/subtracted V co-ords of 1
                INC     H
                DEC     L
                JR      GUVZE2

        ;; Bits 1 and 0 were set
GUVZE4:         LD      D,(HL)
                LD      E,D
                INC     D
                DEC     E               ; D/E given added/subtracted U co-ords of 1
                INC     HL
                LD      A,(HL)
                INC     HL
                ADD     A,$04
                LD      B,(HL)
                LD      H,A
                SUB     $08
                LD      L,A             ; H/L given added/subtracted V co-ords of 4
                JR      GUVZE2

        ;; Bit 2 was set in the object flags
GUVZE5:         LD      A,(HL)          ; Load U co-ord
                RR      C
                JR      C,GUVZE5b
        ;; Bit 0 reset
                LD      E,A
                ADD     A,$04
                LD      D,A
                JR      GUVZE5c
        ;; Bit 0 set
GUVZE5b:        LD      D,A
                SUB     $04
                LD      E,A
GUVZE5c:        INC     HL
                LD      A,(HL)          ; Load V co-ord
                INC     HL
                LD      B,(HL)          ; Load Z co-ord
                RR      C
                JR      C,GUVZE5d
        ;; Bit 1 reset
                LD      L,A
                ADD     A,$04
                LD      H,A
                JR      GUVZE5e
        ;; Bit 1 set
GUVZE5d:        LD      H,A
                SUB     $04
                LD      L,A
GUVZE5e:        LD      A,B
                SUB     $12
                LD      C,A
                EX      AF,AF'
                RET
