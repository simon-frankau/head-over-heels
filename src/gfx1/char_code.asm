;;
;; char_code.asm
;;
;; Provides CharCodeToAttr, plus EQUs for special characters.
;;

CHAR_ARR1:      EQU $21
CHAR_ARR2:      EQU $22
CHAR_ARR3:      EQU $23
CHAR_ARR4:      EQU $24
CHAR_LIGHTNING: EQU $25
CHAR_SPRING:    EQU $26
CHAR_SHIELD:    EQU $27

;; Look up character code in A (- 0x20 already) to a pointer to the
;; character in DE.
CharCodeToAddr: CP      $08
                JR      C,CCTA_1        ; Space ! " # $ % & '
                SUB     $07
                CP      $13
                JR      C,CCTA_1        ; / 0-9
                SUB     $07             ; Alphabetical characters.
CCTA_1:         ADD     A,A
                ADD     A,A
                LD      L,A
                LD      H,$00
                ADD     HL,HL
                LD      DE,IMG_CHARS - MAGIC_OFFSET
                ADD     HL,DE
                EX      DE,HL
                RET
