;;
;; menus.asm
;;
;; Menu-related stuff. Includes main strings table.
;;

;; Main exported functions:
;; * GameOverScreen
;; * GoMainMenu
;; * Strings

MenuCursor:     DEFW $0000      ; Location of the menu pointer

;; Only the first two entries are used for the main menu. The
;; four-entry version is used on the crown screen.
MainMenuSpriteList:     DEFB SPR_HEAD1,            $60,$60
                        DEFB SPR_HEELS1 | SPR_FLIP,$8C,$60
                        DEFB SPR_CROWN,            $60,$48
                        DEFB SPR_CROWN  | SPR_FLIP,$8C,$48

;; Main menu - returns with carry for new game, without for continue.
GoMainMenu:     LD      A,STR_GO_TITLE_SCREEN
                CALL    PrintChar
                LD      IX,MENU_MAIN
                LD      (IX+MENU_CUR_ITEM),$00
                CALL    DrawHnH
                CALL    DrawMenu
GMM_1:          CALL    Random                  ; Seed the PRNG
                CALL    MenuStep
                JR      C,GMM_1
                LD      A,(IX+MENU_CUR_ITEM)
                CP      $01
                JP      C,GoPlayGameMenu        ; Item 0 - play game - tail call
                JR      NZ,GMM_2
                CALL    GoControlsMenu          ; Item 1 - controls menu, then loop.
                JR      GoMainMenu
GMM_2:          CP      $03
                LD      HL,GoMainMenu
                PUSH    HL                      ; Insert return to GoMainMenu.
                JP      Z,GoSensMenu            ; Item 3 - sensitivity menu
                JP      GoSoundMenu             ; Item 2 - sound menu

;; Draw head and heels
DrawHnH:        LD      E,$03
                LD      HL,MainMenuSpriteList
                JP      Draw2FromList           ; Tail call

MENU_MAIN:      DEFB $00                ; Selected menu item
                DEFB $04                ; 4 items
                DEFB $05                ; Initial column
                DEFB $89                ; Initial row
                DEFB STR_PLAY_THE_GAME  ; Play game, select keys, adjust sound, control sens

GoSoundMenu:    LD      A,STR_SOUND_MENU
                CALL    PrintChar
                LD      IX,MENU_SOUND
                CALL    DrawMenu
GoSM_1:         CALL    MenuStep
                JR      C,GoSM_1
                LD      A,(MENU_SOUND)  ; (MENU_SOUND) is used to store the actual level...
                CP      $02             ; But if you set it to 2 ('pardon')...
                LD      HL,SndEnable
                SET     7,(HL)
                RET     NZ
                RES     7,(HL)          ; sound is disabled.
                RET

MENU_SOUND:     DEFB $00                ; Selected menu item
                DEFB $03                ; 3 items
                DEFB $07                ; Initial column
                DEFB $08                ; Initial row
                DEFB STR_LOTS           ; Lots of it, not so much, pardon

;; Run the controls-editing menu
GoControlsMenu:
        ;; Draw the menu boilerplate
                LD      A,STR_SELECT_THEN_SHIFT
                CALL    PrintChar
                LD      IX,MENU_CONTROLS
                CALL    DrawMenu
        ;; Then draw the current controls
                LD      B,$08
GCM_1:          PUSH    BC
                LD      A,B
                DEC     A
                CALL    PrepCtrlEdit
                POP     BC
                PUSH    BC
                LD      A,B
                DEC     A
                CALL    ListControls
                POP     BC
                DJNZ    GCM_1
        ;; Then do the control-editing loop
GCM_2:          CALL    MenuStepAlt
                JR      C,GCM_2
                RET     NZ
                LD      A,STR_PRESS_KEYS_REQD
                CALL    PrintChar
                LD      A,(IX+MENU_CUR_ITEM)
                ADD     A,(IX+MENU_STR_BASE)
                CALL    PrintChar
                LD      A,CTRL_BLANKS
                CALL    PrintChar
                LD      A,(IX+MENU_CUR_ITEM)
                CALL    PrepCtrlEdit
                LD      A,(IX+MENU_CUR_ITEM)
                CALL    EditControls
                LD      A,STR_PRESS_SHFT_TO_FIN
                CALL    PrintChar
                JR      GCM_2

MENU_CONTROLS:  DEFB $00                ; Selected menu item
                DEFB $08                ; 8 items
                DEFB $00                ; Initial column
                DEFB $05 | $80          ; Initial row, don't double-size current row
                DEFB STR_LEFT           ; L, R, D, U, Jump, Carry, Fire, Swop

;; Run the sensitivity menu.
GoSensMenu:     LD      A,STR_SENSITIVITY_MENU
                CALL    PrintChar
                LD      IX,MENU_SENS
                CALL    DrawMenu
GSM_1:          CALL    MenuStep
                JR      C,GSM_1
                LD      A,(IX+MENU_CUR_ITEM)
                JP      SetSens         ; Tail call

MENU_SENS:      DEFB $01                ; Selected menu item (low)
                DEFB $02                ; 2 items
                DEFB $05                ; Initial column
                DEFB $09                ; Initial row
                DEFB $9E                ; High sens, low sens

GoPlayGameMenu: LD      A,(Continues)
                CP      $01             ; Is zero?
                RET     C               ; Return with carry - new game
                LD      A,STR_PLAY_GAME_MENU
                CALL    PrintChar
                LD      IX,MENU_PLAY_GAME
                LD      (IX+MENU_CUR_ITEM),$00
                CALL    DrawMenu
GPGM_1:         CALL    MenuStep
                JR      C,GPGM_1
                LD      A,(IX+MENU_CUR_ITEM)
                CP      $02             ; Item 2? Main menu
                JP      Z,GoMainMenu    ; Tail call
                RRA
                RET                     ; Return with carry if new game

MENU_PLAY_GAME: DEFB $00                ; Selected menu item
                DEFB $03                ; 3 items
                DEFB $09                ; Initial column
                DEFB $09                ; Initial row
                DEFB STR_OLD_GAME       ; Old game, new game, main menu.

;; Game Over screen
GameOverScreen: CALL    PlayTune
                CALL    ScreenWipe
                LD      A,STR_TITLE_SCREEN_EXT
                CALL    PrintChar
                CALL    DrawHnH
                CALL    GetScore
                PUSH    HL
                LD      A,(WorldMask)
                OR      ~$1F
                INC     A
                LD      A,STR_EMPEROR
                JR      Z,GOS_2         ; Jump if all crowns collected.
                LD      A,H
                ADD     A,$10
                JR      NC,GOS_1
                LD      A,H
GOS_1:          RLCA
                RLCA
                RLCA
                AND     $07
                ADD     A,STR_DUMMY     ; Array of possible levels from here.
GOS_2:          CALL    PrintChar
                LD      A,STR_EXPLORED
                CALL    PrintChar
                CALL    RoomCount
                CALL    Print4DigitsL
                LD      A,STR_ROOMS_SCORE
                CALL    PrintChar
                POP     DE
                CALL    Print4DigitsL
                LD      A,STR_LIBERATED
                CALL    PrintChar
                CALL    WorldCount
                LD      A,E
                CALL    Print2DigitsL
                LD      A,STR_PLANETS
                CALL    PrintChar
GOS_3:          CALL    PlayTune        ; Loop here until key pressed.
                CALL    GetInputEntSh
                JR      C,GOS_3
                LD      B,$C0
                JP      PlaySound       ; Silence noise.

;; Clear out the screen area and move the cursor for editing a
;; keyboard control setting
PrepCtrlEdit:   ADD     A,A
                ADD     A,(IX+MENU_INIT_Y)
                AND     $7F
                LD      B,A
                LD      C,$0B
                PUSH    BC
                CALL    SetCursor
                LD      A,CTRL_BLANKS
                CALL    PrintChar
                POP     BC
                JP      SetCursor

;; Indices into the menu definition data structure:
MENU_CUR_ITEM:  EQU $00         ; Currently-selected menu item index
;; Top bit of NUM_ITEMS is set if you don't want the currently-selected
;; line to be double-height
MENU_NUM_ITEMS: EQU $01         ; Number of items in the menu
MENU_INIT_X:    EQU $02         ; Initial X coordinate of the menu items
MENU_INIT_Y:    EQU $03         ; Initial Y coordinate of the menu items
MENU_STR_BASE:  EQU $04         ; First string index of items in the menu

;; Version of MenuStep that doesn't step on Enter.
MenuStepAlt:    CALL    GetInputEntSh
                RET     C
                LD      A,C
                CP      $01
                JR      NZ,MenuStepCore ; Call if the key pressed /wasn't/ Enter
                AND     A
                RET

;; A loop that's repeatedly called for menus.
MenuStep:       CALL    GetInputEntSh
                RET     C
                LD      A,C
        ;; NB: Fall through

MenuStepCore:   AND     A
                RET     Z
        ;; Increment current item, looping back to top if necessary.
                LD      A,(IX+MENU_CUR_ITEM)
                INC     A
                CP      A,(IX+MENU_NUM_ITEMS)
                JR      C,MSC_1
                XOR     A
MSC_1:          LD      (IX+MENU_CUR_ITEM),A
        ;; And play a nice little sound!
                PUSH    IX
                LD      B,$88           ; Teleport beam down noise
                CALL    PlaySound
                POP     IX
        ;; NB: Fall through

;; Draw the menu pointed to by IX.
DrawMenu:
        ;; Set cursor and initialise variables for menu-drawing
                LD      B,(IX+MENU_INIT_Y)
                RES     7,B
                LD      C,(IX+MENU_INIT_X)
                LD      (MenuCursor),BC
                CALL    SetCursor
                LD      B,(IX+MENU_NUM_ITEMS)
                LD      C,(IX+MENU_CUR_ITEM)
                INC     C
        ;; The main menu-item-drawing loop
DM_1:           LD      A,STR_ARROW_NONSEL      ; Arrow to use for non-selected items
                DEC     C
                PUSH    BC
                JR      NZ,DM_3
        ;; This is the currently-selected item
                BIT     7,(IX+MENU_INIT_Y)      ; Is bit 7 of MENU_INIT_Y set?
                JR      NZ,DM_2
                LD      A,CTRL_DOUBLE           ; No - use double height
                CALL    PrintChar
                LD      A,STR_ARROW_SEL
                JR      DM_3
DM_2:           LD      A,CTRL_SINGLE           ; Yes - use single height
                CALL    PrintChar
                LD      A,STR_ARROW_SEL         ; Arrow to use for selected items
        ;; Draw the arrow
DM_3:           CALL    PrintChar
        ;; Calculate the string index to use, and print the string
                LD      A,(IX+MENU_NUM_ITEMS)
                POP     BC
                PUSH    BC
                SUB     B
                ADD     A,(IX+MENU_STR_BASE)
                CALL    PrintChar
        ;; Update the cursor position
                POP     HL
                PUSH    HL
                LD      BC,(MenuCursor)
                LD      A,L                     ; Check if this is current item
                AND     A
                JR      NZ,DM_4
                BIT     7,(IX+MENU_INIT_Y)      ; Is current item and bit 7 of MENU_INIT_Y set?
                JR      NZ,DM_4
                INC     B                       ; No - advance 2 lines
DM_4:           INC     B                       ; Yes - just advance 1
                PUSH    BC
                CALL    SetCursor
        ;; Make sure we're back to single-line
                LD      A,CTRL_SINGLE
                CALL    PrintChar
        ;; And if bit 7 is not set, print out blanks to overwrite the changing parts.
                BIT     7,(IX+MENU_INIT_Y)
                JR      NZ,DM_5
                LD      A,CTRL_BLANKS
                CALL    PrintChar
        ;; Finally, write out the cursor position. Again.
DM_5:           POP     BC
                INC     B
                LD      (MenuCursor),BC
                CALL    SetCursor
                POP     BC
                DJNZ    DM_1
                SCF
                RET

; Strings table for indices < 0x60
Strings:
STR_PLAY:               EQU $80
                                DEFM DELIM, "PLAY"
CTRL_ATTR1:             EQU $81
                                DEFM DELIM,CTRL_ATTR,$01
CTRL_ATTR2:             EQU $82
                                DEFM DELIM,CTRL_ATTR,$02
CTRL_ATTR3:             EQU $83
                                DEFM DELIM,CTRL_ATTR,$03
STR_THE:                EQU $84
                                DEFM DELIM," THE "
STR_GAME:               EQU $85
                                DEFM DELIM,"GAME"
STR_SELECT:             EQU $86
                                DEFM DELIM,"SELECT"
STR_KEY:                EQU $87
                                DEFM DELIM,"KEY"
STR_ANY_KEY:            EQU $88
                                DEFM DELIM,"ANY ",STR_KEY
STR_SENSITIVITY:        EQU $89
                                DEFM DELIM,"SENSITIVITY"
STR_PRESS:              EQU $8A
                                DEFM DELIM,CTRL_ATTR2,"PRESS "
STR_TO:                 EQU $8B
                                DEFM DELIM,CTRL_ATTR2," TO "
STR_ENTER2:             EQU $8C
                                DEFM DELIM,CTRL_ATTR3,STR_ENTER
STR_SHIFT:              EQU $8D
                                DEFM DELIM,CTRL_ATTR3,"SHIFT"
; Controls menu
STR_LEFT:               EQU $8E
                                DEFM DELIM,"LEFT"
STR_RIGHT:              EQU $8F
                                DEFM DELIM,"RIGHT"
STR_DOWN:               EQU $90
                                DEFM DELIM,"DOWN"
STR_UP:                 EQU $91
                                DEFM DELIM,"UP"
STR_JUMP:               EQU $92
                                DEFM DELIM,"JUMP"
STR_CARRY:              EQU $93
                                DEFM DELIM,"CARRY"
STR_FIRE:               EQU $94
                                DEFM DELIM,"FIRE"
STR_SWOP:               EQU $95
                                DEFM DELIM,"SWOP"
; Sound menu
STR_LOTS:               EQU $96
                                DEFM DELIM,"LOTS OF IT"
STR_NOTSO:              EQU $97
                                DEFM DELIM,"NOT SO MUCH"
STR_PARDON:             EQU $98
                                DEFM DELIM,"PARDON"
;  Other stuff
STR_GO_TITLE_SCREEN:    EQU $99
                                DEFM DELIM,CTRL_SCREENWIPE
                                DEFM STR_TITLE_SCREEN,STR_MENU_BLURB
; Main menu
STR_PLAY_THE_GAME:      EQU $9A
                                DEFM DELIM,STR_PLAY,STR_THE,STR_GAME
STR_SELECT_THE_KEYS:    EQU $9B
                                DEFM DELIM,STR_SELECT,STR_THE,STR_KEY,"S"
STR_ADJUST_THE_SOUND:   EQU $9C
                                DEFM DELIM,"ADJUST",STR_THE,"SOUND"
STR_CONTROL_SENS:       EQU $9D
                                DEFM DELIM,"CONTROL ",STR_SENSITIVITY
; Sensitivity menu
STR_HIGH_SENS:          EQU $9E
                                DEFM DELIM,"HIGH ",STR_SENSITIVITY
STR_LOW_SENS:           EQU $9F
                                DEFM DELIM,"LOW ",STR_SENSITIVITY
; Play game menu
STR_OLD_GAME:           EQU $A0
                                DEFM DELIM,"OLD ",STR_GAME
STR_NEW_GAME:           EQU $A1
                                DEFM DELIM,"NEW ",STR_GAME
STR_MAIN_MENU:          EQU $A2
                                DEFM DELIM,"MAIN MENU"
; Other bits.
STR_MENU_BLURB:         EQU $A3
                                DEFM DELIM,CTRL_SGLPOS,$02,$15
                                DEFM STR_PRESS,CTRL_ATTR3,STR_ANY_KEY,STR_TO,"MOVE CURSOR"
                                DEFM CTRL_CURPOS,$01,$17
                                DEFM " ",STR_PRESS,STR_ENTER2,STR_TO,STR_SELECT," OPTION"
                                DEFM CTRL_BLANKS
STR_SHIFT_TO_FINISH:    EQU $A4
                                DEFM DELIM,CTRL_CURPOS,CTRL_ATTR,$03
                                DEFM STR_PRESS,STR_SHIFT,STR_TO,STR_FINISH,CTRL_BLANKS
STR_ENTER_TO_FINISH:    EQU $A5
                                DEFM DELIM,CTRL_CURPOS,CTRL_ATTR,$03
                                DEFM STR_PRESS,STR_ENTER2,STR_TO,STR_FINISH,CTRL_BLANKS
STR_SELECT_THEN_SHIFT:  EQU $A6
                                DEFM DELIM,CTRL_WIPE_SETPOS,$08,$00,CTRL_ATTR1
                                DEFM STR_SELECT_THE_KEYS,STR_PRESS_SHFT_TO_FIN
STR_PRESS_SHFT_TO_FIN:  EQU $A7
                                DEFM DELIM,STR_MENU_BLURB,CTRL_CURPOS,$05,$03
                                DEFM STR_PRESS,CTRL_ATTR1,STR_SHIFT,STR_TO
                                DEFM STR_FINISH,CTRL_BLANKS
STR_PRESS_KEYS_REQD:    EQU $A8
                                DEFM DELIM,CTRL_CURPOS,CTRL_ATTR,$03,CTRL_BLANKS
                                DEFM CTRL_CURPOS,$01,$15,CTRL_BLANKS
                                DEFM CTRL_CURPOS,$01,$17
                                DEFM STR_PRESS,CTRL_ATTR3,STR_KEY,"S"
                                DEFM CTRL_ATTR2," REQUIRED FOR ",CTRL_ATTR3
STR_SOUND_MENU:         EQU $A9
                                DEFM DELIM,CTRL_WIPE_SETPOS,$08,$00,CTRL_ATTR2
                                DEFM STR_ADJUST_THE_SOUND
                                DEFM STR_MENU_BLURB,CTRL_CURPOS,$06,$03,CTRL_ATTR,$00
                                DEFM "MUSIC BY GUY STEVENS"
STR_SENSITIVITY_MENU:   EQU $AA
                                DEFM DELIM,CTRL_WIPE_SETPOS,$06,$00,CTRL_ATTR2
                                DEFM STR_CONTROL_SENS,STR_MENU_BLURB
STR_PLAY_GAME_MENU:     EQU $AB
                                DEFM DELIM,CTRL_WIPE_SETPOS,$09,$00,CTRL_ATTR2
                                DEFM STR_PLAY_THE_GAME,STR_MENU_BLURB
STR_FINISH_RESTART:     EQU $AC
                                DEFM DELIM,CTRL_DOUBLE,CTRL_ATTR2
                                DEFM CTRL_CURPOS,$03,$03
                                DEFM STR_PRESS,CTRL_ATTR3,STR_SHIFT,STR_TO
                                DEFM STR_FINISH," ",STR_GAME
                                DEFM CTRL_CURPOS,$04,$06
                                DEFM STR_PRESS,CTRL_ATTR3,STR_ANY_KEY,STR_TO,"RESTART"
STR_SPACES:             EQU $AD
                                DEFM DELIM,"   "
STR_ARROW_SEL:          EQU $AE
                                DEFM DELIM,CTRL_ATTR3,CHAR_ARR1,CHAR_ARR2,STR_SPACES
STR_ARROW_NONSEL:       EQU $AF
                                DEFM DELIM,CTRL_SINGLE,CTRL_ATTR1
                                DEFM CHAR_ARR3,CHAR_ARR4,STR_SPACES
CTRL_WIPE_SETPOS:       EQU $B0
                                DEFM DELIM,CTRL_SCREENWIPE,CTRL_ATTRMODE,$09
                                DEFM CTRL_DOUBLE,CTRL_CURPOS
CTRL_POS_LIGHTNING:     EQU $B1
                                DEFM DELIM,CTRL_SGLPOS,$05,$14
CTRL_POS_SPRING:        EQU $B2
                                DEFM DELIM,CTRL_SGLPOS,$19,$14
CTRL_POS_HEELS_SHIELD:  EQU $B3
                                DEFM DELIM,CTRL_SGLPOS,$19,$17
CTRL_POS_HEAD_SHIELD:   EQU $B4
                                DEFM DELIM,CTRL_SGLPOS,$05,$17
CTRL_POS_HEELS_LIVES:   EQU $B5
                                DEFM DELIM,CTRL_DOUBLE,CTRL_CURPOS,$12,$16
CTRL_POS_HEAD_LIVES:    EQU $B6
                                DEFM DELIM,CTRL_DOUBLE,CTRL_CURPOS,$0C,$16
CTRL_POS_DONUT:         EQU $B7
                                DEFM DELIM,CTRL_SGLPOS,$01,$11
STR_GAME_SYMBOLS:       EQU $B8
                                DEFM DELIM,CTRL_SINGLE,CTRL_ATTR2
                                DEFM CTRL_CURPOS,$1A,$13,CHAR_SPRING
                                DEFM CTRL_CURPOS,$1A,$16,CTRL_ATTR2,CHAR_SHIELD
                                DEFM CTRL_CURPOS,$06,$13,CTRL_ATTR2,CHAR_LIGHTNING
                                DEFM CTRL_CURPOS,$06,$16,CTRL_ATTR2,CHAR_SHIELD
CTRL_SGLPOS:            EQU $B9
                                DEFM DELIM,CTRL_SINGLE,CTRL_CURPOS
STR_TITLE_SCREEN_EXT:   EQU $BA
                                DEFM DELIM,STR_TITLE_SCREEN
                                DEFM CTRL_CURPOS,$0A,$08
                                DEFM CTRL_ATTR2,CTRL_DOUBLE,CTRL_ATTR,$00
STR_EXPLORED:           EQU $BB
                                DEFM DELIM,CTRL_SGLPOS,$06,$11,CTRL_ATTR1,"EXPLORED "
STR_ROOMS_SCORE:        EQU $BC
                                DEFM DELIM," ROOMS"
                                DEFM CTRL_CURPOS,$09,$0E
                                DEFM CTRL_ATTR2,"SCORE "
STR_LIBERATED:          EQU $BD
                                DEFM DELIM,"0"
                                DEFM CTRL_CURPOS,$05,$14
                                DEFM CTRL_ATTR3,"LIBERATED "
STR_PLANETS:            EQU $BE
                                DEFM DELIM," PLANETS"
STR_DUMMY:              EQU $BF
                                DEFM DELIM,"  DUMMY"
STR_NOVICE:             EQU $C0
                                DEFM DELIM,"  NOVICE"
STR_SPY:                EQU $C1
                                DEFM DELIM,"   SPY    "
STR_MASTER_SPY:         EQU $C2
                                DEFM DELIM,"MASTER SPY"
STR_HERO:               EQU $C3
                                DEFM DELIM,"   HERO"
STR_EMPEROR:            EQU $C4
                                DEFM DELIM," EMPEROR"
STR_TITLE_SCREEN:       EQU $C5
                                DEFM DELIM,CTRL_ATTRMODE,$0A,CTRL_DOUBLE
                                DEFM CTRL_CURPOS,$08,$00
                                DEFM CTRL_ATTR2,"HEAD      HEELS"
                                DEFM CTRL_SGLPOS,$0C,$01
                                DEFM CTRL_ATTR,$00," OVER "
                                DEFM CTRL_CURPOS,$01,$00
                                DEFM " JON"
                                DEFM CTRL_CURPOS,$01,$02
                                DEFM "RITMAN"
                                DEFM CTRL_CURPOS,$19,$00
                                DEFM "BERNIE"
                                DEFM CTRL_CURPOS,$18,$02
                                DEFM "DRUMMOND"
STR_EMPIRE_BLURB:       EQU $C6
                                DEFM DELIM,CTRL_SCREENWIPE,CTRL_ATTRMODE,$06
                                DEFM CTRL_CURPOS,$05,$00,CTRL_DOUBLE,CTRL_ATTR3
                                DEFM STR_THE,STR_BLACKTOOTH," EMPIRE",CTRL_SINGLE
                                DEFM CTRL_CURPOS,$03,$09,CTRL_ATTR1,"EGYPTUS"
                                DEFM CTRL_CURPOS,$15,$17,"BOOK WORLD"
                                DEFM CTRL_CURPOS,$03,$17,"SAFARI"
                                DEFM CTRL_CURPOS,$14,$09,"PENITENTIARY"
                                DEFM CTRL_CURPOS,$0B,$10,STR_BLACKTOOTH
STR_BLACKTOOTH:         EQU $C7
                                DEFM DELIM,"BLACKTOOTH"
STR_FINISH:             EQU $C8
                                DEFM DELIM,"FINISH"
STR_FREEDOM:            EQU $C9
                                DEFM DELIM,CTRL_POS_HEAD_LIVES,CTRL_ATTR,$00,"FREEDOM "
STR_WIN_SCREEN:         EQU $CA
                                DEFM DELIM,CTRL_SCREENWIPE,CTRL_ATTRMODE,$06
                                DEFM CTRL_SGLPOS,$00,$0A,CTRL_ATTR2
                                DEFM STR_THE,"PEOPLE SALUTE YOUR HEROISM"
                                DEFM CTRL_CURPOS,$08,$0C
                                DEFM "AND PROCLAIM YOU"
                                DEFM CTRL_DOUBLE,CTRL_CURPOS,$0B,$10,CTRL_ATTR,$00
                                DEFM STR_EMPEROR

                                DEFM DELIM
