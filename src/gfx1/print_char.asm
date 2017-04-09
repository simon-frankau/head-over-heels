;;
;; print_char.asm
;;
;; Text-printing functions
;;

;; Exported functions:
;; * PrintChar
;; * SetCursor
;; * Print4DigitsL
;; * Print2DigitsL
;; * Print2DigitsR

;; Exported variables:
;; * CharCursor - double pixel X coord centred on $80, Y top of screen = 0

;; Exported constants:
;; * CTRL_*

DELIM:          EQU $FF         ; String delimiter

CharDoublerBuf: DEFS $10,$00    ; 16 bytes to hold double-height character.

AttrIdx:        DEFB $02        ; Which attribute number to use.
CharCursor:     DEFW $8040      ; Where we're going to put the character, on screen.
IsDoubleHeight: DEFB $00        ; Non-zero if printing double-height.
KeepAttr:       DEFB $FF        ; If set to zero, step through attribute codes 1, 2, 3.

;; Main character-printing entry point.
;;
;; Takes a character code in A.
;; The code can be an index into the string tables (Strings, Strings2),
;; if the top bit is set.
PrintChar:      JP      PrintCharBase   ; NB: Target of self-modifying code.

;; Default character printer
PrintCharBase:  CP      $80
                JR      NC,PCB_3
                SUB     $20
                JR      C,ControlCode   ; Tail call!
        ;; Printable character!
                CALL    CharCodeToAddr  ; Address now in DE
                LD      HL,$0804        ; 8x8 sprite
                LD      A,(IsDoubleHeight)
                AND     A
                CALL    NZ,CharDoubler  ; Double the height if necessary.
                LD      BC,(CharCursor) ; Load the destination cursor...
                LD      A,C
                ADD     A,$04
                LD      (CharCursor),A  ; And advance the cursor.
                LD      A,(KeepAttr)
                AND     A
                LD      A,(AttrIdx)     ; Load the attribute index to use.
                JR      NZ,PCB_2
                INC     A               ; If KeepAttr was zero, cycle through attrs 1-3.
                AND     $03
                SCF                     ; (?)
                JR      NZ,PCB_1
                INC     A
PCB_1:          LD      (AttrIdx),A
PCB_2:          JP      DrawSprite
        ;; Code >= 0x80: Print a string from the string tables.
PCB_3:          AND     $7F
                CALL    GetStrAddr
        ;; NB: Fall through.

;; Print characters in HL until DELIM is reached.
PrintChars:     LD      A,(HL)
                CP      DELIM
                RET     Z
                INC     HL
                PUSH    HL
                CALL    PrintChar
                POP     HL
                JR      PrintChars

;; Code < 0x20:
CTRL_SCREENWIPE:        EQU 0 ; Call ScreenWipe
CTRL_NEWLINE:           EQU 1 ; Newline
CTRL_BLANKS:            EQU 2 ; Spaces to end of line
CTRL_SINGLE:            EQU 3 ; Double height off
CTRL_DOUBLE:            EQU 4 ; Double height on
CTRL_ATTR:              EQU 5 ; Set attribute index (0 means cycle, all others set specifically)
CTRL_CURPOS:            EQU 6 ; Set cursor
CTRL_ATTRMODE:          EQU 7 ; Set the screen attributes mode

ControlCode:    ADD     A,$20           ; Add the 0x20 back.
                CP      $05
                JR      NC,CC_GE5
                AND     A
                JP      Z,ScreenWipe    ; Tail call
                SUB     $02
                JR      C,CC_EQ1
                JR      Z,CC_EQ2
                DEC     A
                LD      (IsDoubleHeight),A
                RET

;; Print spaces to the end of line.
CC_EQ2:         LD      A,(CharCursor)
                CP      $C0
                RET     NC
                LD      A,$20
                CALL    PrintChar
                JR      CC_EQ2

CC_EQ1:         LD      HL,(CharCursor)
                LD      A,(IsDoubleHeight)      ; Go down one or two rows, depending on height,
                AND     A
                LD      A,H
                JR      Z,CC_NotDbl
                ADD     A,$08
CC_NotDbl:      ADD     A,$08
                LD      H,A
                LD      L,$40                   ; and return X position to left of screen.
                LD      (CharCursor),HL
                RET

;; These cases change the interpretation of the next character...
CC_GE5:         LD      HL,SetAttrFn
                JR      Z,SetPrintFn
                CP      $07
                LD      HL,SetSchemeFn
                JR      Z,SetPrintFn
                LD      HL,SetCursorFn
        ;; NB: Fall-through.

;; Set the function called when you 'PrintChar'.
SetPrintFn:     LD      (PrintChar+1),HL
                RET

SetSchemeFn:    CALL    SetAttribs
                JR      RestorePrintFn

SetAttrFn:      AND     A
                LD      (KeepAttr),A
                JR      Z,RestorePrintFn
                LD      (AttrIdx),A
        ;; NB: Fall-through

;;  Restore the default function called when you 'PrintChar'.
RestorePrintFn: LD      HL,PrintCharBase
                JR      SetPrintFn

SetCursorFn:    LD      HL,SetCursorFn2 ; Next time, we'll set X coordinate
                ADD     A,A
                ADD     A,A
                ADD     A,$40           ; Convert from character to half-pixel coordinates
                LD      (CharCursor),A  ; and store
                JR      SetPrintFn

SetCursorFn2:   ADD     A,A             ; Convert from character to pixel-based coordinates
                ADD     A,A
                ADD     A,A
                LD      (CharCursor+1),A ; Store X coordinate of CharCursor.
                JR      RestorePrintFn

;; Execute a simple command string to set the cursor position.
;; Takes cursor position in BC.
SetCursor:      LD      (SetCursorBuf+1),BC
                LD      HL,SetCursorBuf
                JP      PrintChars

SetCursorBuf:   DEFB CTRL_CURPOS,$00,$00,DELIM

;; Get the string's address, from an index.
GetStrAddr:     LD      B,A
                LD      HL,Strings
                SUB     $60
                JR      C,GSTA_1
                LD      HL,Strings2
                LD      B,A
GSTA_1:         INC     B
        ;; Search for Bth occurence of DELIM.
                LD      A,DELIM
GSTA_2:         LD      C,A
                CPIR
                DJNZ    GSTA_2
                RET

;; Copy the character, doubling its height, into the buffer
CharDoubler:    LD      B,$08
                LD      HL,CharDoublerBuf
CD_1:           LD      A,(DE)
                LD      (HL),A
                INC     HL
                LD      (HL),A
                INC     HL
                INC     DE
                DJNZ    CD_1
                LD      HL,$1004        ; New width/height - 8 pixels by 16.
                LD      DE,CharDoublerBuf
                RET

;; Left align, no leading zero.
Print4DigitsL:  LD      BC,$00F8        ; Print '0' if zero, otherwise nothing.
                PUSH    DE
                LD      A,D
                CALL    Print2Digits
                POP     DE
                LD      A,E
                JR      Print2Digits    ; Tail call

;; Right align, no leading zero.
Print2DigitsR:  LD      BC,$FFFE        ; Pad with spaces, print '0' if 0.
                JR      Print2Digits    ; Tail call

;; Left align, no leading zero.
Print2DigitsL:  LD      BC,$00FE        ; No padding, print '0' if 0.
        ;; NB: Fall through

;; Prints a 2-digit number. Expects digits stored as BCD in A.
;;
;; Formatting is controlled by B and C, 1 bit per digit, processed LSB
;; to MSB. 'C' bit set means print a 0 if nothing there, 'B' bit set
;; means print a space if nothing there.
Print2Digits:   PUSH    AF
                RRA
                RRA
                RRA
                RRA
                CALL    PrintDigit
                POP     AF
        ;; NB: Fall through for second digit.
PrintDigit:     AND     $0F
                JR      NZ,PD_1
                RRC     C
                JR      C,PD_1          ; If zero, print it out if C & 1.
                RRC     B
                RET     NC              ; Print a space if B & 1, otherwise, nothing at all.
                LD      A,$F0           ; (When adding on $30, this becomes $20 aka " ")
PD_1:           LD      C,$FF
                ADD     A,$30
                PUSH    BC
                CALL    PrintChar
                POP     BC
                SCF
                RET
