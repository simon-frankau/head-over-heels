;;
;; scene.asm
;;
;; Render the scene.
;;

;; Exported functions:
;; * StoreObjExtents
;; * CheckYAndDraw
;; * UnionAndDraw
;; * CheckAndDraw
;; * GetObjExtents2

;; Exported variables:
;; * ViewXExtent
;; * ViewYExtent
;; * SpriteFlags
;; * SpriteRowCount
;; * CurrObject2

;; Sprite variables
;;
;; LSB is upper extent, MSB is lower extent
;; X extent is in screen units (2 pixels per unit). Units
;; increase down and to the right.
ViewXExtent:    DEFW $6066
ViewYExtent:    DEFW $5070
SpriteXStart:   DEFB $00
SpriteRowCount: DEFB $00
ObjXExtent:     DEFW $0000
ObjYExtent:     DEFW $0000
SpriteFlags:    DEFB $00

;; Given an object pointer in HL, calculate and store the object extents.
StoreObjExtents:INC     HL
                INC     HL
                CALL    GetObjExtents2
                LD      (ObjXExtent),BC
                LD      (ObjYExtent),HL
                RET

;; Takes object in HL, gets union of the extents of that object and
;; Obj.Extent. Returns X extent in DE, Y extent in HL.
UnionExtents:   INC     HL
                INC     HL
                CALL    GetObjExtents2
        ;; At this point, X extent in BC, Y extent in HL.
                LD      DE,(ObjYExtent)
        ;; D = min(D, H)
                LD      A,H
                CP      D
                JR      NC,UE_1
                LD      D,H
        ;; E = max(E, L)
UE_1:           LD      A,E
                CP      L
                JR      NC,UE_2
                LD      E,L
UE_2:           LD      HL,(ObjXExtent)
        ;; H = min(B, H)
                LD      A,B
                CP      H
                JR      NC,UE_3
                LD      H,B
        ;; L = max(C, L)
UE_3:           LD      A,L
                CP      C
                RET     NC
                LD      L,C
                RET

;; Store X extent, rounded, from HL
PutXExtent:     LD      A,L             ; Round L up
                ADD     A,$03
                AND     ~$03
                LD      L,A
                LD      A,H
                AND     ~$03            ; Round H down
                LD      H,A
                LD      (ViewXExtent),HL
                RET

;; Takes X extent in HL and Y extent in DE.
CheckYAndDraw:  CALL    PutXExtent
                JR      CheckYAndDraw2

;; If the end's before $48, give up, Otherwise bump the start down and
;; continue.
BumpYMinAndDraw:LD      A,$48
                CP      E
                RET     NC
                LD      D,$48
                JR      DrawCore

UnionAndDraw:   CALL    UnionExtents
        ;; NB: Fall through

;; Check the X extent - give up if it's too far to the right.
CheckAndDraw:   CALL    PutXExtent
                LD      A,E
                CP      $F1
                RET     NC
        ;; NB: Fall through

;; Check the Y extent - give up if it's negative.
;; If the start's less than $48, do a special case.
;; Takes Y extent in DE.
CheckYAndDraw2: LD      A,D
                CP      E
                RET     NC
                CP      $48
                JR      C,BumpYMinAndDraw
        ;; NB: Fall through

;; The core drawing routine: Draw the background to the view buffer,
;; draw the sprites, and then copy it to the screen.
;;
;; Y extent passed in through DE.
;;
;; TODO: Work out what all these flag variables are about...
DrawCore:       LD      (ViewYExtent),DE
                CALL    DrawBkgnd
                LD      A,(DoorFlags1)
                AND     $0C
                JR      Z,DrC_2
                LD      E,A
                AND     $08
                JR      Z,DrC_1
                LD      BC,(ViewXExtent)
                LD      HL,CornerX
                LD      A,B
                CP      (HL)
                JR      NC,DrC_1
                LD      A,(ViewYExtent+1)
                ADD     A,B
                RRA
                LD      D,A
                LD      A,(L84C7)
                CP      D
                JR      C,DrC_1
                LD      HL,ObjectLists + 4      ; Next room in V direction (??)
                PUSH    DE
                CALL    BlitObjects
                POP     DE
                BIT     2,E
                JR      Z,DrC_2
DrC_1:          LD      BC,(ViewXExtent)
                LD      A,(CornerX)
                CP      C
                JR      NC,DrC_2
                LD      A,(ViewYExtent+1)
                SUB     C
                CCF
                RRA
                LD      D,A
                LD      A,(L84C8)
                CP      D
                JR      C,DrC_2
                LD      HL,ObjectLists + 2 * 4  ; Next room in U direction
                CALL    BlitObjects
DrC_2:          LD      HL,ObjectLists + 3 * 4  ; Far
                CALL    BlitObjects
                LD      HL,ObjectLists + 0 * 4  ; Main object list
                CALL    BlitObjects
                LD      HL,ObjectLists + 4 * 4  ; Near
                CALL    BlitObjects
                JP      BlitScreen              ; NB: Tail call

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
        ;; &ViewBuff[Y-low * 6 + X-low / 4]
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
                LD      D,ViewBuff >> 8
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
;; ViewXExtent and ViewYExtent. Also saves the X start in
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
                LD      DE,(ViewXExtent)
                CALL    IntersectExtent
                EXX
                POP     BC
                RET     NC
                EX      AF,AF'
                LD      DE,(ViewYExtent)
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
