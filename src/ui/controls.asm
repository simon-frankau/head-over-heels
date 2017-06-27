;;
;; controls.asm
;;
;; Control configuration and reading functions
;;

;; Main exported functions:
;; * GetInputEntSh
;; * InitStick
;; * ListControls
;; * Strings2
;; * WaitInputClear

;; Strings table for indices >= 0x60 (i.e. 0xE0 once the top bit is set).
Strings2:
STR_ENTER:      EQU $E0
                        DEFB DELIM,"ENTER"
STR_SSH:        EQU $E1
                        DEFB DELIM,CTRL_ATTR3,"SSH"
STR_JOY_MENU:   EQU $E2
                        DEFB DELIM,CTRL_WIPE_SETPOS,$09,$00
                        DEFB CTRL_ATTRMODE,$09,CTRL_ATTR2
                        DEFB STR_SELECT,STR_JOYSTICK,STR_MENU_BLURB
STR_JOYSTICK:   EQU $E3
                        DEFB DELIM," JOYSTICK"
        ;; Joystick menu
STR_KEYSTICK:   EQU $E4
                        DEFB DELIM,STR_KEY,"S/",STR_KEY,STR_JOYSTICK
STR_KEMPSTON:   EQU $E5
                        DEFB DELIM,"KEMPSTON",STR_JOYSTICK
STR_FULLER:     EQU $E6
                        DEFB DELIM,"FULLER",STR_JOYSTICK
        ;; End of menu
STR_JOY:        EQU $E7
                        DEFB DELIM,CTRL_ATTR1,"JOY"
STR_F:          EQU $E8
                        DEFB DELIM,STR_JOY,"F"
STR_U:          EQU $E9
                        DEFB DELIM,STR_JOY,"U"
STR_D:          EQU $EA
                        DEFB DELIM,STR_JOY,"D"
STR_R:          EQU $EB
                        DEFB DELIM,STR_JOY,"R"
STR_L:          EQU $EC
                        DEFB DELIM,STR_JOY,"L"
STR_SPC:        EQU $ED
                        DEFB DELIM,CTRL_ATTR3,"SPC"
                        DEFB DELIM

        ;; NB: These are in port $FE scanning order.
CharSet:        DEFB STR_SHIFT,"ZXCVASDFGQWERT1234509876POIUY"
                DEFB STR_ENTER2,"LKJH",STR_SPC,STR_SSH,"MNB"
                DEFB STR_F,STR_U,STR_D,STR_R,STR_L

NUM_HALF_ROWS:  EQU 9
NUM_PER_HR:     EQU 8

KeyMap:
        ;; Based on half-line keyboard scans.
        ;;   Left  Right Down  Up   Jump  Carry  Fire  Swop
        DEFB $FF,  $FF,  $FF,  $FF, $FF,  $FF,   $E0,  $FF ; Shift,ZXCV = fire
        DEFB $FF,  $FF,  $FE,  $FF, $FF,  $FF,   $FF,  $E1 ; A = d, SDFG = swop
        DEFB $FF,  $FF,  $FF,  $FE, $FF,  $FF,   $FF,  $FF ; Q = u
        DEFB $FF,  $FF,  $FF,  $FF, $FF,  $FF,   $FF,  $FF ; NA
        DEFB $EF,  $F7,  $FB,  $FD, $FE,  $FF,   $FF,  $FF ; 6 = l, 7 = r, 8 = d, 9 = u, 0 = u
        DEFB $FD,  $FE,  $FF,  $FF, $FF,  $FF,   $FF,  $FF ; O = l, P = r
        DEFB $FF,  $FF,  $FF,  $FF, $FF,  $F0,   $FF,  $FF ; Enter,LKJ = carry
        DEFB $FF,  $FF,  $FF,  $FF, $E0,  $FE,   $FF,  $FF ; B = l, N = r, M = d, SS = u, Spc = j
        DEFB $EF,  $F7,  $FB,  $FD, $FE,  $FF,   $FF,  $FF ; Obvious joystick mapping

;; Joystick selection menu, called by InitStick
GoStickMenu:    LD      A,STR_JOY_MENU
                CALL    PrintChar
                LD      IX,MENU_STICK
                CALL    DrawMenu
SelSt_1:        CALL    MenuStep
                JR      C,SelSt_1
                RET

MENU_STICK:     DEFB $00                ; Selected menu item
                DEFB $03                ; 3 items
                DEFB $04                ; Initial column
                DEFB $08                ; Initial row
                DEFB STR_KEYSTICK       ; Keyboard, Kempston, Fuller

InitStick:      LD      B,$04                   ; Read 4 times.
IS_1:           IN      A,($1F)                 ; Kempston port
                AND     $1F
                CP      $1F
                JR      NC,IS_2                 ; Break if equals $1F.
                DJNZ    IS_1
IS_2:           SBC     A,A
                AND     $01
                LD      (MENU_STICK),A          ; Init to 1 if didn't equal $1F.
                CALL    GoStickMenu
                LD      A,(MENU_STICK)
                SUB     $01
                RET     C                       ; MENU_STICK = 0: Keyboard, return
                LD      HL,Kempston
                JR      Z,IS_3                  ; MENU_STICK = 1: Kempston
                LD      HL,Fuller               ; MENU_STICK = 2: Fuller
IS_3:           LD      (GIC_Joy+1),HL          ; Self-modifying code!
                LD      (StickCall+1),HL        ; Ditto
                XOR     A
                LD      (GI_Noppable),A         ; NOP the RET to fall through
                LD      A,$CD
                LD      (GetInputCtrls),A       ; Make it into a 'CALL', so that it returns.
                RET

;; These functions return the keys as follows:
;; 0x10 - Left, 0x08 - Right, 0x04 - Down, 0x02 - Up, 0x01 - Fire
;; (i.e. same order as menu)
;; All bits are set by default, and reset if pressed.

;;  Joystick handler for Kempston
Kempston:       IN      A,($1F)
                LD      B,A
                RRCA
                RRA
                RL      C
                RLCA
                RL      C
                RRA
                RRA
                RL      C
                RRA
                RL      C
                RRA
                RL      C
                LD      A,C
                CPL
                OR      $E0
                RET

;;  Joystick handler for Fuller
Fuller:         IN      A,($7F)
                LD      C,A
                RLCA
                XOR     C
                AND     $F7
                XOR     C
                RL      C
                RL      C
                XOR     C
                AND     $EF
                XOR     C
                OR      $E0
                RET

;; Scan input and return single key/button.
;; Returns 0 in A if something pressed, and the code in B.
;; Otherwise returns non-zero in A.
;; We return Buffer + row idx in HL, apparently to help EditControls,
;; and C the actual bit-mask.
GetInput:       LD      HL,Buffer
                LD      BC,$FEFE        ; Port 254 in C, ~$01 in B...
        ;; This bit scans for any key pressed. Jumps to GI_2 if found.
GI_1:           IN      A,(C)
                OR      $E0
                INC     A
                JR      NZ,GI_2
                INC     HL
                RLC     B
                JR      C,GI_1          ; Loop until the low bit hits C flag.
                INC     A               ; Return 1 if nothing found.
GI_Noppable:    RET                     ; May get overwritten for fall-through.
        ;; Now scan stick...
StickCall:      CALL    Kempston
                INC     A
                JR      NZ,GI_2
                DEC     A               ; Return -1 if nothing found.
                RET
        ;; Found something!
GI_2:           DEC     A               ; Back to what we saw.
        ;; Find first un-set bit.
                LD      BC,$FF7F        ; B becomes 0 in loop, C becomes $FE.
GI_3:           RLC     C               ; Generate the bit mask for one key
                INC     B               ; Count with B
                RRA
                JR      C,GI_3
                LD      A,L
                SUB     Buffer & $FF    ; Convert back to index
                LD      E,A
                ADD     A,A
                ADD     A,A
                ADD     A,E             ; x5
                ADD     A,B             ; Add half-keyboard/joystick bit index
                LD      B,A             ; And stash results in B...
                XOR     A               ; returning zero
                RET

;; Given a key code index in B, get the printable character for it in A.
GetCharStrId:   LD      A,B
                ADD     A,CharSet & $FF
                LD      L,A
                ADC     A,CharSet >> 8
                SUB     L
                LD      H,A
                LD      A,(HL)
                RET

;; Wait until nothing is pressed
WaitInputClear: CALL    GetInput
                JR      Z,WaitInputClear
                RET

;; Checks keys.
;; Carry is set if nothing was detected
;; Returns zero in C if enter was detected
GetInputEntSh:  CALL    GetInput
                SCF
                RET     NZ
                LD      A,B
                LD      C,$00
                CP      $1E
                RET     Z       ; Return 0 in C if Enter
                INC     C
                AND     A
                RET     Z       ; Return 1 in C if Shift...
                CP      $24
                RET     Z       ; or symbol shift.
                INC     C
                XOR     A
                RET             ; Otherwise, return 2 in C.

;; Index into the key map. Takes index in A, returns address in HL.
GetKeyMapAddr:  LD      DE,KeyMap
                LD      L,A
                LD      H,$00
                ADD     HL,DE
                RET

;; Draw the controls. Takes index in A for which control to do.
ListControls:   CALL    GetKeyMapAddr
                LD      C,$00           ; Half-row-based counter
LC_1:           LD      A,(HL)          ; Load the contents of the map
                LD      B,$FF
LC_2:           CP      $FF
                JR      Z,LC_4          ; Nothing of interest left? Done.
LC_3:           INC     B
                SCF                     ; (NB: Fill 'done' bits)
                RRA
                JR      C,LC_3          ; Find index of next bit in B.
                PUSH    HL
                PUSH    AF
                LD      A,C
                ADD     A,B             ; Put index into A...
                PUSH    BC
                LD      B,A
                CALL    GetCharStrId
                CALL    PrintCharAttr2  ; and print corresponding string.
                POP     BC
                POP     AF
                POP     HL
                JR      LC_2            ; Loop until nothing interesting left.
LC_4:           LD      DE,NUM_PER_HR   ; Go to next half-row...
                ADD     HL,DE
                LD      A,C
                ADD     A,$05           ; updating the counter,
                LD      C,A
                CP      NUM_HALF_ROWS*5 ; until all rows are down.
                JR      C,LC_1
                RET

;; Perform the editing for a particular key (in A).
EditControls:   CALL    GetKeyMapAddr
                PUSH    HL
                CALL    WaitInputClear
        ;; Initialise the buffer.
                LD      HL,Buffer
                LD      E,$FF
                LD      BC,NUM_HALF_ROWS
                CALL    FillValue
        ;; Get a character...
EC_1:           CALL    GetInput        ; Code in B, buffer loc in HL/C.
                JR      NZ,EC_1
                LD      A,B
                CP      $1E
                JR      Z,EC_3          ; If it's enter, jump to EC_3.
        ;; got it, and it's not enter.
EC_2:           LD      A,C
        ;; Loop until a new key is seen.
                AND     (HL)
                CP      (HL)
                LD      (HL),A
                JR      Z,EC_1
        ;; Print the character.
                CALL    GetCharStrId
                CALL    PrintCharAttr2
        ;; Now print the enter to finish message (after first char).
                LD      HL,(CharCursor)
                PUSH    HL
                LD      A,STR_ENTER_TO_FINISH
                CALL    PrintChar
                CALL    WaitInputClear
                POP     HL
                LD      (CharCursor),HL
        ;; Get more characters, as long as we don't run out of space.
                LD      A,$C0
                SUB     L
                CP      $14
                JR      NC,EC_1
        ;; Enter was hit, let's see if we're finished.
EC_3:           EXX
        ;; Search for any pressed keys...
                LD      HL,Buffer
                LD      A,$FF
                LD      B,NUM_HALF_ROWS
EC_4:           CP      (HL)
                INC     HL
                JR      NZ,EC_5
                DJNZ    EC_4
        ;; Found nothing, must be first key, treat enter as the key to set.
                EXX
                LD      A,$1E
                JR      EC_2            ; Back into the loop.
        ;; Found something! The enter was the last key, update KeyMap.
EC_5:           POP     HL
        ;; And copy our buffer over to the main KeyMap buffer.
                LD      BC,NUM_PER_HR
                LD      A,NUM_HALF_ROWS
                LD      DE,Buffer
EC_6:           EX      AF,AF'
                LD      A,(DE)
                LD      (HL),A
                INC     DE
                ADD     HL,BC
                EX      AF,AF'
                DEC     A
                JR      NZ,EC_6
                JP      WaitInputClear  ; Tail call

PrintCharAttr2: PUSH    AF
                LD      A,CTRL_ATTR2
                CALL    PrintChar
                POP     AF
                JP      PrintChar       ; Tail call
