;;
;; sprite_stuff.asm
;;
;; Does various ad hoc sprite-drawing tasks.
;;

;; Exported functions:
;;  * CrownScreen
;;  * DrawScreenPeriphery
;;  * Draw2FromList
;;  * CrownScreenCont
;;  * Draw3x24
;;  * Clear3x24

;; Draw the crown screen and then go back to the game screen.
CrownScreenCont:LD      A,(WorldMask)
                CP      $1F
                JR      NZ,ES_1
        ;; Get proclaimed Emperor!
                LD      A,STR_WIN_SCREEN
                CALL    PrintChar
                CALL    PlayTune
                LD      DE,$040F
                LD      HL,MainMenuSpriteList
                CALL    DrawFromList
                CALL    WaitKey
        ;; Dislay the crowns you've won.
ES_1:           CALL    CrownScreen
        ;; Then back to the normal display.
                CALL    DrawBlacked
                JP      RevealScreen    ; NB: Tail call

;; Just draw the crown screen and wait for a keypress
CrownScreen:    LD      A,STR_EMPIRE_BLURB
                CALL    PrintChar
                CALL    PlayTune
                LD      HL,PlanetsSpriteList
                LD      DE,$05FF
                CALL    DrawFromList
                LD      HL,CrownsSpriteList
                LD      DE,(WorldMask)
                LD      D,$05
                CALL    DrawFromList
        ;; NB: Fall through

WaitKey:        CALL    WaitInputClear
                CALL    WaitKeyPressed
                CALL    ScreenWipe
                LD      B,$C1           ; "Tada" noise
                JP      PlaySound       ; NB: Tail call

WaitKeyPressed: LD      HL,$A800
WKP_1:          PUSH    HL
                CALL    PlayTune
                CALL    GetInputEntSh
                POP     HL
                RET     NC              ; Return if key was pressed.
                DEC     HL
                LD      A,H
                OR      L
                JR      NZ,WKP_1
                RET

PlanetsSpriteList:      DEFB SPR_BALL,$54,$78
                        DEFB SPR_BALL,$A4,$78
                        DEFB SPR_BALL,$54,$E8
                        DEFB SPR_BALL,$A4,$E8
                        DEFB SPR_BALL,$7C,$B0

CrownsSpriteList:       DEFB SPR_CROWN,$54,$60
                        DEFB SPR_CROWN,$A4,$60
                        DEFB SPR_CROWN,$54,$D0
                        DEFB SPR_CROWN,$A4,$D0
                        DEFB SPR_CROWN,$7C,$98

DrawScreenPeriphery:    CALL    DrawCarriedObject
                        LD      HL,PeripherySpriteList
                        LD      DE,(Inventory)
                        LD      D,$03
                        CALL    DrawFromList
                        LD      DE,(Character)
        ;; NB: Fall through

Draw2FromList:  LD      D,$02
        ;; NB: Fall through

;; Given a list of sprites, draw them.
;;
;; Load D with number of sprites
;; Load E with bitmask for whether to drawn the nth sprite
;; Load HL with pointer to data
;; Data should contain: Sprite code (1 byte), Coordinates (2 bytes)
DrawFromList:   LD      A,(HL)
                INC     HL
                LD      C,(HL)
                INC     HL
                LD      B,(HL)
                INC     HL
                PUSH    HL
                RR      E
                PUSH    DE
                JR      NC,DFL_2
                CALL    Draw3x24
DFL_1:          POP     DE
                POP     HL
                DEC     D
                JR      NZ,DrawFromList
                RET
DFL_2:          LD      D,$01
                CALL    Draw3x24b
                JR      DFL_1

;; All the icons around the edge of the screen
PeripherySpriteList:    DEFB SPR_PURSE,            $B0,$F0
                        DEFB SPR_HOOTER,           $44,$F0
                        DEFB SPR_DONUTS,           $44,$D8
                        DEFB SPR_HEELS1 | SPR_FLIP,$94,$F0
                        DEFB SPR_HEAD1,            $60,$F0

;; Call Draw3x24b with attribute type 3.
Draw3x24a:      LD      D,$03
        ;; NB: Fall through

;; Draw a 3 byte x 24 row sprite on clear background, complete with
;; attributes, via DrawSprite.
;;
;; Sprite code in A.
;; Origin in BC - Y coordinate gets adjusted by 72 (size of sprite)
;; Attribute style in D
Draw3x24b:      LD      (SpriteCode),A
                LD      A,B
                SUB     $48
                LD      B,A
                PUSH    DE
                PUSH    BC
                CALL    GetSpriteAddr   ; Loads image into DE
                LD      HL,$180C        ; Size is 24 * 12 (double pixels)
                POP     BC
                POP     AF              ; Move contents from D to A.
                AND     A
                JP      DrawSprite      ; NB: Tail call

;; Draw a 3 byte x 24 row sprite on clear background.
;; Takes sprite code in A, coordinates in BC.
;; Attribute style in D.
Draw3x24:       LD      L,$00
                DEC     L
                INC     L
                JR      Z,Draw3x24a     ; And just use Draw3x24a.
        ;; This code here is dead. Some other way of doing things, but
        ;; the Draw3x24a jump is always triggered, so it's never used.
                LD      (SpriteCode),A
                CALL    SetExtents3x24
                CALL    ClearViewBuf
                CALL    GetSpriteAddr
                LD      BC,ViewBuff
                EXX
                LD      B,$18
                CALL    BlitMask3of3
                JP      BlitScreen

;; Takes coordinates in BC, and clears a 3x24 section of display
Clear3x24:      CALL    SetExtents3x24
                CALL    ClearViewBuf
                JP      BlitScreen

;; Set up the extent information for a 3 byte x 24 row sprite
;; Y coordinate in B, X coordinate in C
SetExtents3x24: LD      H,C
                LD      A,H
                ADD     A,$0C
                LD      L,A
                LD      (ViewXExtent),HL
                LD      A,B
                ADD     A,$18
                LD      C,A
                LD      (ViewYExtent),BC
                RET

;; Draw a 3 byte x 32 row sprite on clear background.
;; Takes sprite code in A, coordinates in BC.
Draw3x32:       LD      (SpriteCode),A
                CALL    SetExtents3x24
                LD      A,B
                ADD     A,$20
                LD      (ViewYExtent),A ; Set adjusted extents.
                CALL    ClearViewBuf    ; Clear buffer
                LD      A,$02
                LD      (SpriteFlags),A
                CALL    GetSpriteAddr
                LD      BC,ViewBuff
                EXX
                LD      B,$20
                CALL    BlitMask3of3    ; Draw into buffer.
                JP      BlitScreen      ; Buffer to screen.

ClearViewBuf:   LD      HL,ViewBuff
                LD      BC,$0100
                JP      FillZero        ; Tail call
